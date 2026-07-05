use std::collections::HashSet;

use axum::{
    Json,
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
};
use chrono::{Local, NaiveDate};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, MySql, Transaction};

use super::{
    media_menu::{self, MediaMenu},
    otorisasi::wajib_admin_sppg_aktif,
    upload::{hapus_berkas, path_dari_url},
};
use crate::{error::ApiError, state::AppState};

const PILIH_MENU_ADMIN: &str = r#"
    SELECT
        m.id, m.id_unit_sppg, m.id_sekolah,
        DATE_FORMAT(m.tanggal_menu, '%Y-%m-%d') AS tanggal_menu,
        m.nama_menu, m.deskripsi, m.kalori,
        CAST(m.protein AS DOUBLE) AS protein,
        CAST(m.lemak AS DOUBLE) AS lemak,
        CAST(m.karbohidrat AS DOUBLE) AS karbohidrat,
        m.sumber_data_gizi, m.url_sumber_data_gizi, m.status, m.aktif,
        DATE_FORMAT(m.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(m.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM menu_harian m
    WHERE m.id_unit_sppg = ?
    ORDER BY m.tanggal_menu DESC, m.id DESC
"#;

const PILIH_SATU_MENU_ADMIN: &str = r#"
    SELECT
        m.id, m.id_unit_sppg, m.id_sekolah,
        DATE_FORMAT(m.tanggal_menu, '%Y-%m-%d') AS tanggal_menu,
        m.nama_menu, m.deskripsi, m.kalori,
        CAST(m.protein AS DOUBLE) AS protein,
        CAST(m.lemak AS DOUBLE) AS lemak,
        CAST(m.karbohidrat AS DOUBLE) AS karbohidrat,
        m.sumber_data_gizi, m.url_sumber_data_gizi, m.status, m.aktif,
        DATE_FORMAT(m.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(m.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM menu_harian m
    WHERE m.id = ? AND m.id_unit_sppg = ?
"#;

const PILIH_MENU_PUBLIK: &str = r#"
    SELECT
        m.id, m.id_unit_sppg, m.id_sekolah,
        DATE_FORMAT(m.tanggal_menu, '%Y-%m-%d') AS tanggal_menu,
        m.nama_menu, m.deskripsi, m.kalori,
        CAST(m.protein AS DOUBLE) AS protein,
        CAST(m.lemak AS DOUBLE) AS lemak,
        CAST(m.karbohidrat AS DOUBLE) AS karbohidrat,
        m.sumber_data_gizi, m.url_sumber_data_gizi, m.status, m.aktif,
        DATE_FORMAT(m.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(m.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM menu_harian m
    INNER JOIN sekolah s ON s.id_unit_sppg = m.id_unit_sppg
    INNER JOIN unit_sppg u ON u.id = m.id_unit_sppg
    WHERE s.id = ? AND s.aktif = TRUE AND u.aktif = TRUE
      AND m.tanggal_menu = ? AND m.status = 'dipublikasikan' AND m.aktif = TRUE
      AND (m.id_sekolah = s.id OR m.id_sekolah IS NULL)
    ORDER BY (m.id_sekolah IS NOT NULL) DESC
    LIMIT 1
"#;

const PILIH_RIWAYAT_PUBLIK: &str = r#"
    SELECT
        m.id, m.id_unit_sppg, m.id_sekolah,
        DATE_FORMAT(m.tanggal_menu, '%Y-%m-%d') AS tanggal_menu,
        m.nama_menu, m.deskripsi, m.kalori,
        CAST(m.protein AS DOUBLE) AS protein,
        CAST(m.lemak AS DOUBLE) AS lemak,
        CAST(m.karbohidrat AS DOUBLE) AS karbohidrat,
        m.sumber_data_gizi, m.url_sumber_data_gizi, m.status, m.aktif,
        DATE_FORMAT(m.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(m.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM menu_harian m
    INNER JOIN sekolah s ON s.id_unit_sppg = m.id_unit_sppg
    INNER JOIN unit_sppg u ON u.id = m.id_unit_sppg
    WHERE s.id = ? AND s.aktif = TRUE AND u.aktif = TRUE
      AND m.tanggal_menu BETWEEN ? AND ?
      AND m.status = 'dipublikasikan' AND m.aktif = TRUE
      AND (m.id_sekolah = s.id OR m.id_sekolah IS NULL)
    ORDER BY m.tanggal_menu DESC, (m.id_sekolah IS NOT NULL) DESC
"#;

#[derive(Debug, FromRow, Serialize)]
pub struct MenuDasar {
    id: u64,
    id_unit_sppg: u64,
    id_sekolah: Option<u64>,
    tanggal_menu: String,
    nama_menu: String,
    deskripsi: String,
    kalori: u16,
    protein: f64,
    lemak: f64,
    karbohidrat: f64,
    sumber_data_gizi: String,
    url_sumber_data_gizi: String,
    status: String,
    aktif: bool,
    created_at: String,
    update_at: String,
}

#[derive(Debug, Serialize)]
pub struct MenuDetail {
    #[serde(flatten)]
    menu: MenuDasar,
    komponen: Vec<KomponenMenu>,
    alergi: Vec<AlergiMenu>,
    media: Vec<MediaMenu>,
}

#[derive(Debug, FromRow, Serialize)]
pub struct KomponenMenu {
    id: u64,
    id_bahan_pangan: Option<u64>,
    nama_komponen: String,
    keterangan_porsi: Option<String>,
    berat_gram: Option<f64>,
    urutan: u8,
}

#[derive(Debug, FromRow, Serialize)]
pub struct AlergiMenu {
    id: u64,
    nama_alergi: String,
    keterangan: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct DataMenu {
    id_sekolah: Option<u64>,
    tanggal_menu: String,
    nama_menu: String,
    deskripsi: String,
    kalori: u16,
    protein: f64,
    lemak: f64,
    karbohidrat: f64,
    sumber_data_gizi: String,
    url_sumber_data_gizi: String,
    status: String,
    aktif: Option<bool>,
    komponen: Vec<DataKomponen>,
    alergi: Vec<DataAlergi>,
}

#[derive(Debug, Deserialize)]
pub struct DataKomponen {
    id_bahan_pangan: Option<u64>,
    nama_komponen: String,
    keterangan_porsi: Option<String>,
    berat_gram: Option<f64>,
    urutan: u8,
}

#[derive(Debug, FromRow)]
struct BahanHitung {
    nama: String,
    energi_per_100g: f64,
    protein_per_100g: f64,
    lemak_per_100g: f64,
    karbohidrat_per_100g: f64,
}

#[derive(Debug, Deserialize)]
pub struct DataAlergi {
    nama_alergi: String,
    keterangan: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct FilterMenuPublik {
    id_sekolah: u64,
    tanggal: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct FilterRiwayat {
    id_sekolah: u64,
    jumlah_hari: Option<u8>,
}

#[derive(Debug, Serialize)]
pub struct ResponsData<T> {
    sukses: bool,
    data: T,
}

#[derive(Debug, Serialize)]
pub struct ResponsPesan {
    sukses: bool,
    pesan: &'static str,
}

pub async fn daftar_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsData<Vec<MenuDetail>>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let daftar = sqlx::query_as::<_, MenuDasar>(PILIH_MENU_ADMIN)
        .bind(id_unit_sppg)
        .fetch_all(&state.database)
        .await
        .map_err(kesalahan_database)?;
    let data = muat_daftar_detail(&state, daftar).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn tambah(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(input): Json<DataMenu>,
) -> Result<(StatusCode, Json<ResponsData<MenuDetail>>), ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let input = siapkan_data_menu(&state, input).await?;
    pastikan_sekolah(&state, id_unit_sppg, input.id_sekolah).await?;

    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;
    let hasil = sqlx::query(
        r#"
        INSERT INTO menu_harian (
            id_unit_sppg, id_sekolah, kunci_cakupan, tanggal_menu, nama_menu, deskripsi,
            kalori, protein, lemak, karbohidrat, sumber_data_gizi,
            url_sumber_data_gizi, status, aktif
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(id_unit_sppg)
    .bind(input.id_sekolah)
    .bind(input.id_sekolah.unwrap_or(0))
    .bind(&input.tanggal_menu)
    .bind(&input.nama_menu)
    .bind(&input.deskripsi)
    .bind(input.kalori)
    .bind(input.protein)
    .bind(input.lemak)
    .bind(input.karbohidrat)
    .bind(&input.sumber_data_gizi)
    .bind(&input.url_sumber_data_gizi)
    .bind(&input.status)
    .bind(input.aktif.unwrap_or(true))
    .execute(&mut *transaksi)
    .await
    .map_err(map_kesalahan_simpan)?;
    let id_menu = hasil.last_insert_id();
    simpan_relasi(&mut transaksi, id_menu, &input).await?;
    transaksi.commit().await.map_err(kesalahan_database)?;

    let data = ambil_satu_detail(&state, id_menu, id_unit_sppg).await?;
    Ok((
        StatusCode::CREATED,
        Json(ResponsData { sukses: true, data }),
    ))
}

pub async fn ubah(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
    Json(input): Json<DataMenu>,
) -> Result<Json<ResponsData<MenuDetail>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let input = siapkan_data_menu(&state, input).await?;
    pastikan_sekolah(&state, id_unit_sppg, input.id_sekolah).await?;
    pastikan_menu_milik_unit(&state, id, id_unit_sppg).await?;

    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;
    sqlx::query(
        r#"
        UPDATE menu_harian SET
            id_sekolah = ?, kunci_cakupan = ?, tanggal_menu = ?, nama_menu = ?, deskripsi = ?,
            kalori = ?, protein = ?, lemak = ?, karbohidrat = ?,
            sumber_data_gizi = ?, url_sumber_data_gizi = ?, status = ?,
            aktif = COALESCE(?, aktif)
        WHERE id = ? AND id_unit_sppg = ?
        "#,
    )
    .bind(input.id_sekolah)
    .bind(input.id_sekolah.unwrap_or(0))
    .bind(&input.tanggal_menu)
    .bind(&input.nama_menu)
    .bind(&input.deskripsi)
    .bind(input.kalori)
    .bind(input.protein)
    .bind(input.lemak)
    .bind(input.karbohidrat)
    .bind(&input.sumber_data_gizi)
    .bind(&input.url_sumber_data_gizi)
    .bind(&input.status)
    .bind(input.aktif)
    .bind(id)
    .bind(id_unit_sppg)
    .execute(&mut *transaksi)
    .await
    .map_err(map_kesalahan_simpan)?;

    sqlx::query("DELETE FROM komponen_menu WHERE id_menu_harian = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    sqlx::query("DELETE FROM alergi_menu WHERE id_menu_harian = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    simpan_relasi(&mut transaksi, id, &input).await?;
    transaksi.commit().await.map_err(kesalahan_database)?;

    let data = ambil_satu_detail(&state, id, id_unit_sppg).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn nonaktifkan(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
) -> Result<Json<ResponsPesan>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    pastikan_menu_milik_unit(&state, id, id_unit_sppg).await?;
    sqlx::query("UPDATE menu_harian SET aktif = FALSE WHERE id = ? AND id_unit_sppg = ?")
        .bind(id)
        .bind(id_unit_sppg)
        .execute(&state.database)
        .await
        .map_err(kesalahan_database)?;

    Ok(Json(ResponsPesan {
        sukses: true,
        pesan: "Menu berhasil dinonaktifkan tanpa menghapus riwayat",
    }))
}

pub async fn hapus_permanen(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
) -> Result<Json<ResponsPesan>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    pastikan_menu_milik_unit(&state, id, id_unit_sppg).await?;

    let jumlah_aduan = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM aduan WHERE id_menu_harian = ? AND id_unit_sppg = ?",
    )
    .bind(id)
    .bind(id_unit_sppg)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)?;
    if jumlah_aduan > 0 {
        return Err(ApiError::konflik(
            "Menu memiliki riwayat aduan dan tidak dapat dihapus permanen. Gunakan nonaktifkan.",
        ));
    }

    let urls = sqlx::query_scalar::<_, String>(
        "SELECT url_berkas FROM media_menu WHERE id_menu_harian = ?",
    )
    .bind(id)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;

    sqlx::query("DELETE FROM menu_harian WHERE id = ? AND id_unit_sppg = ?")
        .bind(id)
        .bind(id_unit_sppg)
        .execute(&state.database)
        .await
        .map_err(kesalahan_database)?;

    for url in urls {
        if let Some(path) = path_dari_url(state.storage_path.as_ref(), &url) {
            hapus_berkas(&path).await;
        }
    }

    Ok(Json(ResponsPesan {
        sukses: true,
        pesan: "Menu berhasil dihapus permanen",
    }))
}

pub async fn menu_publik(
    State(state): State<AppState>,
    Query(filter): Query<FilterMenuPublik>,
) -> Result<Json<ResponsData<MenuDetail>>, ApiError> {
    let tanggal = validasi_tanggal_opsional(filter.tanggal)?;
    let menu = sqlx::query_as::<_, MenuDasar>(PILIH_MENU_PUBLIK)
        .bind(filter.id_sekolah)
        .bind(tanggal)
        .fetch_optional(&state.database)
        .await
        .map_err(kesalahan_database)?
        .ok_or_else(|| ApiError::tidak_ditemukan("Menu pada tanggal tersebut tidak ditemukan"))?;
    let data = muat_detail(&state, menu).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn riwayat_publik(
    State(state): State<AppState>,
    Query(filter): Query<FilterRiwayat>,
) -> Result<Json<ResponsData<Vec<MenuDetail>>>, ApiError> {
    let jumlah_hari = filter.jumlah_hari.unwrap_or(7);
    if !(1..=30).contains(&jumlah_hari) {
        return Err(ApiError::permintaan_tidak_valid(
            "Jumlah hari riwayat harus antara 1 dan 30",
        ));
    }
    let tanggal_akhir = Local::now().date_naive();
    let tanggal_awal = tanggal_akhir - chrono::Duration::days(i64::from(jumlah_hari - 1));
    let daftar = sqlx::query_as::<_, MenuDasar>(PILIH_RIWAYAT_PUBLIK)
        .bind(filter.id_sekolah)
        .bind(tanggal_awal.to_string())
        .bind(tanggal_akhir.to_string())
        .fetch_all(&state.database)
        .await
        .map_err(kesalahan_database)?;

    let mut tanggal_terpilih = HashSet::new();
    let daftar = daftar
        .into_iter()
        .filter(|menu| tanggal_terpilih.insert(menu.tanggal_menu.clone()))
        .collect();
    let data = muat_daftar_detail(&state, daftar).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

async fn simpan_relasi(
    transaksi: &mut Transaction<'_, MySql>,
    id_menu: u64,
    input: &DataMenu,
) -> Result<(), ApiError> {
    for komponen in &input.komponen {
        sqlx::query(
            r#"
            INSERT INTO komponen_menu
                (id_menu_harian, id_bahan_pangan, nama_komponen,
                 keterangan_porsi, berat_gram, urutan)
            VALUES (?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(id_menu)
        .bind(komponen.id_bahan_pangan)
        .bind(&komponen.nama_komponen)
        .bind(&komponen.keterangan_porsi)
        .bind(komponen.berat_gram)
        .bind(komponen.urutan)
        .execute(&mut **transaksi)
        .await
        .map_err(map_kesalahan_simpan)?;
    }
    for alergi in &input.alergi {
        sqlx::query(
            r#"
            INSERT INTO alergi_menu (id_menu_harian, nama_alergi, keterangan)
            VALUES (?, ?, ?)
            "#,
        )
        .bind(id_menu)
        .bind(&alergi.nama_alergi)
        .bind(&alergi.keterangan)
        .execute(&mut **transaksi)
        .await
        .map_err(map_kesalahan_simpan)?;
    }
    Ok(())
}

async fn muat_daftar_detail(
    state: &AppState,
    daftar: Vec<MenuDasar>,
) -> Result<Vec<MenuDetail>, ApiError> {
    let mut hasil = Vec::with_capacity(daftar.len());
    for menu in daftar {
        hasil.push(muat_detail(state, menu).await?);
    }
    Ok(hasil)
}

async fn muat_detail(state: &AppState, menu: MenuDasar) -> Result<MenuDetail, ApiError> {
    let komponen = sqlx::query_as::<_, KomponenMenu>(
        r#"
        SELECT id, id_bahan_pangan, nama_komponen, keterangan_porsi,
               CAST(berat_gram AS DOUBLE) AS berat_gram, urutan
        FROM komponen_menu WHERE id_menu_harian = ? ORDER BY urutan, id
        "#,
    )
    .bind(menu.id)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;
    let alergi = sqlx::query_as::<_, AlergiMenu>(
        r#"
        SELECT id, nama_alergi, keterangan
        FROM alergi_menu WHERE id_menu_harian = ? ORDER BY nama_alergi
        "#,
    )
    .bind(menu.id)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;
    let media = media_menu::daftar_untuk_menu(state, menu.id).await?;
    Ok(MenuDetail {
        menu,
        komponen,
        alergi,
        media,
    })
}

async fn ambil_satu_detail(
    state: &AppState,
    id: u64,
    id_unit_sppg: u64,
) -> Result<MenuDetail, ApiError> {
    let menu = sqlx::query_as::<_, MenuDasar>(PILIH_SATU_MENU_ADMIN)
        .bind(id)
        .bind(id_unit_sppg)
        .fetch_optional(&state.database)
        .await
        .map_err(kesalahan_database)?
        .ok_or_else(|| ApiError::tidak_ditemukan("Menu tidak ditemukan"))?;
    muat_detail(state, menu).await
}

pub(super) async fn pastikan_menu_milik_unit(
    state: &AppState,
    id: u64,
    id_unit_sppg: u64,
) -> Result<(), ApiError> {
    let ada = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM menu_harian WHERE id = ? AND id_unit_sppg = ?",
    )
    .bind(id)
    .bind(id_unit_sppg)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)?
        > 0;
    if !ada {
        return Err(ApiError::tidak_ditemukan(
            "Menu tidak ditemukan pada unit SPPG ini",
        ));
    }
    Ok(())
}

async fn pastikan_sekolah(
    state: &AppState,
    id_unit_sppg: u64,
    id_sekolah: Option<u64>,
) -> Result<(), ApiError> {
    let Some(id_sekolah) = id_sekolah else {
        return Ok(());
    };
    let ada = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM sekolah
        WHERE id = ? AND id_unit_sppg = ? AND aktif = TRUE
        "#,
    )
    .bind(id_sekolah)
    .bind(id_unit_sppg)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)?
        > 0;
    if !ada {
        return Err(ApiError::permintaan_tidak_valid(
            "Sekolah tidak aktif atau bukan bagian dari unit SPPG ini",
        ));
    }
    Ok(())
}

impl DataMenu {
    fn rapikan_dan_validasi(mut self) -> Result<Self, ApiError> {
        NaiveDate::parse_from_str(self.tanggal_menu.trim(), "%Y-%m-%d").map_err(|_| {
            ApiError::permintaan_tidak_valid("Tanggal menu harus memakai format YYYY-MM-DD")
        })?;
        self.tanggal_menu = self.tanggal_menu.trim().to_owned();
        self.nama_menu = self.nama_menu.trim().to_owned();
        self.deskripsi = self.deskripsi.trim().to_owned();
        self.sumber_data_gizi = self.sumber_data_gizi.trim().to_owned();
        self.url_sumber_data_gizi = self.url_sumber_data_gizi.trim().to_owned();
        self.status = self.status.trim().to_lowercase();

        if self.nama_menu.is_empty()
            || self.deskripsi.is_empty()
            || self.sumber_data_gizi.is_empty()
        {
            return Err(ApiError::permintaan_tidak_valid(
                "Nama, deskripsi, dan sumber data gizi wajib diisi",
            ));
        }
        if !self.url_sumber_data_gizi.starts_with("https://")
            && !self.url_sumber_data_gizi.starts_with("http://")
        {
            return Err(ApiError::permintaan_tidak_valid(
                "URL sumber data gizi harus diawali http:// atau https://",
            ));
        }
        if !["draf", "dipublikasikan"].contains(&self.status.as_str()) {
            return Err(ApiError::permintaan_tidak_valid(
                "Status menu harus draf atau dipublikasikan",
            ));
        }
        if self.kalori == 0
            || !self.protein.is_finite()
            || !self.lemak.is_finite()
            || !self.karbohidrat.is_finite()
            || self.protein < 0.0
            || self.lemak < 0.0
            || self.karbohidrat < 0.0
        {
            return Err(ApiError::permintaan_tidak_valid(
                "Nilai nutrisi harus berupa angka valid dan tidak boleh negatif",
            ));
        }
        if self.komponen.is_empty() || self.komponen.len() > 20 {
            return Err(ApiError::permintaan_tidak_valid(
                "Menu harus memiliki 1 sampai 20 komponen makanan",
            ));
        }
        if self.alergi.len() > 7 {
            return Err(ApiError::permintaan_tidak_valid(
                "Kategori alergi melebihi batas yang tersedia",
            ));
        }

        let mut nama_komponen = HashSet::new();
        for komponen in &mut self.komponen {
            komponen.nama_komponen = komponen.nama_komponen.trim().to_owned();
            komponen.keterangan_porsi = rapikan_opsional(komponen.keterangan_porsi.take());
            if komponen.nama_komponen.is_empty()
                || !nama_komponen.insert(komponen.nama_komponen.to_lowercase())
            {
                return Err(ApiError::permintaan_tidak_valid(
                    "Nama komponen wajib diisi dan tidak boleh ganda",
                ));
            }
            if komponen
                .berat_gram
                .is_some_and(|berat| !berat.is_finite() || berat <= 0.0 || berat > 2000.0)
            {
                return Err(ApiError::permintaan_tidak_valid(
                    "Berat bahan harus lebih dari 0 dan maksimal 2000 gram",
                ));
            }
        }

        let kategori = [
            "telur", "susu", "kacang", "seafood", "gluten", "kedelai", "lainnya",
        ];
        let mut nama_alergi = HashSet::new();
        for alergi in &mut self.alergi {
            alergi.nama_alergi = alergi.nama_alergi.trim().to_lowercase();
            alergi.keterangan = rapikan_opsional(alergi.keterangan.take());
            if !kategori.contains(&alergi.nama_alergi.as_str())
                || !nama_alergi.insert(alergi.nama_alergi.clone())
            {
                return Err(ApiError::permintaan_tidak_valid(
                    "Kategori alergi tidak valid atau dipilih lebih dari sekali",
                ));
            }
        }
        Ok(self)
    }
}

async fn siapkan_data_menu(state: &AppState, mut input: DataMenu) -> Result<DataMenu, ApiError> {
    let jumlah_bahan_terpilih = input
        .komponen
        .iter()
        .filter(|item| item.id_bahan_pangan.is_some() || item.berat_gram.is_some())
        .count();
    if jumlah_bahan_terpilih == 0 {
        return input.rapikan_dan_validasi();
    }
    if jumlah_bahan_terpilih != input.komponen.len()
        || input
            .komponen
            .iter()
            .any(|item| item.id_bahan_pangan.is_none() || item.berat_gram.is_none())
    {
        return Err(ApiError::permintaan_tidak_valid(
            "Setiap komponen otomatis wajib memilih bahan katalog dan berat saji",
        ));
    }

    let mut kalori = 0.0;
    let mut protein = 0.0;
    let mut lemak = 0.0;
    let mut karbohidrat = 0.0;
    let mut alergi = HashSet::new();
    let mut id_bahan_unik = HashSet::new();
    for komponen in &mut input.komponen {
        let id_bahan = komponen.id_bahan_pangan.expect("sudah divalidasi");
        let berat = komponen.berat_gram.expect("sudah divalidasi");
        if !id_bahan_unik.insert(id_bahan) {
            return Err(ApiError::permintaan_tidak_valid(
                "Bahan katalog tidak boleh dipilih lebih dari sekali",
            ));
        }
        if !berat.is_finite() || berat <= 0.0 || berat > 2000.0 {
            return Err(ApiError::permintaan_tidak_valid(
                "Berat bahan harus lebih dari 0 dan maksimal 2000 gram",
            ));
        }
        let bahan = sqlx::query_as::<_, BahanHitung>(
            r#"
            SELECT nama,
                   CAST(energi_per_100g AS DOUBLE) AS energi_per_100g,
                   CAST(protein_per_100g AS DOUBLE) AS protein_per_100g,
                   CAST(lemak_per_100g AS DOUBLE) AS lemak_per_100g,
                   CAST(karbohidrat_per_100g AS DOUBLE) AS karbohidrat_per_100g
            FROM bahan_pangan
            WHERE id = ? AND aktif = TRUE
            "#,
        )
        .bind(id_bahan)
        .fetch_optional(&state.database)
        .await
        .map_err(kesalahan_database)?
        .ok_or_else(|| ApiError::permintaan_tidak_valid("Bahan katalog tidak tersedia"))?;
        let faktor = berat / 100.0;
        kalori += bahan.energi_per_100g * faktor;
        protein += bahan.protein_per_100g * faktor;
        lemak += bahan.lemak_per_100g * faktor;
        karbohidrat += bahan.karbohidrat_per_100g * faktor;
        komponen.nama_komponen = bahan.nama;
        komponen.keterangan_porsi = Some(format!("{} gram", rapikan_angka(berat)));
        alergi.extend(
            sqlx::query_scalar::<_, String>(
                "SELECT nama_alergi FROM alergi_bahan_pangan WHERE id_bahan_pangan = ?",
            )
            .bind(id_bahan)
            .fetch_all(&state.database)
            .await
            .map_err(kesalahan_database)?,
        );
    }

    input.kalori = kalori.round().clamp(1.0, u16::MAX as f64) as u16;
    input.protein = bulatkan_dua(protein);
    input.lemak = bulatkan_dua(lemak);
    input.karbohidrat = bulatkan_dua(karbohidrat);
    input.sumber_data_gizi = "TKPI Kementerian Kesehatan RI 2020".to_owned();
    input.url_sumber_data_gizi = "https://repository.kemkes.go.id/book/668".to_owned();
    let mut daftar_alergi = alergi.into_iter().collect::<Vec<_>>();
    daftar_alergi.sort();
    input.alergi = daftar_alergi
        .into_iter()
        .map(|nama_alergi| DataAlergi {
            nama_alergi,
            keterangan: Some("Ditentukan otomatis dari bahan katalog".to_owned()),
        })
        .collect();
    input.rapikan_dan_validasi()
}

fn bulatkan_dua(nilai: f64) -> f64 {
    (nilai * 100.0).round() / 100.0
}

fn rapikan_angka(nilai: f64) -> String {
    if nilai.fract().abs() < f64::EPSILON {
        format!("{nilai:.0}")
    } else {
        format!("{nilai:.2}").trim_end_matches('0').to_owned()
    }
}

fn validasi_tanggal_opsional(tanggal: Option<String>) -> Result<String, ApiError> {
    let tanggal = tanggal.unwrap_or_else(|| Local::now().date_naive().to_string());
    NaiveDate::parse_from_str(tanggal.trim(), "%Y-%m-%d")
        .map(|tanggal| tanggal.to_string())
        .map_err(|_| ApiError::permintaan_tidak_valid("Tanggal harus memakai format YYYY-MM-DD"))
}

fn rapikan_opsional(nilai: Option<String>) -> Option<String> {
    nilai
        .map(|nilai| nilai.trim().to_owned())
        .filter(|nilai| !nilai.is_empty())
}

fn map_kesalahan_simpan(error: sqlx::Error) -> ApiError {
    if error
        .as_database_error()
        .is_some_and(|database_error| database_error.is_unique_violation())
    {
        return ApiError::konflik("Menu untuk tanggal dan cakupan sekolah tersebut sudah tersedia");
    }
    kesalahan_database(error)
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Operasi database menu harian gagal");
    ApiError::kesalahan_internal()
}
