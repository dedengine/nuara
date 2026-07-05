use axum::{
    Json,
    extract::{Path, State},
};
use serde::Serialize;
use sqlx::FromRow;

use crate::{error::ApiError, state::AppState};

#[derive(Debug, FromRow, Serialize)]
pub struct Wilayah {
    kode: String,
    nama: String,
    kode_pos: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ResponsWilayah {
    sukses: bool,
    data: Vec<Wilayah>,
}

#[derive(Debug, Serialize)]
pub struct ResponsKodePos {
    sukses: bool,
    data: Vec<String>,
}

pub async fn daftar_provinsi(
    State(state): State<AppState>,
) -> Result<Json<ResponsWilayah>, ApiError> {
    daftar_tingkat(&state, "provinsi", None).await
}

pub async fn daftar_kabupaten_kota(
    State(state): State<AppState>,
    Path(kode_provinsi): Path<String>,
) -> Result<Json<ResponsWilayah>, ApiError> {
    daftar_tingkat(&state, "kabupaten_kota", Some(kode_provinsi)).await
}

pub async fn daftar_kecamatan(
    State(state): State<AppState>,
    Path(kode_kabupaten_kota): Path<String>,
) -> Result<Json<ResponsWilayah>, ApiError> {
    daftar_tingkat(&state, "kecamatan", Some(kode_kabupaten_kota)).await
}

pub async fn daftar_kelurahan_desa(
    State(state): State<AppState>,
    Path(kode_kecamatan): Path<String>,
) -> Result<Json<ResponsWilayah>, ApiError> {
    daftar_tingkat(&state, "kelurahan_desa", Some(kode_kecamatan)).await
}

pub async fn daftar_kode_pos(
    State(state): State<AppState>,
    Path(kode_kelurahan_desa): Path<String>,
) -> Result<Json<ResponsKodePos>, ApiError> {
    let data = sqlx::query_scalar::<_, String>(
        r#"
        SELECT DISTINCT kode_pos
        FROM referensi_wilayah
        WHERE kode = ? AND tingkat = 'kelurahan_desa' AND kode_pos IS NOT NULL
        ORDER BY kode_pos
        "#,
    )
    .bind(kode_kelurahan_desa)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;

    Ok(Json(ResponsKodePos { sukses: true, data }))
}

async fn daftar_tingkat(
    state: &AppState,
    tingkat: &str,
    kode_induk: Option<String>,
) -> Result<Json<ResponsWilayah>, ApiError> {
    let data = sqlx::query_as::<_, Wilayah>(
        r#"
        SELECT kode, nama, kode_pos
        FROM referensi_wilayah
        WHERE tingkat = ? AND ((? IS NULL AND kode_induk IS NULL) OR kode_induk = ?)
        ORDER BY nama
        "#,
    )
    .bind(tingkat)
    .bind(&kode_induk)
    .bind(&kode_induk)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;

    Ok(Json(ResponsWilayah { sukses: true, data }))
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Gagal mengambil referensi wilayah Indonesia");
    ApiError::kesalahan_internal()
}
