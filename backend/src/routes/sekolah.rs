use axum::{
    Json,
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use super::{otorisasi::wajib_admin_sppg_aktif, unit_sppg::validasi_rt_rw};
use crate::{error::ApiError, state::AppState};

const PILIH_DAFTAR_SEKOLAH: &str = r#"
    SELECT
        s.id, s.id_unit_sppg, s.nama, s.jenjang, s.provinsi, s.kabupaten_kota,
        s.kecamatan, s.kelurahan_desa, s.kode_pos, s.rt, s.rw, s.alamat_detail,
        s.aktif,
        DATE_FORMAT(s.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(s.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM sekolah s
    WHERE s.id_unit_sppg = ? AND (? = FALSE OR s.aktif = TRUE)
    ORDER BY s.jenjang, s.nama
"#;

const PILIH_SATU_SEKOLAH: &str = r#"
    SELECT
        s.id, s.id_unit_sppg, s.nama, s.jenjang, s.provinsi, s.kabupaten_kota,
        s.kecamatan, s.kelurahan_desa, s.kode_pos, s.rt, s.rw, s.alamat_detail,
        s.aktif,
        DATE_FORMAT(s.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(s.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM sekolah s
    WHERE s.id = ? AND s.id_unit_sppg = ?
"#;

#[derive(Debug, FromRow, Serialize)]
pub struct Sekolah {
    id: u64,
    id_unit_sppg: u64,
    nama: String,
    jenjang: String,
    provinsi: String,
    kabupaten_kota: String,
    kecamatan: String,
    kelurahan_desa: String,
    kode_pos: String,
    rt: String,
    rw: String,
    alamat_detail: String,
    aktif: bool,
    created_at: String,
    update_at: String,
}

#[derive(Debug, Deserialize)]
pub struct DataSekolah {
    nama: String,
    jenjang: String,
    rt: String,
    rw: String,
    alamat_detail: String,
    aktif: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct FilterStatusPilihan {
    id_unit_sppg: u64,
    id_sekolah: u64,
}

#[derive(Debug, FromRow)]
struct AlamatUnitSppg {
    provinsi: String,
    kabupaten_kota: String,
    kecamatan: String,
    kelurahan_desa: String,
    kode_pos: String,
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

pub async fn status_pilihan(
    State(state): State<AppState>,
    Query(filter): Query<FilterStatusPilihan>,
) -> Result<Json<ResponsData<bool>>, ApiError> {
    let aktif = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1
            FROM sekolah s
            INNER JOIN unit_sppg u ON u.id = s.id_unit_sppg
            WHERE u.id = ? AND s.id = ?
              AND u.aktif = TRUE AND s.aktif = TRUE
        )
        "#,
    )
    .bind(filter.id_unit_sppg)
    .bind(filter.id_sekolah)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)?;

    Ok(Json(ResponsData {
        sukses: true,
        data: aktif,
    }))
}

pub async fn daftar_publik(
    State(state): State<AppState>,
    Path(id_unit_sppg): Path<u64>,
) -> Result<Json<ResponsData<Vec<Sekolah>>>, ApiError> {
    let unit_tersedia = sqlx::query_scalar::<_, bool>(
        "SELECT aktif FROM unit_sppg WHERE id = ? AND aktif = TRUE LIMIT 1",
    )
    .bind(id_unit_sppg)
    .fetch_optional(&state.database)
    .await
    .map_err(kesalahan_database)?
    .is_some();
    if !unit_tersedia {
        return Err(ApiError::tidak_ditemukan("Unit SPPG aktif tidak ditemukan"));
    }

    let data = ambil_daftar(&state, id_unit_sppg, true).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn daftar_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsData<Vec<Sekolah>>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let data = ambil_daftar(&state, id_unit_sppg, false).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn tambah(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(input): Json<DataSekolah>,
) -> Result<(StatusCode, Json<ResponsData<Sekolah>>), ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let input = input.rapikan_dan_validasi()?;
    let alamat_unit = ambil_alamat_unit(&state, id_unit_sppg).await?;

    let hasil = sqlx::query(
        r#"
        INSERT INTO sekolah (
            id_unit_sppg, nama, jenjang, provinsi, kabupaten_kota, kecamatan,
            kelurahan_desa, kode_pos, rt, rw, alamat_detail, aktif
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)
        "#,
    )
    .bind(id_unit_sppg)
    .bind(&input.nama)
    .bind(&input.jenjang)
    .bind(&alamat_unit.provinsi)
    .bind(&alamat_unit.kabupaten_kota)
    .bind(&alamat_unit.kecamatan)
    .bind(&alamat_unit.kelurahan_desa)
    .bind(&alamat_unit.kode_pos)
    .bind(&input.rt)
    .bind(&input.rw)
    .bind(&input.alamat_detail)
    .execute(&state.database)
    .await
    .map_err(map_kesalahan_simpan)?;

    let data = ambil_satu(&state, hasil.last_insert_id(), id_unit_sppg).await?;
    Ok((
        StatusCode::CREATED,
        Json(ResponsData { sukses: true, data }),
    ))
}

pub async fn ubah(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
    Json(input): Json<DataSekolah>,
) -> Result<Json<ResponsData<Sekolah>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let input = input.rapikan_dan_validasi()?;
    let alamat_unit = ambil_alamat_unit(&state, id_unit_sppg).await?;

    let hasil = sqlx::query(
        r#"
        UPDATE sekolah SET
            nama = ?, jenjang = ?, provinsi = ?, kabupaten_kota = ?, kecamatan = ?,
            kelurahan_desa = ?, kode_pos = ?, rt = ?, rw = ?, alamat_detail = ?,
            aktif = COALESCE(?, aktif)
        WHERE id = ? AND id_unit_sppg = ?
        "#,
    )
    .bind(&input.nama)
    .bind(&input.jenjang)
    .bind(&alamat_unit.provinsi)
    .bind(&alamat_unit.kabupaten_kota)
    .bind(&alamat_unit.kecamatan)
    .bind(&alamat_unit.kelurahan_desa)
    .bind(&alamat_unit.kode_pos)
    .bind(&input.rt)
    .bind(&input.rw)
    .bind(&input.alamat_detail)
    .bind(input.aktif)
    .bind(id)
    .bind(id_unit_sppg)
    .execute(&state.database)
    .await
    .map_err(map_kesalahan_simpan)?;

    if hasil.rows_affected() == 0 {
        let ada = sekolah_milik_unit_ada(&state, id, id_unit_sppg).await?;
        if !ada {
            return Err(ApiError::tidak_ditemukan(
                "Sekolah tidak ditemukan pada unit SPPG ini",
            ));
        }
    }

    let data = ambil_satu(&state, id, id_unit_sppg).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn nonaktifkan(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
) -> Result<Json<ResponsPesan>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let hasil = sqlx::query("UPDATE sekolah SET aktif = FALSE WHERE id = ? AND id_unit_sppg = ?")
        .bind(id)
        .bind(id_unit_sppg)
        .execute(&state.database)
        .await
        .map_err(kesalahan_database)?;

    if hasil.rows_affected() == 0 {
        let ada = sekolah_milik_unit_ada(&state, id, id_unit_sppg).await?;
        if !ada {
            return Err(ApiError::tidak_ditemukan(
                "Sekolah tidak ditemukan pada unit SPPG ini",
            ));
        }
    }

    Ok(Json(ResponsPesan {
        sukses: true,
        pesan: "Sekolah berhasil dinonaktifkan",
    }))
}

async fn ambil_daftar(
    state: &AppState,
    id_unit_sppg: u64,
    hanya_aktif: bool,
) -> Result<Vec<Sekolah>, ApiError> {
    sqlx::query_as::<_, Sekolah>(PILIH_DAFTAR_SEKOLAH)
        .bind(id_unit_sppg)
        .bind(hanya_aktif)
        .fetch_all(&state.database)
        .await
        .map_err(kesalahan_database)
}

async fn ambil_satu(state: &AppState, id: u64, id_unit_sppg: u64) -> Result<Sekolah, ApiError> {
    sqlx::query_as::<_, Sekolah>(PILIH_SATU_SEKOLAH)
        .bind(id)
        .bind(id_unit_sppg)
        .fetch_optional(&state.database)
        .await
        .map_err(kesalahan_database)?
        .ok_or_else(|| ApiError::tidak_ditemukan("Sekolah tidak ditemukan"))
}

async fn sekolah_milik_unit_ada(
    state: &AppState,
    id: u64,
    id_unit_sppg: u64,
) -> Result<bool, ApiError> {
    sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM sekolah WHERE id = ? AND id_unit_sppg = ?")
        .bind(id)
        .bind(id_unit_sppg)
        .fetch_one(&state.database)
        .await
        .map(|jumlah| jumlah > 0)
        .map_err(kesalahan_database)
}

async fn ambil_alamat_unit(
    state: &AppState,
    id_unit_sppg: u64,
) -> Result<AlamatUnitSppg, ApiError> {
    sqlx::query_as::<_, AlamatUnitSppg>(
        r#"
        SELECT provinsi, kabupaten_kota, kecamatan, kelurahan_desa, kode_pos
        FROM unit_sppg
        WHERE id = ? AND aktif = TRUE
        LIMIT 1
        "#,
    )
    .bind(id_unit_sppg)
    .fetch_optional(&state.database)
    .await
    .map_err(kesalahan_database)?
    .ok_or_else(|| ApiError::tidak_ditemukan("Unit SPPG aktif tidak ditemukan"))
}

impl DataSekolah {
    fn rapikan_dan_validasi(mut self) -> Result<Self, ApiError> {
        self.nama = self.nama.trim().to_owned();
        self.jenjang = self.jenjang.trim().to_uppercase();
        self.rt = self.rt.trim().to_owned();
        self.rw = self.rw.trim().to_owned();
        self.alamat_detail = self.alamat_detail.trim().to_owned();

        let wajib = [&self.nama, &self.rt, &self.rw, &self.alamat_detail];
        if wajib.iter().any(|nilai| nilai.is_empty()) {
            return Err(ApiError::permintaan_tidak_valid(
                "Nama sekolah, RT, RW, dan alamat detail wajib diisi",
            ));
        }
        if !["SD", "SMP", "SMA", "SMK", "SLB", "LAINNYA"].contains(&self.jenjang.as_str()) {
            return Err(ApiError::permintaan_tidak_valid(
                "Jenjang harus SD, SMP, SMA, SMK, SLB, atau LAINNYA",
            ));
        }
        validasi_rt_rw(&self.rt, &self.rw)?;
        Ok(self)
    }
}

fn map_kesalahan_simpan(error: sqlx::Error) -> ApiError {
    if error
        .as_database_error()
        .is_some_and(|database_error| database_error.is_unique_violation())
    {
        return ApiError::konflik("Nama sekolah sudah digunakan pada unit SPPG ini");
    }
    kesalahan_database(error)
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Operasi database sekolah gagal");
    ApiError::kesalahan_internal()
}
