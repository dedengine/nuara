use std::collections::HashMap;

use axum::{
    Json,
    extract::{Multipart, Path, Query, State},
    http::{HeaderMap, StatusCode},
};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use super::{
    otorisasi::wajib_admin_sppg_aktif,
    upload::{FormUpload, hapus_berkas, simpan_multipart},
};
use crate::{
    error::ApiError,
    state::{AppState, EventAduan},
};

#[derive(Debug)]
struct DataAduanBaru {
    id_unit_sppg: u64,
    id_sekolah: u64,
    id_menu_harian: Option<u64>,
    kategori: String,
    isi_aduan: String,
    nilai_kepuasan: u8,
}

#[derive(Debug, FromRow, Serialize)]
pub struct AduanDasar {
    id: u64,
    id_unit_sppg: u64,
    id_sekolah: u64,
    nama_sekolah: String,
    id_menu_harian: Option<u64>,
    nama_menu: Option<String>,
    kategori: String,
    isi_aduan: String,
    nilai_kepuasan: u8,
    status: String,
    created_at: String,
    update_at: String,
}

#[derive(Debug, FromRow, Serialize)]
pub struct MediaAduan {
    id: u64,
    jenis_media: String,
    url_berkas: String,
    nama_berkas: String,
    ukuran_byte: u64,
    mime_type: String,
    durasi_detik: Option<u16>,
    created_at: String,
}

#[derive(Debug, Serialize)]
pub struct AduanDetail {
    #[serde(flatten)]
    aduan: AduanDasar,
    media: Vec<MediaAduan>,
}

#[derive(Debug, Deserialize)]
pub struct FilterAduan {
    status: Option<String>,
    id_sekolah: Option<u64>,
}

#[derive(Debug, Deserialize)]
pub struct DataStatus {
    status: String,
}

#[derive(Debug, FromRow, Serialize)]
pub struct StatistikAduan {
    total: i64,
    baru: i64,
    diproses: i64,
    selesai: i64,
    ditolak: i64,
    rata_rata_kepuasan: f64,
}

#[derive(Debug, Serialize)]
pub struct ResponsData<T> {
    sukses: bool,
    data: T,
}

pub async fn kirim(
    State(state): State<AppState>,
    multipart: Multipart,
) -> Result<(StatusCode, Json<ResponsData<AduanDetail>>), ApiError> {
    let form = simpan_multipart(multipart, state.storage_path.as_ref(), "aduan").await?;
    let data = match baca_data_aduan(&form) {
        Ok(data) => data,
        Err(error) => {
            hapus_berkas(&form.berkas.path_lokal).await;
            return Err(error);
        }
    };
    if let Err(error) = validasi_relasi(&state, &data).await {
        hapus_berkas(&form.berkas.path_lokal).await;
        return Err(error);
    }

    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;
    let hasil = sqlx::query(
        r#"
        INSERT INTO aduan (
            id_unit_sppg, id_sekolah, id_menu_harian, kategori,
            isi_aduan, nilai_kepuasan, status
        ) VALUES (?, ?, ?, ?, ?, ?, 'baru')
        "#,
    )
    .bind(data.id_unit_sppg)
    .bind(data.id_sekolah)
    .bind(data.id_menu_harian)
    .bind(&data.kategori)
    .bind(&data.isi_aduan)
    .bind(data.nilai_kepuasan)
    .execute(&mut *transaksi)
    .await;
    let hasil = match hasil {
        Ok(hasil) => hasil,
        Err(error) => {
            hapus_berkas(&form.berkas.path_lokal).await;
            return Err(kesalahan_database(error));
        }
    };
    let id_aduan = hasil.last_insert_id();
    let berkas = &form.berkas;
    if let Err(error) = sqlx::query(
        r#"
        INSERT INTO media_aduan (
            id_aduan, jenis_media, url_berkas, nama_berkas,
            ukuran_byte, mime_type, durasi_detik
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(id_aduan)
    .bind(berkas.jenis_media)
    .bind(&berkas.url_berkas)
    .bind(&berkas.nama_berkas)
    .bind(berkas.ukuran_byte)
    .bind(&berkas.mime_type)
    .bind(berkas.durasi_detik)
    .execute(&mut *transaksi)
    .await
    {
        hapus_berkas(&berkas.path_lokal).await;
        return Err(kesalahan_database(error));
    }
    if let Err(error) = transaksi.commit().await {
        hapus_berkas(&berkas.path_lokal).await;
        return Err(kesalahan_database(error));
    }

    let id_unit_sppg = data.id_unit_sppg;
    state.terbitkan_event_aduan(EventAduan {
        jenis: "aduan_dibuat",
        id_unit_sppg,
        id_aduan,
    });
    let data = ambil_satu(&state, id_aduan, id_unit_sppg).await?;
    Ok((
        StatusCode::CREATED,
        Json(ResponsData { sukses: true, data }),
    ))
}

pub async fn daftar_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(filter): Query<FilterAduan>,
) -> Result<Json<ResponsData<Vec<AduanDetail>>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let status = filter.status.map(|nilai| nilai.trim().to_lowercase());
    if let Some(status) = &status
        && !status_valid(status)
    {
        return Err(ApiError::permintaan_tidak_valid(
            "Filter status tidak valid",
        ));
    }

    let daftar = sqlx::query_as::<_, AduanDasar>(
        r#"
        SELECT
            a.id, a.id_unit_sppg, a.id_sekolah, s.nama AS nama_sekolah,
            a.id_menu_harian, m.nama_menu, a.kategori, a.isi_aduan,
            a.nilai_kepuasan, a.status,
            DATE_FORMAT(a.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
            DATE_FORMAT(a.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
        FROM aduan a
        INNER JOIN sekolah s ON s.id = a.id_sekolah
        LEFT JOIN menu_harian m ON m.id = a.id_menu_harian
        WHERE a.id_unit_sppg = ?
          AND (? IS NULL OR a.status = ?)
          AND (? IS NULL OR a.id_sekolah = ?)
        ORDER BY a.created_at DESC, a.id DESC
        "#,
    )
    .bind(id_unit_sppg)
    .bind(&status)
    .bind(&status)
    .bind(filter.id_sekolah)
    .bind(filter.id_sekolah)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;

    let mut data = Vec::with_capacity(daftar.len());
    for aduan in daftar {
        data.push(muat_detail(&state, aduan).await?);
    }
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn statistik(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsData<StatistikAduan>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let data = sqlx::query_as::<_, StatistikAduan>(
        r#"
        SELECT
            COUNT(*) AS total,
            CAST(COALESCE(SUM(status = 'baru'), 0) AS SIGNED) AS baru,
            CAST(COALESCE(SUM(status = 'diproses'), 0) AS SIGNED) AS diproses,
            CAST(COALESCE(SUM(status = 'selesai'), 0) AS SIGNED) AS selesai,
            CAST(COALESCE(SUM(status = 'ditolak'), 0) AS SIGNED) AS ditolak,
            CAST(COALESCE(AVG(nilai_kepuasan), 0) AS DOUBLE) AS rata_rata_kepuasan
        FROM aduan WHERE id_unit_sppg = ?
        "#,
    )
    .bind(id_unit_sppg)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn ubah_status(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
    Json(input): Json<DataStatus>,
) -> Result<Json<ResponsData<AduanDetail>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let status = input.status.trim().to_lowercase();
    if !status_valid(&status) {
        return Err(ApiError::permintaan_tidak_valid(
            "Status harus baru, diproses, selesai, atau ditolak",
        ));
    }
    let hasil = sqlx::query("UPDATE aduan SET status = ? WHERE id = ? AND id_unit_sppg = ?")
        .bind(status)
        .bind(id)
        .bind(id_unit_sppg)
        .execute(&state.database)
        .await
        .map_err(kesalahan_database)?;
    if hasil.rows_affected() == 0 && !aduan_milik_unit_ada(&state, id, id_unit_sppg).await? {
        return Err(ApiError::tidak_ditemukan("Aduan tidak ditemukan"));
    }
    state.terbitkan_event_aduan(EventAduan {
        jenis: "status_aduan_diubah",
        id_unit_sppg,
        id_aduan: id,
    });
    let data = ambil_satu(&state, id, id_unit_sppg).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

fn baca_data_aduan(form: &FormUpload) -> Result<DataAduanBaru, ApiError> {
    let id_unit_sppg = parse_wajib::<u64>(&form.field, "id_unit_sppg")?;
    let id_sekolah = parse_wajib::<u64>(&form.field, "id_sekolah")?;
    let id_menu_harian = parse_opsional::<u64>(&form.field, "id_menu_harian")?;
    let kategori = field_wajib(&form.field, "kategori")?.to_lowercase();
    let isi_aduan = field_wajib(&form.field, "isi_aduan")?;
    let nilai_kepuasan = parse_wajib::<u8>(&form.field, "nilai_kepuasan")?;

    let kategori_valid = [
        "rasa",
        "porsi",
        "kebersihan",
        "makanan_rusak",
        "benda_asing",
        "alergi",
        "lainnya",
    ];
    if !kategori_valid.contains(&kategori.as_str()) {
        return Err(ApiError::permintaan_tidak_valid(
            "Kategori aduan tidak valid",
        ));
    }
    if isi_aduan.chars().count() < 10 || isi_aduan.chars().count() > 2000 {
        return Err(ApiError::permintaan_tidak_valid(
            "Isi aduan harus terdiri dari 10 sampai 2000 karakter",
        ));
    }
    if !(1..=5).contains(&nilai_kepuasan) {
        return Err(ApiError::permintaan_tidak_valid(
            "Nilai kepuasan harus antara 1 dan 5",
        ));
    }
    Ok(DataAduanBaru {
        id_unit_sppg,
        id_sekolah,
        id_menu_harian,
        kategori,
        isi_aduan,
        nilai_kepuasan,
    })
}

async fn validasi_relasi(state: &AppState, data: &DataAduanBaru) -> Result<(), ApiError> {
    let sekolah_valid = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*)
        FROM sekolah s
        INNER JOIN unit_sppg u ON u.id = s.id_unit_sppg
        WHERE s.id = ? AND s.id_unit_sppg = ? AND s.aktif = TRUE AND u.aktif = TRUE
        "#,
    )
    .bind(data.id_sekolah)
    .bind(data.id_unit_sppg)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)?
        > 0;
    if !sekolah_valid {
        return Err(ApiError::permintaan_tidak_valid(
            "Sekolah dan unit SPPG tidak saling berkaitan atau sedang nonaktif",
        ));
    }
    if let Some(id_menu) = data.id_menu_harian {
        let menu_valid = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM menu_harian
            WHERE id = ? AND id_unit_sppg = ? AND aktif = TRUE
              AND (id_sekolah IS NULL OR id_sekolah = ?)
            "#,
        )
        .bind(id_menu)
        .bind(data.id_unit_sppg)
        .bind(data.id_sekolah)
        .fetch_one(&state.database)
        .await
        .map_err(kesalahan_database)?
            > 0;
        if !menu_valid {
            return Err(ApiError::permintaan_tidak_valid(
                "Menu tidak sesuai dengan sekolah dan unit SPPG yang dipilih",
            ));
        }
    }
    Ok(())
}

async fn ambil_satu(state: &AppState, id: u64, id_unit_sppg: u64) -> Result<AduanDetail, ApiError> {
    let aduan = sqlx::query_as::<_, AduanDasar>(
        r#"
        SELECT
            a.id, a.id_unit_sppg, a.id_sekolah, s.nama AS nama_sekolah,
            a.id_menu_harian, m.nama_menu, a.kategori, a.isi_aduan,
            a.nilai_kepuasan, a.status,
            DATE_FORMAT(a.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
            DATE_FORMAT(a.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
        FROM aduan a
        INNER JOIN sekolah s ON s.id = a.id_sekolah
        LEFT JOIN menu_harian m ON m.id = a.id_menu_harian
        WHERE a.id = ? AND a.id_unit_sppg = ?
        "#,
    )
    .bind(id)
    .bind(id_unit_sppg)
    .fetch_optional(&state.database)
    .await
    .map_err(kesalahan_database)?
    .ok_or_else(|| ApiError::tidak_ditemukan("Aduan tidak ditemukan"))?;
    muat_detail(state, aduan).await
}

async fn muat_detail(state: &AppState, aduan: AduanDasar) -> Result<AduanDetail, ApiError> {
    let media = sqlx::query_as::<_, MediaAduan>(
        r#"
        SELECT id, jenis_media, url_berkas, nama_berkas, ukuran_byte,
               mime_type, durasi_detik,
               DATE_FORMAT(created_at, '%Y-%m-%dT%H:%i:%s') AS created_at
        FROM media_aduan WHERE id_aduan = ? ORDER BY created_at, id
        "#,
    )
    .bind(aduan.id)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;
    Ok(AduanDetail { aduan, media })
}

async fn aduan_milik_unit_ada(
    state: &AppState,
    id: u64,
    id_unit_sppg: u64,
) -> Result<bool, ApiError> {
    sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM aduan WHERE id = ? AND id_unit_sppg = ?")
        .bind(id)
        .bind(id_unit_sppg)
        .fetch_one(&state.database)
        .await
        .map(|jumlah| jumlah > 0)
        .map_err(kesalahan_database)
}

fn field_wajib(fields: &HashMap<String, String>, nama: &str) -> Result<String, ApiError> {
    fields
        .get(nama)
        .map(|nilai| nilai.trim().to_owned())
        .filter(|nilai| !nilai.is_empty())
        .ok_or_else(|| ApiError::permintaan_tidak_valid(format!("Field {nama} wajib diisi")))
}

fn parse_wajib<T>(fields: &HashMap<String, String>, nama: &str) -> Result<T, ApiError>
where
    T: std::str::FromStr,
{
    field_wajib(fields, nama)?
        .parse()
        .map_err(|_| ApiError::permintaan_tidak_valid(format!("Field {nama} tidak valid")))
}

fn parse_opsional<T>(fields: &HashMap<String, String>, nama: &str) -> Result<Option<T>, ApiError>
where
    T: std::str::FromStr,
{
    fields
        .get(nama)
        .filter(|nilai| !nilai.trim().is_empty())
        .map(|nilai| {
            nilai
                .trim()
                .parse()
                .map_err(|_| ApiError::permintaan_tidak_valid(format!("Field {nama} tidak valid")))
        })
        .transpose()
}

fn status_valid(status: &str) -> bool {
    ["baru", "diproses", "selesai", "ditolak"].contains(&status)
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Operasi database aduan gagal");
    ApiError::kesalahan_internal()
}
