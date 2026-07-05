use axum::http::HeaderMap;

use super::autentikasi::validasi_token;
use crate::{error::ApiError, state::AppState};

pub(super) async fn wajib_admin_sppg_aktif(
    headers: &HeaderMap,
    state: &AppState,
) -> Result<u64, ApiError> {
    let klaim = validasi_token(headers, state)?;
    let id_admin = klaim
        .sub
        .parse::<u64>()
        .map_err(|_| ApiError::tidak_terautentikasi("Token akses tidak valid"))?;

    if klaim.peran == "super_admin" {
        let id_unit_sppg = headers
            .get("x-unit-sppg-id")
            .and_then(|value| value.to_str().ok())
            .and_then(|value| value.parse::<u64>().ok())
            .ok_or_else(|| {
                ApiError::permintaan_tidak_valid(
                    "Super admin harus memilih unit SPPG terlebih dahulu",
                )
            })?;

        let valid = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*)
            FROM admin a
            INNER JOIN unit_sppg u ON u.id = ?
            WHERE a.id = ? AND a.peran = 'super_admin'
              AND a.aktif = TRUE AND u.aktif = TRUE
            "#,
        )
        .bind(id_unit_sppg)
        .bind(id_admin)
        .fetch_one(&state.database)
        .await
        .map_err(|error| {
            tracing::error!(%error, "Pemeriksaan akses super admin gagal");
            ApiError::kesalahan_internal()
        })? > 0;

        if !valid {
            return Err(ApiError::akses_ditolak(
                "Akun super admin atau unit SPPG sedang tidak aktif",
            ));
        }

        return Ok(id_unit_sppg);
    }

    if klaim.peran != "admin_sppg" {
        return Err(ApiError::akses_ditolak(
            "Fitur ini hanya dapat digunakan oleh admin SPPG atau super admin",
        ));
    }

    let id_unit_sppg = klaim
        .id_unit_sppg
        .ok_or_else(|| ApiError::akses_ditolak("Admin tidak terhubung ke unit SPPG"))?;
    let valid = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*)
        FROM admin a
        INNER JOIN unit_sppg u ON u.id = a.id_unit_sppg
        WHERE a.id = ? AND a.id_unit_sppg = ? AND a.aktif = TRUE AND u.aktif = TRUE
        "#,
    )
    .bind(id_admin)
    .bind(id_unit_sppg)
    .fetch_one(&state.database)
    .await
    .map_err(|error| {
        tracing::error!(%error, "Pemeriksaan akses admin SPPG gagal");
        ApiError::kesalahan_internal()
    })? > 0;

    if !valid {
        return Err(ApiError::akses_ditolak(
            "Akun admin atau unit SPPG sedang tidak aktif",
        ));
    }

    Ok(id_unit_sppg)
}
