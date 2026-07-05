use std::{convert::Infallible, time::Duration};

use axum::{
    Json,
    extract::{Query, State},
    http::HeaderMap,
    response::sse::{Event, KeepAlive, Sse},
};
use serde::{Deserialize, Serialize};
use tokio::sync::broadcast::error::RecvError;
use tokio_stream::Stream;

use super::otorisasi::wajib_admin_sppg_aktif;
use crate::{error::ApiError, state::AppState};

#[derive(Deserialize)]
pub struct ParameterTiket {
    tiket: String,
}

#[derive(Serialize)]
pub struct DataTiket {
    tiket: String,
    berlaku_detik: u64,
}

#[derive(Serialize)]
pub struct ResponsData<T> {
    sukses: bool,
    data: T,
}

pub async fn buat_tiket(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsData<DataTiket>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let tiket = state.buat_tiket_event(id_unit_sppg).await;

    Ok(Json(ResponsData {
        sukses: true,
        data: DataTiket {
            tiket,
            berlaku_detik: 12 * 60 * 60,
        },
    }))
}

pub async fn stream(
    State(state): State<AppState>,
    Query(parameter): Query<ParameterTiket>,
) -> Result<Sse<impl Stream<Item = Result<Event, Infallible>>>, ApiError> {
    let id_unit_sppg = state
        .unit_dari_tiket_event(parameter.tiket.trim())
        .await
        .ok_or_else(|| {
            ApiError::tidak_terautentikasi("Tiket event tidak valid atau kedaluwarsa")
        })?;
    let mut penerima = state.berlangganan_event_aduan();

    let aliran = async_stream::stream! {
        loop {
            match penerima.recv().await {
                Ok(event) if event.id_unit_sppg == id_unit_sppg => {
                    let data = serde_json::to_string(&event)
                        .unwrap_or_else(|_| "{}".to_owned());
                    yield Ok(Event::default().data(data));
                }
                Ok(_) | Err(RecvError::Lagged(_)) => continue,
                Err(RecvError::Closed) => break,
            }
        }
    };

    Ok(Sse::new(aliran).keep_alive(
        KeepAlive::new()
            .interval(Duration::from_secs(15))
            .text("nuara-terhubung"),
    ))
}
