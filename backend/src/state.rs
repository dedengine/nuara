use std::{
    collections::HashMap,
    path::PathBuf,
    sync::Arc,
    time::{Duration, Instant},
};

use serde::Serialize;
use sqlx::MySqlPool;
use tokio::sync::{Mutex, broadcast};

const MASA_BERLAKU_TIKET_EVENT: Duration = Duration::from_secs(12 * 60 * 60);

#[derive(Clone, Debug, Serialize)]
pub struct EventAduan {
    pub jenis: &'static str,
    pub id_unit_sppg: u64,
    pub id_aduan: u64,
}

#[derive(Clone, Copy)]
struct TiketEvent {
    id_unit_sppg: u64,
    kedaluwarsa: Instant,
}

#[derive(Clone)]
pub struct AppState {
    pub database: MySqlPool,
    pub jwt_secret: Arc<str>,
    pub storage_path: Arc<PathBuf>,
    event_aduan: broadcast::Sender<EventAduan>,
    tiket_event: Arc<Mutex<HashMap<String, TiketEvent>>>,
}

impl AppState {
    pub fn baru(database: MySqlPool, jwt_secret: String, storage_path: PathBuf) -> Self {
        let (event_aduan, _) = broadcast::channel(128);
        Self {
            database,
            jwt_secret: Arc::from(jwt_secret),
            storage_path: Arc::new(storage_path),
            event_aduan,
            tiket_event: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub async fn buat_tiket_event(&self, id_unit_sppg: u64) -> String {
        let sekarang = Instant::now();
        let mut daftar = self.tiket_event.lock().await;
        daftar.retain(|_, tiket| tiket.kedaluwarsa > sekarang);

        let tiket = uuid::Uuid::new_v4().to_string();
        daftar.insert(
            tiket.clone(),
            TiketEvent {
                id_unit_sppg,
                kedaluwarsa: sekarang + MASA_BERLAKU_TIKET_EVENT,
            },
        );
        tiket
    }

    pub async fn unit_dari_tiket_event(&self, tiket: &str) -> Option<u64> {
        let sekarang = Instant::now();
        let mut daftar = self.tiket_event.lock().await;
        daftar.retain(|_, data| data.kedaluwarsa > sekarang);
        daftar.get(tiket).map(|data| data.id_unit_sppg)
    }

    pub fn berlangganan_event_aduan(&self) -> broadcast::Receiver<EventAduan> {
        self.event_aduan.subscribe()
    }

    pub fn terbitkan_event_aduan(&self, event: EventAduan) {
        let _ = self.event_aduan.send(event);
    }
}
