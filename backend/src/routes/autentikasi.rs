use std::time::{SystemTime, UNIX_EPOCH};

use argon2::{
    Argon2,
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString, rand_core::OsRng},
};
use axum::{
    Json,
    extract::State,
    http::{HeaderMap, header::AUTHORIZATION},
};
use jsonwebtoken::{Algorithm, DecodingKey, EncodingKey, Header, Validation, decode, encode};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use crate::{error::ApiError, state::AppState};

const DURASI_TOKEN_DETIK: u64 = 8 * 60 * 60;

#[derive(Debug, Deserialize)]
pub struct PermintaanMasuk {
    email: String,
    password: String,
}

#[derive(Debug, FromRow)]
struct AdminLogin {
    id: u64,
    id_unit_sppg: Option<u64>,
    nama: String,
    email: String,
    hash_password: String,
    peran: String,
    aktif: bool,
    unit_aktif: Option<bool>,
}

#[derive(Debug, FromRow, Serialize)]
pub struct ProfilAdmin {
    id: u64,
    id_unit_sppg: Option<u64>,
    nama: String,
    email: String,
    peran: String,
}

#[derive(Debug, Serialize)]
pub struct ResponsMasuk {
    sukses: bool,
    data: DataMasuk,
}

#[derive(Debug, Serialize)]
struct DataMasuk {
    token_akses: String,
    tipe_token: &'static str,
    berlaku_selama_detik: u64,
    admin: ProfilAdmin,
}

#[derive(Debug, Serialize)]
pub struct ResponsProfil {
    sukses: bool,
    data: ProfilAdmin,
}

#[derive(Debug, Serialize)]
pub struct ResponsKeluar {
    sukses: bool,
    pesan: &'static str,
}

#[derive(Debug, Deserialize)]
pub struct PermintaanUbahPassword {
    password_lama: String,
    password_baru: String,
}

#[derive(Debug, Deserialize)]
pub struct PermintaanUbahProfil {
    nama: String,
    email: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub(super) struct KlaimToken {
    pub(super) sub: String,
    pub(super) peran: String,
    pub(super) id_unit_sppg: Option<u64>,
    iat: usize,
    exp: usize,
}

pub async fn masuk(
    State(state): State<AppState>,
    Json(permintaan): Json<PermintaanMasuk>,
) -> Result<Json<ResponsMasuk>, ApiError> {
    let email = permintaan.email.trim().to_lowercase();
    if email.is_empty() || permintaan.password.len() < 8 {
        return Err(ApiError::permintaan_tidak_valid(
            "Email dan password minimal 8 karakter wajib diisi",
        ));
    }

    let admin = sqlx::query_as::<_, AdminLogin>(
        r#"
        SELECT
            a.id, a.id_unit_sppg, a.nama, a.email,
            a.password AS hash_password, a.peran, a.aktif,
            u.aktif AS unit_aktif
        FROM admin a
        LEFT JOIN unit_sppg u ON u.id = a.id_unit_sppg
        WHERE a.email = ?
        LIMIT 1
        "#,
    )
    .bind(email)
    .fetch_optional(&state.database)
    .await
    .map_err(|error| {
        tracing::error!(%error, "Gagal mencari admin saat login");
        ApiError::kesalahan_internal()
    })?
    .ok_or_else(kredensial_tidak_valid)?;

    let password = permintaan.password;
    let hash_password = admin.hash_password.clone();
    let password_cocok = tokio::task::spawn_blocking(move || {
        let hash = PasswordHash::new(&hash_password).ok()?;
        Argon2::default()
            .verify_password(password.as_bytes(), &hash)
            .ok()
    })
    .await
    .map_err(|error| {
        tracing::error!(%error, "Proses verifikasi password gagal dijalankan");
        ApiError::kesalahan_internal()
    })?
    .is_some();

    if !password_cocok {
        return Err(kredensial_tidak_valid());
    }

    if admin.peran == "admin_sppg" && admin.unit_aktif != Some(true) {
        return Err(ApiError::akses_ditolak(
            "Unit SPPG sedang dinonaktifkan. Hubungi Super Admin Nuara.",
        ));
    }
    if !admin.aktif {
        return Err(ApiError::akses_ditolak(
            "Akun sedang dinonaktifkan. Hubungi Super Admin Nuara.",
        ));
    }

    let sekarang = waktu_unix()?;
    let klaim = KlaimToken {
        sub: admin.id.to_string(),
        peran: admin.peran.clone(),
        id_unit_sppg: admin.id_unit_sppg,
        iat: sekarang as usize,
        exp: (sekarang + DURASI_TOKEN_DETIK) as usize,
    };
    let token_akses = encode(
        &Header::new(Algorithm::HS256),
        &klaim,
        &EncodingKey::from_secret(state.jwt_secret.as_bytes()),
    )
    .map_err(|error| {
        tracing::error!(%error, "Gagal membuat token akses");
        ApiError::kesalahan_internal()
    })?;

    Ok(Json(ResponsMasuk {
        sukses: true,
        data: DataMasuk {
            token_akses,
            tipe_token: "Bearer",
            berlaku_selama_detik: DURASI_TOKEN_DETIK,
            admin: ProfilAdmin {
                id: admin.id,
                id_unit_sppg: admin.id_unit_sppg,
                nama: admin.nama,
                email: admin.email,
                peran: admin.peran,
            },
        },
    }))
}

pub async fn profil(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsProfil>, ApiError> {
    let klaim = validasi_token(&headers, &state)?;
    let id_admin = klaim.sub.parse::<u64>().map_err(|_| token_tidak_valid())?;

    let admin = sqlx::query_as::<_, ProfilAdmin>(
        r#"
        SELECT id, id_unit_sppg, nama, email, peran
        FROM admin
        WHERE id = ? AND aktif = TRUE
        LIMIT 1
        "#,
    )
    .bind(id_admin)
    .fetch_optional(&state.database)
    .await
    .map_err(|error| {
        tracing::error!(%error, "Gagal mengambil profil admin");
        ApiError::kesalahan_internal()
    })?
    .ok_or_else(token_tidak_valid)?;

    Ok(Json(ResponsProfil {
        sukses: true,
        data: admin,
    }))
}

pub async fn keluar(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsKeluar>, ApiError> {
    validasi_token(&headers, &state)?;

    Ok(Json(ResponsKeluar {
        sukses: true,
        pesan: "Berhasil keluar. Hapus token dari perangkat.",
    }))
}

pub async fn ubah_profil_super_admin(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(permintaan): Json<PermintaanUbahProfil>,
) -> Result<Json<ResponsProfil>, ApiError> {
    let klaim = validasi_token(&headers, &state)?;
    if klaim.peran != "super_admin" {
        return Err(ApiError::akses_ditolak(
            "Fitur ini hanya tersedia untuk Super Admin",
        ));
    }

    let nama = permintaan.nama.trim();
    let email = permintaan.email.trim().to_lowercase();
    if nama.chars().count() < 3 || nama.chars().count() > 150 {
        return Err(ApiError::permintaan_tidak_valid(
            "Nama harus terdiri dari 3 sampai 150 karakter",
        ));
    }
    if email.len() > 190 || !email.contains('@') || email.starts_with('@') {
        return Err(ApiError::permintaan_tidak_valid(
            "Email Super Admin tidak valid",
        ));
    }

    let id_admin = klaim.sub.parse::<u64>().map_err(|_| token_tidak_valid())?;
    sqlx::query(
        r#"
        UPDATE admin
        SET nama = ?, email = ?
        WHERE id = ? AND peran = 'super_admin' AND aktif = TRUE
        "#,
    )
    .bind(nama)
    .bind(&email)
    .bind(id_admin)
    .execute(&state.database)
    .await
    .map_err(|error| {
        if let sqlx::Error::Database(database_error) = &error
            && database_error.is_unique_violation()
        {
            return ApiError::konflik("Email sudah digunakan oleh akun lain");
        }
        tracing::error!(%error, "Gagal memperbarui profil Super Admin");
        ApiError::kesalahan_internal()
    })?;

    let admin = sqlx::query_as::<_, ProfilAdmin>(
        r#"
        SELECT id, id_unit_sppg, nama, email, peran
        FROM admin
        WHERE id = ? AND peran = 'super_admin' AND aktif = TRUE
        LIMIT 1
        "#,
    )
    .bind(id_admin)
    .fetch_optional(&state.database)
    .await
    .map_err(|error| {
        tracing::error!(%error, "Gagal mengambil profil Super Admin yang diperbarui");
        ApiError::kesalahan_internal()
    })?
    .ok_or_else(token_tidak_valid)?;

    Ok(Json(ResponsProfil {
        sukses: true,
        data: admin,
    }))
}

pub async fn ubah_password(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(permintaan): Json<PermintaanUbahPassword>,
) -> Result<Json<ResponsKeluar>, ApiError> {
    let klaim = validasi_token(&headers, &state)?;
    if klaim.peran != "admin_sppg" {
        return Err(ApiError::akses_ditolak(
            "Fitur ini hanya tersedia untuk Admin SPPG",
        ));
    }
    if permintaan.password_lama.len() < 8 || permintaan.password_baru.len() < 8 {
        return Err(ApiError::permintaan_tidak_valid(
            "Password lama dan password baru minimal 8 karakter",
        ));
    }
    if permintaan.password_lama == permintaan.password_baru {
        return Err(ApiError::permintaan_tidak_valid(
            "Password baru harus berbeda dari password lama",
        ));
    }

    let id_admin = klaim.sub.parse::<u64>().map_err(|_| token_tidak_valid())?;
    let hash_lama = sqlx::query_scalar::<_, String>(
        "SELECT password FROM admin WHERE id = ? AND peran = 'admin_sppg' AND aktif = TRUE",
    )
    .bind(id_admin)
    .fetch_optional(&state.database)
    .await
    .map_err(|error| {
        tracing::error!(%error, "Gagal mengambil password Admin SPPG");
        ApiError::kesalahan_internal()
    })?
    .ok_or_else(token_tidak_valid)?;

    if !verifikasi_password(permintaan.password_lama, hash_lama).await? {
        return Err(ApiError::tidak_terautentikasi("Password lama tidak sesuai"));
    }

    let hash_baru = buat_hash_password(permintaan.password_baru).await?;
    sqlx::query("UPDATE admin SET password = ? WHERE id = ?")
        .bind(hash_baru)
        .bind(id_admin)
        .execute(&state.database)
        .await
        .map_err(|error| {
            tracing::error!(%error, "Gagal memperbarui password Admin SPPG");
            ApiError::kesalahan_internal()
        })?;

    Ok(Json(ResponsKeluar {
        sukses: true,
        pesan: "Password berhasil diperbarui",
    }))
}

pub(super) fn validasi_token(
    headers: &HeaderMap,
    state: &AppState,
) -> Result<KlaimToken, ApiError> {
    let authorization = headers
        .get(AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .ok_or_else(token_tidak_valid)?;
    let token = authorization
        .strip_prefix("Bearer ")
        .filter(|token| !token.is_empty())
        .ok_or_else(token_tidak_valid)?;

    decode::<KlaimToken>(
        token,
        &DecodingKey::from_secret(state.jwt_secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )
    .map(|data| data.claims)
    .map_err(|_| token_tidak_valid())
}

fn waktu_unix() -> Result<u64, ApiError> {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|durasi| durasi.as_secs())
        .map_err(|error| {
            tracing::error!(%error, "Waktu sistem berada sebelum UNIX epoch");
            ApiError::kesalahan_internal()
        })
}

fn kredensial_tidak_valid() -> ApiError {
    ApiError::tidak_terautentikasi("Email atau password tidak sesuai")
}

async fn verifikasi_password(password: String, hash_password: String) -> Result<bool, ApiError> {
    tokio::task::spawn_blocking(move || {
        let hash = PasswordHash::new(&hash_password).ok()?;
        Argon2::default()
            .verify_password(password.as_bytes(), &hash)
            .ok()
    })
    .await
    .map_err(|error| {
        tracing::error!(%error, "Proses verifikasi password gagal dijalankan");
        ApiError::kesalahan_internal()
    })
    .map(|hasil| hasil.is_some())
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

fn token_tidak_valid() -> ApiError {
    ApiError::tidak_terautentikasi("Token akses tidak valid atau sudah kedaluwarsa")
}
