use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use http_body_util::BodyExt;
use sqlx::mysql::MySqlPoolOptions;
use std::path::PathBuf;
use tower::ServiceExt;

fn router_tanpa_koneksi_aktif() -> axum::Router {
    let pool = MySqlPoolOptions::new()
        .connect_lazy("mysql://nuara_test:nuara_test@127.0.0.1:3306/nuara_test")
        .expect("URL database pengujian harus valid");

    nuara_api::buat_router(
        pool,
        "kunci-pengujian-minimal-tiga-puluh-dua-karakter".to_owned(),
        PathBuf::from("storage/test-uploads"),
    )
}

#[tokio::test]
async fn root_mengembalikan_informasi_layanan() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(Request::get("/").body(Body::empty()).unwrap())
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert_eq!(json["nama"], "Nuara API");
    assert_eq!(json["versi"], env!("CARGO_PKG_VERSION"));
}

#[tokio::test]
async fn route_tidak_ada_mengembalikan_json_404() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::get("/api/route-tidak-ada")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::NOT_FOUND);

    let body = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert_eq!(json["sukses"], false);
    assert_eq!(json["error"]["kode"], "ROUTE_TIDAK_DITEMUKAN");
}

#[tokio::test]
async fn profil_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::get("/api/admin/profil")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    let body = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert_eq!(json["error"]["kode"], "TIDAK_TERAUTENTIKASI");
}

#[tokio::test]
async fn ubah_profil_super_admin_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::put("/api/admin/profil")
                .header("content-type", "application/json")
                .body(Body::from(
                    r#"{"nama":"Super Admin","email":"super@nuara.test"}"#,
                ))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn manajemen_sppg_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::get("/api/super-admin/unit-sppg")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn reset_password_admin_sppg_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::post("/api/super-admin/unit-sppg/1/admin/reset-password")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn manajemen_sekolah_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::get("/api/admin/sekolah")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn manajemen_menu_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::get("/api/admin/menu-harian")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn complaint_center_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::get("/api/admin/aduan")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn tiket_event_aduan_tanpa_token_ditolak() {
    let response = router_tanpa_koneksi_aktif()
        .oneshot(
            Request::post("/api/admin/events/tiket")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}
