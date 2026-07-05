use std::{env, net::SocketAddr, path::PathBuf};

use thiserror::Error;

#[derive(Debug, Clone)]
pub struct Konfigurasi {
    pub database_url: String,
    pub jwt_secret: String,
    pub storage_path: PathBuf,
    host: String,
    port: u16,
}

#[derive(Debug, Error)]
pub enum KesalahanKonfigurasi {
    #[error("Environment variable {0} belum diatur")]
    TidakDitemukan(&'static str),
    #[error("PORT harus berupa angka antara 1 dan 65535")]
    PortTidakValid,
    #[error("HOST dan PORT tidak membentuk alamat server yang valid: {0}")]
    AlamatTidakValid(String),
    #[error("JWT_SECRET minimal harus terdiri dari 32 karakter")]
    JwtSecretTerlaluPendek,
}

impl Konfigurasi {
    pub fn dari_environment() -> Result<Self, KesalahanKonfigurasi> {
        let database_url = env::var("DATABASE_URL")
            .map_err(|_| KesalahanKonfigurasi::TidakDitemukan("DATABASE_URL"))?;
        let jwt_secret = env::var("JWT_SECRET")
            .map_err(|_| KesalahanKonfigurasi::TidakDitemukan("JWT_SECRET"))?;
        if jwt_secret.len() < 32 {
            return Err(KesalahanKonfigurasi::JwtSecretTerlaluPendek);
        }
        let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_owned());
        let storage_path = env::var("STORAGE_PATH")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("storage/uploads"));
        let port = env::var("PORT")
            .unwrap_or_else(|_| "8080".to_owned())
            .parse()
            .map_err(|_| KesalahanKonfigurasi::PortTidakValid)?;

        Ok(Self {
            database_url,
            jwt_secret,
            storage_path,
            host,
            port,
        })
    }

    pub fn alamat_server(&self) -> Result<SocketAddr, KesalahanKonfigurasi> {
        let alamat = format!("{}:{}", self.host, self.port);
        alamat
            .parse()
            .map_err(|_| KesalahanKonfigurasi::AlamatTidakValid(alamat))
    }
}
