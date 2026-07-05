use axum::{
    Json,
    extract::{Multipart, Path, State},
    http::{HeaderMap, StatusCode},
};
use serde::Serialize;
use sqlx::FromRow;

use super::{
    menu::pastikan_menu_milik_unit,
    otorisasi::wajib_admin_sppg_aktif,
    upload::{hapus_berkas, path_dari_url, simpan_multipart},
};
use crate::{error::ApiError, state::AppState};

#[derive(Debug, FromRow, Serialize)]
pub(super) struct MediaMenu {
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
pub struct ResponsData<T> {
    sukses: bool,
    data: T,
}

#[derive(Debug, Serialize)]
pub struct ResponsPesan {
    sukses: bool,
    pesan: &'static str,
}

pub async fn unggah(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id_menu): Path<u64>,
    multipart: Multipart,
) -> Result<(StatusCode, Json<ResponsData<MediaMenu>>), ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    pastikan_menu_milik_unit(&state, id_menu, id_unit_sppg).await?;
    let form = simpan_multipart(
        multipart,
        state.storage_path.as_ref(),
        &format!("menu/{id_menu}"),
    )
    .await?;
    let berkas = form.berkas;

    let hasil = sqlx::query(
        r#"
        INSERT INTO media_menu (
            id_menu_harian, jenis_media, url_berkas, nama_berkas,
            ukuran_byte, mime_type, durasi_detik
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(id_menu)
    .bind(berkas.jenis_media)
    .bind(&berkas.url_berkas)
    .bind(&berkas.nama_berkas)
    .bind(berkas.ukuran_byte)
    .bind(&berkas.mime_type)
    .bind(berkas.durasi_detik)
    .execute(&state.database)
    .await;

    let hasil = match hasil {
        Ok(hasil) => hasil,
        Err(error) => {
            hapus_berkas(&berkas.path_lokal).await;
            return Err(kesalahan_database(error));
        }
    };
    let data = ambil_satu(&state, hasil.last_insert_id()).await?;
    Ok((
        StatusCode::CREATED,
        Json(ResponsData { sukses: true, data }),
    ))
}

pub async fn hapus(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
) -> Result<Json<ResponsPesan>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let url = sqlx::query_scalar::<_, String>(
        r#"
        SELECT mm.url_berkas
        FROM media_menu mm
        INNER JOIN menu_harian m ON m.id = mm.id_menu_harian
        WHERE mm.id = ? AND m.id_unit_sppg = ?
        LIMIT 1
        "#,
    )
    .bind(id)
    .bind(id_unit_sppg)
    .fetch_optional(&state.database)
    .await
    .map_err(kesalahan_database)?
    .ok_or_else(|| ApiError::tidak_ditemukan("Media menu tidak ditemukan"))?;

    sqlx::query("DELETE FROM media_menu WHERE id = ?")
        .bind(id)
        .execute(&state.database)
        .await
        .map_err(kesalahan_database)?;
    if let Some(path) = path_dari_url(state.storage_path.as_ref(), &url) {
        hapus_berkas(&path).await;
    }

    Ok(Json(ResponsPesan {
        sukses: true,
        pesan: "Media menu berhasil dihapus",
    }))
}

pub(super) async fn daftar_untuk_menu(
    state: &AppState,
    id_menu: u64,
) -> Result<Vec<MediaMenu>, ApiError> {
    sqlx::query_as::<_, MediaMenu>(
        r#"
        SELECT id, jenis_media, url_berkas, nama_berkas, ukuran_byte,
               mime_type, durasi_detik,
               DATE_FORMAT(created_at, '%Y-%m-%dT%H:%i:%s') AS created_at
        FROM media_menu
        WHERE id_menu_harian = ?
        ORDER BY created_at DESC, id DESC
        "#,
    )
    .bind(id_menu)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)
}

async fn ambil_satu(state: &AppState, id: u64) -> Result<MediaMenu, ApiError> {
    sqlx::query_as::<_, MediaMenu>(
        r#"
        SELECT id, jenis_media, url_berkas, nama_berkas, ukuran_byte,
               mime_type, durasi_detik,
               DATE_FORMAT(created_at, '%Y-%m-%dT%H:%i:%s') AS created_at
        FROM media_menu WHERE id = ?
        "#,
    )
    .bind(id)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Operasi database media menu gagal");
    ApiError::kesalahan_internal()
}
