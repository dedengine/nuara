mod aduan;
mod autentikasi;
mod events;
mod katalog_menu;
mod kesehatan;
mod media_menu;
mod menu;
mod otorisasi;
mod sekolah;
mod smart_dinner;
mod unit_sppg;
mod upload;
mod wilayah;

use axum::{
    Router,
    routing::{get, post},
};

use crate::{error::ApiError, state::AppState};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(kesehatan::informasi_layanan))
        .route("/api/kesehatan", get(kesehatan::periksa_kesehatan))
        .route("/api/admin/masuk", post(autentikasi::masuk))
        .route("/api/admin/keluar", post(autentikasi::keluar))
        .route("/api/admin/events/tiket", post(events::buat_tiket))
        .route("/api/admin/events", get(events::stream))
        .route(
            "/api/admin/profil",
            get(autentikasi::profil).put(autentikasi::ubah_profil_super_admin),
        )
        .route(
            "/api/admin/password",
            axum::routing::put(autentikasi::ubah_password),
        )
        .route("/api/wilayah/provinsi", get(wilayah::daftar_provinsi))
        .route(
            "/api/wilayah/kabupaten-kota/{kode_provinsi}",
            get(wilayah::daftar_kabupaten_kota),
        )
        .route(
            "/api/wilayah/kecamatan/{kode_kabupaten_kota}",
            get(wilayah::daftar_kecamatan),
        )
        .route(
            "/api/wilayah/kelurahan-desa/{kode_kecamatan}",
            get(wilayah::daftar_kelurahan_desa),
        )
        .route(
            "/api/wilayah/kode-pos/{kode_kelurahan_desa}",
            get(wilayah::daftar_kode_pos),
        )
        .route("/api/unit-sppg", get(unit_sppg::daftar_publik))
        .route("/api/unit-sppg/{id}/sekolah", get(sekolah::daftar_publik))
        .route(
            "/api/super-admin/unit-sppg",
            get(unit_sppg::daftar_admin).post(unit_sppg::tambah),
        )
        .route(
            "/api/super-admin/unit-sppg/{id}",
            axum::routing::put(unit_sppg::ubah).delete(unit_sppg::nonaktifkan),
        )
        .route(
            "/api/super-admin/unit-sppg/{id}/permanen",
            axum::routing::delete(unit_sppg::hapus_permanen),
        )
        .route(
            "/api/super-admin/unit-sppg/{id}/admin",
            post(unit_sppg::buat_admin).put(unit_sppg::ubah_admin),
        )
        .route(
            "/api/super-admin/unit-sppg/{id}/admin/reset-password",
            post(unit_sppg::reset_password_admin),
        )
        .route(
            "/api/admin/sekolah",
            get(sekolah::daftar_admin).post(sekolah::tambah),
        )
        .route(
            "/api/admin/sekolah/{id}",
            axum::routing::put(sekolah::ubah).delete(sekolah::nonaktifkan),
        )
        .route(
            "/api/admin/menu-harian",
            get(menu::daftar_admin).post(menu::tambah),
        )
        .route(
            "/api/admin/katalog-menu",
            get(katalog_menu::daftar).post(katalog_menu::tambah_template),
        )
        .route(
            "/api/admin/menu-harian/{id}",
            axum::routing::put(menu::ubah).delete(menu::nonaktifkan),
        )
        .route(
            "/api/admin/menu-harian/{id}/permanen",
            axum::routing::delete(menu::hapus_permanen),
        )
        .route(
            "/api/admin/menu-harian/{id}/media",
            post(media_menu::unggah),
        )
        .route(
            "/api/admin/media-menu/{id}",
            axum::routing::delete(media_menu::hapus),
        )
        .route("/api/mobile/menu-harian", get(menu::menu_publik))
        .route("/api/mobile/status-pilihan", get(sekolah::status_pilihan))
        .route("/api/mobile/menu-harian/riwayat", get(menu::riwayat_publik))
        .route("/api/mobile/aduan", post(aduan::kirim))
        .route("/api/admin/aduan", get(aduan::daftar_admin))
        .route("/api/admin/aduan/statistik", get(aduan::statistik))
        .route(
            "/api/admin/aduan/{id}/status",
            axum::routing::put(aduan::ubah_status),
        )
        .route(
            "/api/mobile/rekomendasi-makan-malam",
            get(smart_dinner::rekomendasi),
        )
}

pub async fn tidak_ditemukan() -> ApiError {
    ApiError::route_tidak_ditemukan()
}
