use axum::{Json, extract::State};
use serde::Serialize;

use crate::{error::ApiError, state::AppState};

#[derive(Debug, Serialize)]
pub struct InformasiLayanan {
    nama: &'static str,
    deskripsi: &'static str,
    versi: &'static str,
}

#[derive(Debug, Serialize)]
pub struct StatusKesehatan {
    status: &'static str,
    layanan: &'static str,
    database: &'static str,
    versi: &'static str,
}

pub async fn informasi_layanan() -> Json<InformasiLayanan> {
    Json(InformasiLayanan {
        nama: "Nuara API",
        deskripsi: "Web API Nutrisi Anak Nusantara",
        versi: env!("CARGO_PKG_VERSION"),
    })
}

pub async fn periksa_kesehatan(
    State(state): State<AppState>,
) -> Result<Json<StatusKesehatan>, ApiError> {
    sqlx::query_scalar::<_, i32>("SELECT 1")
        .fetch_one(&state.database)
        .await
        .map_err(|error| {
            tracing::error!(%error, "Pemeriksaan database gagal");
            ApiError::layanan_tidak_tersedia("Database belum dapat dihubungi")
        })?;

    Ok(Json(StatusKesehatan {
        status: "sehat",
        layanan: "aktif",
        database: "terhubung",
        versi: env!("CARGO_PKG_VERSION"),
    }))
}
