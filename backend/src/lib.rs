mod config;
mod error;
mod routes;
mod state;

use std::time::Duration;

use anyhow::Context;
use axum::Router;
use sqlx::{MySqlPool, mysql::MySqlPoolOptions};
use tokio::{net::TcpListener, signal};
use tower_http::{
    cors::CorsLayer,
    services::ServeDir,
    trace::{DefaultMakeSpan, DefaultOnResponse, TraceLayer},
};
use tracing::Level;
use tracing_subscriber::EnvFilter;

use config::Konfigurasi;
use state::AppState;

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("./database/migrations");

pub async fn jalankan() -> anyhow::Result<()> {
    muat_environment();
    siapkan_logging();

    let konfigurasi = Konfigurasi::dari_environment()?;
    let pool = hubungkan_database(&konfigurasi.database_url).await?;

    MIGRATOR
        .run(&pool)
        .await
        .context("Gagal menjalankan migrasi database")?;

    tokio::fs::create_dir_all(&konfigurasi.storage_path)
        .await
        .context("Gagal menyiapkan folder penyimpanan media")?;
    let alamat = konfigurasi.alamat_server()?;
    let listener = TcpListener::bind(alamat)
        .await
        .with_context(|| format!("Gagal memakai alamat server {alamat}"))?;
    let app = buat_router(pool, konfigurasi.jwt_secret, konfigurasi.storage_path);

    tracing::info!(%alamat, "Backend Nuara siap menerima permintaan");

    axum::serve(listener, app)
        .with_graceful_shutdown(sinyal_berhenti())
        .await
        .context("Server HTTP berhenti secara tidak terduga")?;

    Ok(())
}

pub fn buat_router(
    database: MySqlPool,
    jwt_secret: String,
    storage_path: std::path::PathBuf,
) -> Router {
    let layanan_media = ServeDir::new(storage_path.clone());
    let state = AppState::baru(database, jwt_secret, storage_path);

    Router::new()
        .merge(routes::router())
        .nest_service("/media", layanan_media)
        .fallback(routes::tidak_ditemukan)
        .with_state(state)
        // Selama development, Flutter Web dapat memakai port localhost yang berubah-ubah.
        .layer(CorsLayer::permissive())
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::new().level(Level::INFO))
                .on_response(DefaultOnResponse::new().level(Level::INFO)),
        )
        .layer(axum::extract::DefaultBodyLimit::max(105 * 1024 * 1024))
}

async fn hubungkan_database(database_url: &str) -> anyhow::Result<MySqlPool> {
    MySqlPoolOptions::new()
        .max_connections(10)
        .min_connections(1)
        .acquire_timeout(Duration::from_secs(5))
        .connect(database_url)
        .await
        .context("Tidak dapat terhubung ke database MySQL")
}

fn muat_environment() {
    dotenvy::dotenv().ok();
}

fn siapkan_logging() {
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("nuara_api=debug,tower_http=info"));

    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_target(false)
        .compact()
        .init();
}

async fn sinyal_berhenti() {
    if let Err(error) = signal::ctrl_c().await {
        tracing::error!(%error, "Gagal menunggu sinyal berhenti");
    }
}
