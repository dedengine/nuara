use argon2::{
    Argon2,
    password_hash::{PasswordHasher, SaltString, rand_core::OsRng},
};
use axum::{
    Json,
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, MySql, Transaction};

use super::autentikasi::validasi_token;
use super::upload::{hapus_berkas, path_dari_url};
use crate::{error::ApiError, state::AppState};

const PASSWORD_DEFAULT_ADMIN: &str = "nuara123";

const PILIH_UNIT_SPPG: &str = r#"
    SELECT
        u.id, u.kode, u.nama, u.kode_provinsi, u.provinsi,
        u.kode_kabupaten_kota, u.kabupaten_kota, u.kode_kecamatan, u.kecamatan,
        u.kode_kelurahan_desa, u.kelurahan_desa, u.kode_pos, u.rt, u.rw, u.alamat_detail,
        u.nomor_telepon, u.aktif,
        (SELECT COUNT(*) FROM sekolah s WHERE s.id_unit_sppg = u.id) AS jumlah_sekolah,
        (SELECT a.id FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS id_admin,
        (SELECT a.nama FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS nama_admin,
        (SELECT a.email FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS email_admin,
        DATE_FORMAT(u.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(u.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM unit_sppg u
    WHERE (? = FALSE OR u.aktif = TRUE)
    ORDER BY u.provinsi, u.kabupaten_kota, u.nama
"#;

const PILIH_SATU_UNIT_SPPG: &str = r#"
    SELECT
        u.id, u.kode, u.nama, u.kode_provinsi, u.provinsi,
        u.kode_kabupaten_kota, u.kabupaten_kota, u.kode_kecamatan, u.kecamatan,
        u.kode_kelurahan_desa, u.kelurahan_desa, u.kode_pos, u.rt, u.rw, u.alamat_detail,
        u.nomor_telepon, u.aktif,
        (SELECT COUNT(*) FROM sekolah s WHERE s.id_unit_sppg = u.id) AS jumlah_sekolah,
        (SELECT a.id FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS id_admin,
        (SELECT a.nama FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS nama_admin,
        (SELECT a.email FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS email_admin,
        DATE_FORMAT(u.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(u.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM unit_sppg u
    WHERE u.id = ?
"#;

const PILIH_UNIT_SPPG_PUBLIK: &str = r#"
    SELECT
        u.id, u.kode, u.nama, u.kode_provinsi, u.provinsi,
        u.kode_kabupaten_kota, u.kabupaten_kota, u.kode_kecamatan, u.kecamatan,
        u.kode_kelurahan_desa, u.kelurahan_desa, u.kode_pos, u.rt, u.rw,
        u.alamat_detail, u.nomor_telepon, u.aktif,
        (SELECT COUNT(*) FROM sekolah s WHERE s.id_unit_sppg = u.id) AS jumlah_sekolah,
        (SELECT a.id FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS id_admin,
        (SELECT a.nama FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS nama_admin,
        (SELECT a.email FROM admin a WHERE a.id_unit_sppg = u.id LIMIT 1) AS email_admin,
        DATE_FORMAT(u.created_at, '%Y-%m-%dT%H:%i:%s') AS created_at,
        DATE_FORMAT(u.update_at, '%Y-%m-%dT%H:%i:%s') AS update_at
    FROM unit_sppg u
    WHERE u.aktif = TRUE
        AND u.kode_provinsi = ?
        AND u.kode_kabupaten_kota = ?
        AND u.kode_kecamatan = ?
        AND u.kode_kelurahan_desa = ?
        AND u.kode_pos = ?
    ORDER BY u.provinsi, u.kabupaten_kota, u.nama
"#;

#[derive(Debug, FromRow, Serialize)]
pub struct UnitSppg {
    id: u64,
    kode: String,
    nama: String,
    kode_provinsi: Option<String>,
    provinsi: String,
    kode_kabupaten_kota: Option<String>,
    kabupaten_kota: String,
    kode_kecamatan: Option<String>,
    kecamatan: String,
    kode_kelurahan_desa: Option<String>,
    kelurahan_desa: String,
    kode_pos: String,
    rt: String,
    rw: String,
    alamat_detail: String,
    nomor_telepon: Option<String>,
    aktif: bool,
    jumlah_sekolah: i64,
    id_admin: Option<u64>,
    nama_admin: Option<String>,
    email_admin: Option<String>,
    created_at: String,
    update_at: String,
}

#[derive(Debug, Deserialize)]
pub struct DataUnitSppg {
    nama: String,
    kode_provinsi: String,
    provinsi: String,
    kode_kabupaten_kota: String,
    kabupaten_kota: String,
    kode_kecamatan: String,
    kecamatan: String,
    kode_kelurahan_desa: String,
    kelurahan_desa: String,
    kode_pos: String,
    rt: String,
    rw: String,
    alamat_detail: String,
    nomor_telepon: Option<String>,
    aktif: Option<bool>,
    admin: Option<DataAdminBaru>,
}

#[derive(Debug, Deserialize)]
pub struct DataAdminBaru {
    nama: String,
    email: String,
    password: String,
}

#[derive(Debug, Deserialize)]
pub struct DataAdminUbah {
    nama: String,
    email: String,
    password: Option<String>,
}

#[derive(Debug, Default, Deserialize, Clone)]
pub struct FilterUnitSppg {
    kode_provinsi: Option<String>,
    kode_kabupaten_kota: Option<String>,
    kode_kecamatan: Option<String>,
    kode_kelurahan_desa: Option<String>,
    kode_pos: Option<String>,
}

#[derive(Debug, FromRow)]
struct WilayahTerpilih {
    provinsi: String,
    kabupaten_kota: String,
    kecamatan: String,
    kelurahan_desa: String,
    kode_pos: Option<String>,
}

#[derive(Debug, FromRow, Serialize)]
pub struct AdminUnit {
    id: u64,
    id_unit_sppg: u64,
    nama: String,
    email: String,
    peran: String,
    aktif: bool,
}

#[derive(Debug, Serialize)]
pub struct ResponsData<T> {
    sukses: bool,
    data: T,
}

#[derive(Debug, Serialize)]
pub struct ResponsDaftarUnitPublik {
    sukses: bool,
    data: Vec<UnitSppg>,
    meta: MetaDaftarUnitPublik,
}

#[derive(Debug, Serialize)]
pub struct MetaDaftarUnitPublik {
    ada_unit_nonaktif: bool,
}

#[derive(Debug, Serialize)]
pub struct ResponsPesan {
    sukses: bool,
    pesan: &'static str,
}

pub async fn daftar_publik(
    State(state): State<AppState>,
    Query(filter): Query<FilterUnitSppg>,
) -> Result<Json<ResponsDaftarUnitPublik>, ApiError> {
    let filter_status = filter.clone();
    let data = ambil_daftar_publik(&state, filter).await?;
    let ada_unit_nonaktif = data.is_empty() && unit_nonaktif_ada(&state, &filter_status).await?;
    Ok(Json(ResponsDaftarUnitPublik {
        sukses: true,
        data,
        meta: MetaDaftarUnitPublik { ada_unit_nonaktif },
    }))
}

pub async fn daftar_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsData<Vec<UnitSppg>>>, ApiError> {
    wajib_super_admin(&headers, &state)?;
    let data = ambil_daftar(&state, false).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn tambah(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(input): Json<DataUnitSppg>,
) -> Result<(StatusCode, Json<ResponsData<UnitSppg>>), ApiError> {
    wajib_super_admin(&headers, &state)?;
    let mut input = input.rapikan_dan_validasi()?;
    validasi_dan_lengkapi_wilayah(&state, &mut input).await?;
    let admin = input
        .admin
        .take()
        .ok_or_else(|| ApiError::permintaan_tidak_valid("Data akun admin SPPG wajib diisi"))?;
    let admin = admin.rapikan_dan_validasi()?;
    let hash_password = buat_hash_password(admin.password).await?;
    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;
    let kode_otomatis = buat_kode_sppg(&mut transaksi, &input.kode_kelurahan_desa).await?;

    let hasil = sqlx::query(
        r#"
        INSERT INTO unit_sppg (
            kode, nama, kode_provinsi, provinsi, kode_kabupaten_kota,
            kabupaten_kota, kode_kecamatan, kecamatan, kode_kelurahan_desa,
            kelurahan_desa, kode_pos, rt, rw, alamat_detail, nomor_telepon, aktif
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(&kode_otomatis)
    .bind(&input.nama)
    .bind(&input.kode_provinsi)
    .bind(&input.provinsi)
    .bind(&input.kode_kabupaten_kota)
    .bind(&input.kabupaten_kota)
    .bind(&input.kode_kecamatan)
    .bind(&input.kecamatan)
    .bind(&input.kode_kelurahan_desa)
    .bind(&input.kelurahan_desa)
    .bind(&input.kode_pos)
    .bind(&input.rt)
    .bind(&input.rw)
    .bind(&input.alamat_detail)
    .bind(&input.nomor_telepon)
    .bind(input.aktif.unwrap_or(true))
    .execute(&mut *transaksi)
    .await
    .map_err(|error| map_kesalahan_simpan(error, "Kode SPPG sudah digunakan"))?;

    let id_unit_sppg = hasil.last_insert_id();
    sqlx::query(
        r#"
        INSERT INTO admin (id_unit_sppg, nama, email, password, peran, aktif)
        VALUES (?, ?, ?, ?, 'admin_sppg', TRUE)
        "#,
    )
    .bind(id_unit_sppg)
    .bind(admin.nama)
    .bind(admin.email)
    .bind(hash_password)
    .execute(&mut *transaksi)
    .await
    .map_err(|error| {
        map_kesalahan_simpan(
            error,
            "Email admin sudah digunakan atau unit sudah memiliki admin",
        )
    })?;

    transaksi.commit().await.map_err(kesalahan_database)?;

    let data = ambil_satu(&state, id_unit_sppg).await?;
    Ok((
        StatusCode::CREATED,
        Json(ResponsData { sukses: true, data }),
    ))
}

pub async fn ubah(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
    Json(input): Json<DataUnitSppg>,
) -> Result<Json<ResponsData<UnitSppg>>, ApiError> {
    wajib_super_admin(&headers, &state)?;
    let mut input = input.rapikan_dan_validasi()?;
    validasi_dan_lengkapi_wilayah(&state, &mut input).await?;
    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;

    let hasil = sqlx::query(
        r#"
        UPDATE unit_sppg SET
            nama = ?, kode_provinsi = ?, provinsi = ?,
            kode_kabupaten_kota = ?, kabupaten_kota = ?, kode_kecamatan = ?,
            kecamatan = ?, kode_kelurahan_desa = ?, kelurahan_desa = ?,
            kode_pos = ?, rt = ?, rw = ?, alamat_detail = ?, nomor_telepon = ?,
            aktif = COALESCE(?, aktif)
        WHERE id = ?
        "#,
    )
    .bind(&input.nama)
    .bind(&input.kode_provinsi)
    .bind(&input.provinsi)
    .bind(&input.kode_kabupaten_kota)
    .bind(&input.kabupaten_kota)
    .bind(&input.kode_kecamatan)
    .bind(&input.kecamatan)
    .bind(&input.kode_kelurahan_desa)
    .bind(&input.kelurahan_desa)
    .bind(&input.kode_pos)
    .bind(&input.rt)
    .bind(&input.rw)
    .bind(&input.alamat_detail)
    .bind(&input.nomor_telepon)
    .bind(input.aktif)
    .bind(id)
    .execute(&mut *transaksi)
    .await
    .map_err(|error| map_kesalahan_simpan(error, "Kode SPPG sudah digunakan"))?;

    if hasil.rows_affected() == 0 {
        let ada = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM unit_sppg WHERE id = ?")
            .bind(id)
            .fetch_one(&mut *transaksi)
            .await
            .map_err(kesalahan_database)?
            > 0;
        if !ada {
            return Err(ApiError::tidak_ditemukan("Unit SPPG tidak ditemukan"));
        }
    }

    if let Some(aktif) = input.aktif {
        sqlx::query("UPDATE admin SET aktif = ? WHERE id_unit_sppg = ?")
            .bind(aktif)
            .bind(id)
            .execute(&mut *transaksi)
            .await
            .map_err(kesalahan_database)?;
    }

    transaksi.commit().await.map_err(kesalahan_database)?;
    let data = ambil_satu(&state, id).await?;
    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn nonaktifkan(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
) -> Result<Json<ResponsPesan>, ApiError> {
    wajib_super_admin(&headers, &state)?;
    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;
    let hasil = sqlx::query("UPDATE unit_sppg SET aktif = FALSE WHERE id = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;

    if hasil.rows_affected() == 0 {
        let ada = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM unit_sppg WHERE id = ?")
            .bind(id)
            .fetch_one(&mut *transaksi)
            .await
            .map_err(kesalahan_database)?
            > 0;
        if !ada {
            return Err(ApiError::tidak_ditemukan("Unit SPPG tidak ditemukan"));
        }
    }

    sqlx::query("UPDATE admin SET aktif = FALSE WHERE id_unit_sppg = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    transaksi.commit().await.map_err(kesalahan_database)?;

    Ok(Json(ResponsPesan {
        sukses: true,
        pesan: "Unit SPPG dan akun adminnya berhasil dinonaktifkan",
    }))
}

pub async fn hapus_permanen(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
) -> Result<Json<ResponsPesan>, ApiError> {
    wajib_super_admin(&headers, &state)?;
    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;

    let _nama_unit =
        sqlx::query_scalar::<_, String>("SELECT nama FROM unit_sppg WHERE id = ? FOR UPDATE")
            .bind(id)
            .fetch_optional(&mut *transaksi)
            .await
            .map_err(kesalahan_database)?
            .ok_or_else(|| ApiError::tidak_ditemukan("Unit SPPG tidak ditemukan"))?;

    let mut urls = sqlx::query_scalar::<_, String>(
        r#"
        SELECT ma.url_berkas
        FROM media_aduan ma
        INNER JOIN aduan a ON a.id = ma.id_aduan
        WHERE a.id_unit_sppg = ?
        "#,
    )
    .bind(id)
    .fetch_all(&mut *transaksi)
    .await
    .map_err(kesalahan_database)?;
    urls.extend(
        sqlx::query_scalar::<_, String>(
            r#"
            SELECT mm.url_berkas
            FROM media_menu mm
            INNER JOIN menu_harian m ON m.id = mm.id_menu_harian
            WHERE m.id_unit_sppg = ?
            "#,
        )
        .bind(id)
        .fetch_all(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?,
    );

    sqlx::query("DELETE FROM aduan WHERE id_unit_sppg = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    sqlx::query("DELETE FROM menu_harian WHERE id_unit_sppg = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    sqlx::query("DELETE FROM sekolah WHERE id_unit_sppg = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;

    sqlx::query("DELETE FROM admin WHERE id_unit_sppg = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    sqlx::query("DELETE FROM unit_sppg WHERE id = ?")
        .bind(id)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    transaksi.commit().await.map_err(kesalahan_database)?;

    for url in urls {
        if let Some(path) = path_dari_url(state.storage_path.as_ref(), &url) {
            hapus_berkas(&path).await;
        }
    }

    Ok(Json(ResponsPesan {
        sukses: true,
        pesan: "Unit SPPG beserta seluruh datanya berhasil dihapus permanen",
    }))
}

pub async fn buat_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
    Json(input): Json<DataAdminBaru>,
) -> Result<(StatusCode, Json<ResponsData<AdminUnit>>), ApiError> {
    wajib_super_admin(&headers, &state)?;
    let input = input.rapikan_dan_validasi()?;

    let unit_aktif =
        sqlx::query_scalar::<_, bool>("SELECT aktif FROM unit_sppg WHERE id = ? LIMIT 1")
            .bind(id)
            .fetch_optional(&state.database)
            .await
            .map_err(kesalahan_database)?
            .ok_or_else(|| ApiError::tidak_ditemukan("Unit SPPG tidak ditemukan"))?;

    if !unit_aktif {
        return Err(ApiError::konflik(
            "Admin tidak dapat dibuat untuk unit SPPG nonaktif",
        ));
    }

    let hash_password = buat_hash_password(input.password).await?;
    let hasil = sqlx::query(
        r#"
        INSERT INTO admin (id_unit_sppg, nama, email, password, peran, aktif)
        VALUES (?, ?, ?, ?, 'admin_sppg', TRUE)
        "#,
    )
    .bind(id)
    .bind(input.nama)
    .bind(input.email)
    .bind(hash_password)
    .execute(&state.database)
    .await
    .map_err(|error| {
        map_kesalahan_simpan(
            error,
            "Unit SPPG sudah memiliki admin atau email sudah digunakan",
        )
    })?;

    let data = sqlx::query_as::<_, AdminUnit>(
        "SELECT id, id_unit_sppg, nama, email, peran, aktif FROM admin WHERE id = ?",
    )
    .bind(hasil.last_insert_id())
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)?;

    Ok((
        StatusCode::CREATED,
        Json(ResponsData { sukses: true, data }),
    ))
}

pub async fn ubah_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
    Json(input): Json<DataAdminUbah>,
) -> Result<Json<ResponsData<AdminUnit>>, ApiError> {
    wajib_super_admin(&headers, &state)?;
    let input = input.rapikan_dan_validasi()?;

    if let Some(password) = input.password {
        let hash_password = buat_hash_password(password).await?;
        sqlx::query(
            r#"
            UPDATE admin
            SET nama = ?, email = ?, password = ?
            WHERE id_unit_sppg = ? AND peran = 'admin_sppg'
            "#,
        )
        .bind(&input.nama)
        .bind(&input.email)
        .bind(hash_password)
        .bind(id)
        .execute(&state.database)
        .await
        .map_err(|error| map_kesalahan_simpan(error, "Email admin sudah digunakan"))?;
    } else {
        sqlx::query(
            r#"
            UPDATE admin
            SET nama = ?, email = ?
            WHERE id_unit_sppg = ? AND peran = 'admin_sppg'
            "#,
        )
        .bind(&input.nama)
        .bind(&input.email)
        .bind(id)
        .execute(&state.database)
        .await
        .map_err(|error| map_kesalahan_simpan(error, "Email admin sudah digunakan"))?;
    }

    let data = sqlx::query_as::<_, AdminUnit>(
        r#"
        SELECT id, id_unit_sppg, nama, email, peran, aktif
        FROM admin
        WHERE id_unit_sppg = ? AND peran = 'admin_sppg'
        LIMIT 1
        "#,
    )
    .bind(id)
    .fetch_optional(&state.database)
    .await
    .map_err(kesalahan_database)?
    .ok_or_else(|| ApiError::tidak_ditemukan("Akun admin unit belum dibuat"))?;

    Ok(Json(ResponsData { sukses: true, data }))
}

pub async fn reset_password_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(id): Path<u64>,
) -> Result<Json<ResponsPesan>, ApiError> {
    wajib_super_admin(&headers, &state)?;

    let hash_password = buat_hash_password(PASSWORD_DEFAULT_ADMIN.to_owned()).await?;
    let hasil = sqlx::query(
        r#"
        UPDATE admin
        SET password = ?
        WHERE id_unit_sppg = ? AND peran = 'admin_sppg'
        "#,
    )
    .bind(hash_password)
    .bind(id)
    .execute(&state.database)
    .await
    .map_err(kesalahan_database)?;

    if hasil.rows_affected() == 0 {
        return Err(ApiError::tidak_ditemukan("Akun admin unit belum dibuat"));
    }

    Ok(Json(ResponsPesan {
        sukses: true,
        pesan: "Password admin unit berhasil direset ke password default",
    }))
}

async fn ambil_daftar(state: &AppState, hanya_aktif: bool) -> Result<Vec<UnitSppg>, ApiError> {
    sqlx::query_as::<_, UnitSppg>(PILIH_UNIT_SPPG)
        .bind(hanya_aktif)
        .fetch_all(&state.database)
        .await
        .map_err(kesalahan_database)
}

async fn ambil_daftar_publik(
    state: &AppState,
    filter: FilterUnitSppg,
) -> Result<Vec<UnitSppg>, ApiError> {
    let (
        Some(kode_provinsi),
        Some(kode_kabupaten_kota),
        Some(kode_kecamatan),
        Some(kode_kelurahan_desa),
        Some(kode_pos),
    ) = (
        filter.kode_provinsi,
        filter.kode_kabupaten_kota,
        filter.kode_kecamatan,
        filter.kode_kelurahan_desa,
        filter.kode_pos,
    )
    else {
        return ambil_daftar(state, true).await;
    };

    sqlx::query_as::<_, UnitSppg>(PILIH_UNIT_SPPG_PUBLIK)
        .bind(kode_provinsi)
        .bind(kode_kabupaten_kota)
        .bind(kode_kecamatan)
        .bind(kode_kelurahan_desa)
        .bind(kode_pos)
        .fetch_all(&state.database)
        .await
        .map_err(kesalahan_database)
}

async fn unit_nonaktif_ada(state: &AppState, filter: &FilterUnitSppg) -> Result<bool, ApiError> {
    let (
        Some(kode_provinsi),
        Some(kode_kabupaten_kota),
        Some(kode_kecamatan),
        Some(kode_kelurahan_desa),
        Some(kode_pos),
    ) = (
        filter.kode_provinsi.as_deref(),
        filter.kode_kabupaten_kota.as_deref(),
        filter.kode_kecamatan.as_deref(),
        filter.kode_kelurahan_desa.as_deref(),
        filter.kode_pos.as_deref(),
    )
    else {
        return Ok(false);
    };

    sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1
            FROM unit_sppg
            WHERE aktif = FALSE
              AND kode_provinsi = ?
              AND kode_kabupaten_kota = ?
              AND kode_kecamatan = ?
              AND kode_kelurahan_desa = ?
              AND kode_pos = ?
        )
        "#,
    )
    .bind(kode_provinsi)
    .bind(kode_kabupaten_kota)
    .bind(kode_kecamatan)
    .bind(kode_kelurahan_desa)
    .bind(kode_pos)
    .fetch_one(&state.database)
    .await
    .map_err(kesalahan_database)
}

async fn ambil_satu(state: &AppState, id: u64) -> Result<UnitSppg, ApiError> {
    sqlx::query_as::<_, UnitSppg>(PILIH_SATU_UNIT_SPPG)
        .bind(id)
        .fetch_optional(&state.database)
        .await
        .map_err(kesalahan_database)?
        .ok_or_else(|| ApiError::tidak_ditemukan("Unit SPPG tidak ditemukan"))
}

fn wajib_super_admin(headers: &HeaderMap, state: &AppState) -> Result<(), ApiError> {
    let klaim = validasi_token(headers, state)?;
    if klaim.peran != "super_admin" {
        return Err(ApiError::akses_ditolak(
            "Fitur ini hanya dapat digunakan oleh Super Admin",
        ));
    }
    Ok(())
}

async fn buat_hash_password(password: String) -> Result<String, ApiError> {
    tokio::task::spawn_blocking(move || {
        let salt = SaltString::generate(&mut OsRng);
        Argon2::default()
            .hash_password(password.as_bytes(), &salt)
            .map(|hash| hash.to_string())
    })
    .await
    .map_err(|error| {
        tracing::error!(%error, "Proses pembuatan hash password gagal dijalankan");
        ApiError::kesalahan_internal()
    })?
    .map_err(|error| {
        tracing::error!(%error, "Pembuatan hash password gagal");
        ApiError::kesalahan_internal()
    })
}

impl DataUnitSppg {
    fn rapikan_dan_validasi(mut self) -> Result<Self, ApiError> {
        self.nama = self.nama.trim().to_owned();
        self.kode_provinsi = self.kode_provinsi.trim().to_owned();
        self.provinsi = self.provinsi.trim().to_owned();
        self.kode_kabupaten_kota = self.kode_kabupaten_kota.trim().to_owned();
        self.kabupaten_kota = self.kabupaten_kota.trim().to_owned();
        self.kode_kecamatan = self.kode_kecamatan.trim().to_owned();
        self.kecamatan = self.kecamatan.trim().to_owned();
        self.kode_kelurahan_desa = self.kode_kelurahan_desa.trim().to_owned();
        self.kelurahan_desa = self.kelurahan_desa.trim().to_owned();
        self.kode_pos = self.kode_pos.trim().to_owned();
        self.rt = self.rt.trim().to_owned();
        self.rw = self.rw.trim().to_owned();
        self.alamat_detail = self.alamat_detail.trim().to_owned();
        self.nomor_telepon = self
            .nomor_telepon
            .map(|nomor| nomor.trim().to_owned())
            .filter(|nomor| !nomor.is_empty());

        let wajib = [
            &self.nama,
            &self.kode_provinsi,
            &self.provinsi,
            &self.kode_kabupaten_kota,
            &self.kabupaten_kota,
            &self.kode_kecamatan,
            &self.kecamatan,
            &self.kode_kelurahan_desa,
            &self.kelurahan_desa,
            &self.kode_pos,
            &self.rt,
            &self.rw,
            &self.alamat_detail,
        ];
        if wajib.iter().any(|nilai| nilai.is_empty()) {
            return Err(ApiError::permintaan_tidak_valid(
                "Seluruh data alamat wajib diisi",
            ));
        }
        validasi_kode_pos_rt_rw(&self.kode_pos, &self.rt, &self.rw)?;
        Ok(self)
    }
}

async fn buat_kode_sppg(
    transaksi: &mut Transaction<'_, MySql>,
    kode_kelurahan_desa: &str,
) -> Result<String, ApiError> {
    sqlx::query(
        r#"
        INSERT INTO urutan_kode_sppg (kode_kelurahan_desa, nomor_terakhir)
        VALUES (?, 1)
        ON DUPLICATE KEY UPDATE nomor_terakhir = nomor_terakhir + 1
        "#,
    )
    .bind(kode_kelurahan_desa)
    .execute(&mut **transaksi)
    .await
    .map_err(kesalahan_database)?;

    let nomor = sqlx::query_scalar::<_, u32>(
        "SELECT nomor_terakhir FROM urutan_kode_sppg WHERE kode_kelurahan_desa = ?",
    )
    .bind(kode_kelurahan_desa)
    .fetch_one(&mut **transaksi)
    .await
    .map_err(kesalahan_database)?;

    Ok(format_kode_sppg(kode_kelurahan_desa, nomor))
}

fn format_kode_sppg(kode_kelurahan_desa: &str, nomor: u32) -> String {
    let kode_wilayah = kode_kelurahan_desa.replace('.', "");
    format!("SPPG-{kode_wilayah}-{nomor:03}")
}

async fn validasi_dan_lengkapi_wilayah(
    state: &AppState,
    input: &mut DataUnitSppg,
) -> Result<(), ApiError> {
    let wilayah = sqlx::query_as::<_, WilayahTerpilih>(
        r#"
        SELECT
            provinsi.nama AS provinsi,
            kabupaten.nama AS kabupaten_kota,
            kecamatan.nama AS kecamatan,
            kelurahan.nama AS kelurahan_desa,
            kelurahan.kode_pos
        FROM referensi_wilayah provinsi
        INNER JOIN referensi_wilayah kabupaten
            ON kabupaten.kode = ? AND kabupaten.kode_induk = provinsi.kode
        INNER JOIN referensi_wilayah kecamatan
            ON kecamatan.kode = ? AND kecamatan.kode_induk = kabupaten.kode
        INNER JOIN referensi_wilayah kelurahan
            ON kelurahan.kode = ? AND kelurahan.kode_induk = kecamatan.kode
        WHERE provinsi.kode = ?
        LIMIT 1
        "#,
    )
    .bind(&input.kode_kabupaten_kota)
    .bind(&input.kode_kecamatan)
    .bind(&input.kode_kelurahan_desa)
    .bind(&input.kode_provinsi)
    .fetch_optional(&state.database)
    .await
    .map_err(kesalahan_database)?
    .ok_or_else(|| {
        ApiError::permintaan_tidak_valid(
            "Urutan provinsi, kabupaten/kota, kecamatan, dan kelurahan/desa tidak sesuai",
        )
    })?;

    if wilayah.kode_pos.as_deref() != Some(input.kode_pos.as_str()) {
        return Err(ApiError::permintaan_tidak_valid(
            "Kode pos tidak sesuai dengan kelurahan atau desa yang dipilih",
        ));
    }

    input.provinsi = wilayah.provinsi;
    input.kabupaten_kota = wilayah.kabupaten_kota;
    input.kecamatan = wilayah.kecamatan;
    input.kelurahan_desa = wilayah.kelurahan_desa;
    Ok(())
}

impl DataAdminBaru {
    fn rapikan_dan_validasi(mut self) -> Result<Self, ApiError> {
        self.nama = self.nama.trim().to_owned();
        self.email = self.email.trim().to_lowercase();
        if self.nama.is_empty() || !self.email.contains('@') || self.password.len() < 8 {
            return Err(ApiError::permintaan_tidak_valid(
                "Nama, email valid, dan password minimal 8 karakter wajib diisi",
            ));
        }
        Ok(self)
    }
}

impl DataAdminUbah {
    fn rapikan_dan_validasi(mut self) -> Result<Self, ApiError> {
        self.nama = self.nama.trim().to_owned();
        self.email = self.email.trim().to_lowercase();
        self.password = self
            .password
            .map(|password| password.trim().to_owned())
            .filter(|password| !password.is_empty());
        if self.nama.is_empty() || !self.email.contains('@') {
            return Err(ApiError::permintaan_tidak_valid(
                "Nama dan email admin yang valid wajib diisi",
            ));
        }
        if self
            .password
            .as_ref()
            .is_some_and(|password| password.len() < 8)
        {
            return Err(ApiError::permintaan_tidak_valid(
                "Password baru minimal 8 karakter",
            ));
        }
        Ok(self)
    }
}

pub(super) fn validasi_kode_pos_rt_rw(kode_pos: &str, rt: &str, rw: &str) -> Result<(), ApiError> {
    if kode_pos.len() != 5 || !kode_pos.chars().all(|karakter| karakter.is_ascii_digit()) {
        return Err(ApiError::permintaan_tidak_valid(
            "Kode pos harus terdiri dari 5 angka",
        ));
    }
    validasi_rt_rw(rt, rw)
}

pub(super) fn validasi_rt_rw(rt: &str, rw: &str) -> Result<(), ApiError> {
    if [rt, rw].iter().any(|nilai| {
        nilai.is_empty()
            || nilai.len() > 3
            || !nilai.chars().all(|karakter| karakter.is_ascii_digit())
    }) {
        return Err(ApiError::permintaan_tidak_valid(
            "RT dan RW harus terdiri dari 1 sampai 3 angka",
        ));
    }
    Ok(())
}

fn map_kesalahan_simpan(error: sqlx::Error, pesan_konflik: &str) -> ApiError {
    if error
        .as_database_error()
        .is_some_and(|database_error| database_error.is_unique_violation())
    {
        return ApiError::konflik(pesan_konflik);
    }
    kesalahan_database(error)
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Operasi database unit SPPG gagal");
    ApiError::kesalahan_internal()
}

#[cfg(test)]
mod tests {
    use super::format_kode_sppg;

    #[test]
    fn kode_sppg_memakai_kode_kelurahan_dan_nomor_urut() {
        assert_eq!(format_kode_sppg("32.76.05.1001", 7), "SPPG-3276051001-007");
    }
}
