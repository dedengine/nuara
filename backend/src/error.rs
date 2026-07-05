use axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde::Serialize;

#[derive(Debug)]
pub struct ApiError {
    status: StatusCode,
    kode: &'static str,
    pesan: String,
}

#[derive(Debug, Serialize)]
struct ResponsError {
    sukses: bool,
    error: DetailError,
}

#[derive(Debug, Serialize)]
struct DetailError {
    kode: &'static str,
    pesan: String,
}

impl ApiError {
    pub fn permintaan_tidak_valid(pesan: impl Into<String>) -> Self {
        Self {
            status: StatusCode::BAD_REQUEST,
            kode: "PERMINTAAN_TIDAK_VALID",
            pesan: pesan.into(),
        }
    }

    pub fn tidak_terautentikasi(pesan: impl Into<String>) -> Self {
        Self {
            status: StatusCode::UNAUTHORIZED,
            kode: "TIDAK_TERAUTENTIKASI",
            pesan: pesan.into(),
        }
    }

    pub fn akses_ditolak(pesan: impl Into<String>) -> Self {
        Self {
            status: StatusCode::FORBIDDEN,
            kode: "AKSES_DITOLAK",
            pesan: pesan.into(),
        }
    }

    pub fn tidak_ditemukan(pesan: impl Into<String>) -> Self {
        Self {
            status: StatusCode::NOT_FOUND,
            kode: "DATA_TIDAK_DITEMUKAN",
            pesan: pesan.into(),
        }
    }

    pub fn konflik(pesan: impl Into<String>) -> Self {
        Self {
            status: StatusCode::CONFLICT,
            kode: "DATA_KONFLIK",
            pesan: pesan.into(),
        }
    }

    pub fn kesalahan_internal() -> Self {
        Self {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            kode: "KESALAHAN_INTERNAL",
            pesan: "Terjadi kesalahan pada server".to_owned(),
        }
    }

    pub fn layanan_tidak_tersedia(pesan: impl Into<String>) -> Self {
        Self {
            status: StatusCode::SERVICE_UNAVAILABLE,
            kode: "LAYANAN_TIDAK_TERSEDIA",
            pesan: pesan.into(),
        }
    }

    pub fn route_tidak_ditemukan() -> Self {
        Self {
            status: StatusCode::NOT_FOUND,
            kode: "ROUTE_TIDAK_DITEMUKAN",
            pesan: "Alamat API yang diminta tidak tersedia".to_owned(),
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let body = ResponsError {
            sukses: false,
            error: DetailError {
                kode: self.kode,
                pesan: self.pesan,
            },
        };

        (self.status, Json(body)).into_response()
    }
}
