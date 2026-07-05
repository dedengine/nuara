use axum::{
    Json,
    extract::{Query, State},
};
use chrono::{Local, NaiveDate};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use crate::{error::ApiError, state::AppState};

#[derive(Debug, Deserialize)]
pub struct FilterRekomendasi {
    id_sekolah: u64,
    tanggal: Option<String>,
}

#[derive(Debug, FromRow, Serialize)]
pub struct RingkasanMakanSiang {
    id_menu_harian: u64,
    nama_menu: String,
    tanggal_menu: String,
    jenjang: String,
    kalori: f64,
    protein: f64,
    lemak: f64,
    karbohidrat: f64,
}

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct RekomendasiDatabase {
    id: u64,
    nama_menu: String,
    deskripsi: String,
    fokus_nutrisi: String,
    kalori: f64,
    protein: f64,
    lemak: f64,
    karbohidrat: f64,
    serat: f64,
    sumber_data_gizi: String,
    url_sumber_data_gizi: String,
}

#[derive(Debug, Serialize)]
pub struct RekomendasiTerpilih {
    #[serde(flatten)]
    menu: RekomendasiDatabase,
    skor_kecocokan: f64,
}

#[derive(Debug, Serialize)]
pub struct NilaiNutrisi {
    kalori: f64,
    protein: f64,
    lemak: f64,
    karbohidrat: f64,
}

#[derive(Debug, Serialize)]
pub struct DataRekomendasi {
    makan_siang: RingkasanMakanSiang,
    target_hingga_makan_malam: NilaiNutrisi,
    kekurangan_setelah_makan_siang: NilaiNutrisi,
    rekomendasi: Vec<RekomendasiTerpilih>,
    sumber_target: &'static str,
    url_sumber_target: &'static str,
    catatan: &'static str,
}

#[derive(Debug, Serialize)]
pub struct ResponsData<T> {
    sukses: bool,
    data: T,
}

pub async fn rekomendasi(
    State(state): State<AppState>,
    Query(filter): Query<FilterRekomendasi>,
) -> Result<Json<ResponsData<DataRekomendasi>>, ApiError> {
    let tanggal = validasi_tanggal(filter.tanggal)?;
    let makan_siang = sqlx::query_as::<_, RingkasanMakanSiang>(
        r#"
        SELECT
            m.id AS id_menu_harian, m.nama_menu,
            DATE_FORMAT(m.tanggal_menu, '%Y-%m-%d') AS tanggal_menu,
            s.jenjang,
            CAST(m.kalori AS DOUBLE) AS kalori,
            CAST(m.protein AS DOUBLE) AS protein,
            CAST(m.lemak AS DOUBLE) AS lemak,
            CAST(m.karbohidrat AS DOUBLE) AS karbohidrat
        FROM menu_harian m
        INNER JOIN sekolah s ON s.id_unit_sppg = m.id_unit_sppg
        INNER JOIN unit_sppg u ON u.id = m.id_unit_sppg
        WHERE s.id = ? AND s.aktif = TRUE AND u.aktif = TRUE
          AND m.tanggal_menu = ? AND m.status = 'dipublikasikan' AND m.aktif = TRUE
          AND (m.id_sekolah = s.id OR m.id_sekolah IS NULL)
        ORDER BY (m.id_sekolah IS NOT NULL) DESC
        LIMIT 1
        "#,
    )
    .bind(filter.id_sekolah)
    .bind(tanggal)
    .fetch_optional(&state.database)
    .await
    .map_err(kesalahan_database)?
    .ok_or_else(|| ApiError::tidak_ditemukan("Menu makan siang tidak ditemukan"))?;

    let target = target_jenjang(&makan_siang.jenjang);
    let kekurangan = NilaiNutrisi {
        kalori: (target.kalori - makan_siang.kalori).max(0.0),
        protein: (target.protein - makan_siang.protein).max(0.0),
        lemak: (target.lemak - makan_siang.lemak).max(0.0),
        karbohidrat: (target.karbohidrat - makan_siang.karbohidrat).max(0.0),
    };
    let daftar = sqlx::query_as::<_, RekomendasiDatabase>(
        r#"
        SELECT id, nama_menu, deskripsi, fokus_nutrisi,
               CAST(kalori AS DOUBLE) AS kalori,
               CAST(protein AS DOUBLE) AS protein,
               CAST(lemak AS DOUBLE) AS lemak,
               CAST(karbohidrat AS DOUBLE) AS karbohidrat,
               CAST(serat AS DOUBLE) AS serat,
               sumber_data_gizi, url_sumber_data_gizi
        FROM rekomendasi_makan_malam WHERE aktif = TRUE
        "#,
    )
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;

    let mut rekomendasi: Vec<_> = daftar
        .into_iter()
        .map(|menu| RekomendasiTerpilih {
            skor_kecocokan: hitung_skor(&menu, &kekurangan, &target),
            menu,
        })
        .collect();
    rekomendasi.sort_by(|a, b| b.skor_kecocokan.total_cmp(&a.skor_kecocokan));
    rekomendasi.truncate(3);

    Ok(Json(ResponsData {
        sukses: true,
        data: DataRekomendasi {
            makan_siang,
            target_hingga_makan_malam: target,
            kekurangan_setelah_makan_siang: kekurangan,
            rekomendasi,
            sumber_target: "Permenkes Nomor 28 Tahun 2019 tentang AKG",
            url_sumber_target: "https://peraturan.bpk.go.id/Details/138621/permenkes-no-28-tahun-2019",
            catatan: "Rekomendasi bersifat umum berdasarkan jenjang sekolah dan bukan diagnosis medis.",
        },
    }))
}

fn target_jenjang(jenjang: &str) -> NilaiNutrisi {
    match jenjang {
        "SMP" => NilaiNutrisi {
            kalori: 1450.0,
            protein: 50.0,
            lemak: 50.0,
            karbohidrat: 215.0,
        },
        "SMA" | "SMK" => NilaiNutrisi {
            kalori: 1600.0,
            protein: 60.0,
            lemak: 55.0,
            karbohidrat: 235.0,
        },
        _ => NilaiNutrisi {
            kalori: 1200.0,
            protein: 40.0,
            lemak: 40.0,
            karbohidrat: 180.0,
        },
    }
}

fn hitung_skor(
    menu: &RekomendasiDatabase,
    kekurangan: &NilaiNutrisi,
    target: &NilaiNutrisi,
) -> f64 {
    let skor = kedekatan(menu.kalori, kekurangan.kalori, target.kalori) * 0.30
        + kedekatan(menu.protein, kekurangan.protein, target.protein) * 0.30
        + kedekatan(menu.lemak, kekurangan.lemak, target.lemak) * 0.15
        + kedekatan(menu.karbohidrat, kekurangan.karbohidrat, target.karbohidrat) * 0.25;
    (skor * 1000.0).round() / 10.0
}

fn kedekatan(nilai: f64, kekurangan: f64, target: f64) -> f64 {
    (1.0 - ((nilai - kekurangan).abs() / target.max(1.0))).clamp(0.0, 1.0)
}

fn validasi_tanggal(tanggal: Option<String>) -> Result<String, ApiError> {
    let tanggal = tanggal.unwrap_or_else(|| Local::now().date_naive().to_string());
    NaiveDate::parse_from_str(tanggal.trim(), "%Y-%m-%d")
        .map(|tanggal| tanggal.to_string())
        .map_err(|_| ApiError::permintaan_tidak_valid("Tanggal harus memakai format YYYY-MM-DD"))
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Perhitungan Smart Dinner gagal");
    ApiError::kesalahan_internal()
}
