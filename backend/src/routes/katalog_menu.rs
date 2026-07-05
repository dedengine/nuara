use std::collections::{HashMap, HashSet};

use axum::{
    Json,
    extract::State,
    http::{HeaderMap, StatusCode},
};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use super::otorisasi::wajib_admin_sppg_aktif;
use crate::{error::ApiError, state::AppState};

#[derive(Clone, Debug, Serialize)]
pub struct BahanPangan {
    id: u64,
    kode_tkpi: String,
    nama: String,
    kategori: String,
    energi_per_100g: f64,
    protein_per_100g: f64,
    lemak_per_100g: f64,
    karbohidrat_per_100g: f64,
    sumber_data: String,
    url_sumber: String,
    terverifikasi: bool,
    alergi: Vec<String>,
}

#[derive(Debug, FromRow)]
struct BahanDasar {
    id: u64,
    kode_tkpi: String,
    nama: String,
    kategori: String,
    energi_per_100g: f64,
    protein_per_100g: f64,
    lemak_per_100g: f64,
    karbohidrat_per_100g: f64,
    sumber_data: String,
    url_sumber: String,
    terverifikasi: bool,
}

#[derive(Debug, FromRow)]
struct TemplateDasar {
    id: u64,
    nama: String,
    deskripsi: String,
    catatan_validasi: String,
    bawaan_sistem: bool,
}

#[derive(Debug, FromRow)]
struct BahanTemplateDasar {
    id_bahan_pangan: u64,
    berat_gram: f64,
    urutan: u8,
}

#[derive(Debug, Serialize)]
struct BahanTemplate {
    #[serde(flatten)]
    bahan: BahanPangan,
    berat_gram: f64,
    urutan: u8,
}

#[derive(Debug, Serialize)]
struct NilaiNutrisi {
    kalori: u16,
    protein: f64,
    lemak: f64,
    karbohidrat: f64,
}

#[derive(Debug, Serialize)]
struct TemplateMenu {
    id: u64,
    nama: String,
    deskripsi: String,
    catatan_validasi: String,
    bawaan_sistem: bool,
    terverifikasi: bool,
    nutrisi: NilaiNutrisi,
    alergi: Vec<String>,
    bahan: Vec<BahanTemplate>,
}

#[derive(Debug, Serialize)]
pub struct KatalogMenu {
    bahan: Vec<BahanPangan>,
    template: Vec<TemplateMenu>,
}

#[derive(Debug, Serialize)]
pub struct ResponsData<T> {
    sukses: bool,
    data: T,
}

#[derive(Debug, Serialize)]
pub struct ResponsPesan {
    sukses: bool,
    pesan: &'static str,
}

#[derive(Debug, Deserialize)]
pub struct DataTemplateBaru {
    nama: String,
    deskripsi: String,
    bahan: Vec<DataBahanTemplate>,
}

#[derive(Debug, Deserialize)]
pub struct DataBahanTemplate {
    id_bahan_pangan: u64,
    berat_gram: f64,
}

pub async fn daftar(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ResponsData<KatalogMenu>>, ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    let bahan = muat_bahan(&state).await?;
    let indeks_bahan = bahan
        .iter()
        .cloned()
        .map(|item| (item.id, item))
        .collect::<HashMap<_, _>>();
    let daftar_template = sqlx::query_as::<_, TemplateDasar>(
        r#"
        SELECT id, nama, deskripsi, catatan_validasi,
               (id_unit_sppg IS NULL) AS bawaan_sistem
        FROM template_menu
        WHERE aktif = TRUE AND (id_unit_sppg IS NULL OR id_unit_sppg = ?)
        ORDER BY (id_unit_sppg IS NULL) DESC, nama
        "#,
    )
    .bind(id_unit_sppg)
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;

    let mut template = Vec::with_capacity(daftar_template.len());
    for item in daftar_template {
        let komposisi = sqlx::query_as::<_, BahanTemplateDasar>(
            r#"
            SELECT id_bahan_pangan, CAST(berat_gram AS DOUBLE) AS berat_gram, urutan
            FROM template_menu_bahan
            WHERE id_template_menu = ?
            ORDER BY urutan, id_bahan_pangan
            "#,
        )
        .bind(item.id)
        .fetch_all(&state.database)
        .await
        .map_err(kesalahan_database)?;

        let mut bahan_template = Vec::with_capacity(komposisi.len());
        let mut alergi = HashSet::new();
        let mut terverifikasi = true;
        for komponen in komposisi {
            let bahan = indeks_bahan
                .get(&komponen.id_bahan_pangan)
                .cloned()
                .ok_or_else(ApiError::kesalahan_internal)?;
            alergi.extend(bahan.alergi.iter().cloned());
            terverifikasi &= bahan.terverifikasi;
            bahan_template.push(BahanTemplate {
                bahan,
                berat_gram: komponen.berat_gram,
                urutan: komponen.urutan,
            });
        }
        let mut daftar_alergi = alergi.into_iter().collect::<Vec<_>>();
        daftar_alergi.sort();
        let nutrisi = hitung_nutrisi(&bahan_template);
        template.push(TemplateMenu {
            id: item.id,
            nama: item.nama,
            deskripsi: item.deskripsi,
            catatan_validasi: item.catatan_validasi,
            bawaan_sistem: item.bawaan_sistem,
            terverifikasi,
            nutrisi,
            alergi: daftar_alergi,
            bahan: bahan_template,
        });
    }

    Ok(Json(ResponsData {
        sukses: true,
        data: KatalogMenu { bahan, template },
    }))
}

pub async fn tambah_template(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(mut input): Json<DataTemplateBaru>,
) -> Result<(StatusCode, Json<ResponsPesan>), ApiError> {
    let id_unit_sppg = wajib_admin_sppg_aktif(&headers, &state).await?;
    input.nama = input.nama.trim().to_owned();
    input.deskripsi = input.deskripsi.trim().to_owned();
    if input.nama.len() < 3 || input.deskripsi.len() < 10 {
        return Err(ApiError::permintaan_tidak_valid(
            "Nama template minimal 3 karakter dan deskripsi minimal 10 karakter",
        ));
    }
    if input.bahan.is_empty() || input.bahan.len() > 20 {
        return Err(ApiError::permintaan_tidak_valid(
            "Template harus memiliki 1 sampai 20 bahan",
        ));
    }
    let mut id_unik = HashSet::new();
    for bahan in &input.bahan {
        if !id_unik.insert(bahan.id_bahan_pangan)
            || !bahan.berat_gram.is_finite()
            || bahan.berat_gram <= 0.0
            || bahan.berat_gram > 2000.0
        {
            return Err(ApiError::permintaan_tidak_valid(
                "Bahan template tidak boleh ganda dan berat harus antara 0 sampai 2000 gram",
            ));
        }
    }
    for id in &id_unik {
        let aktif =
            sqlx::query_scalar::<_, bool>("SELECT aktif FROM bahan_pangan WHERE id = ? LIMIT 1")
                .bind(id)
                .fetch_optional(&state.database)
                .await
                .map_err(kesalahan_database)?
                .unwrap_or(false);
        if !aktif {
            return Err(ApiError::permintaan_tidak_valid(
                "Salah satu bahan tidak tersedia pada katalog",
            ));
        }
    }

    let mut transaksi = state.database.begin().await.map_err(kesalahan_database)?;
    let sudah_ada = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM template_menu WHERE id_unit_sppg = ? AND LOWER(nama) = LOWER(?)",
    )
    .bind(id_unit_sppg)
    .bind(&input.nama)
    .fetch_one(&mut *transaksi)
    .await
    .map_err(kesalahan_database)?
        > 0;
    if sudah_ada {
        return Err(ApiError::konflik(
            "Nama template sudah digunakan pada unit ini",
        ));
    }
    let hasil = sqlx::query(
        r#"
        INSERT INTO template_menu
            (id_unit_sppg, nama, deskripsi, catatan_validasi, aktif)
        VALUES (?, ?, ?, 'Template unit; validasi ahli gizi tetap diperlukan.', TRUE)
        "#,
    )
    .bind(id_unit_sppg)
    .bind(&input.nama)
    .bind(&input.deskripsi)
    .execute(&mut *transaksi)
    .await
    .map_err(kesalahan_database)?;
    let id_template = hasil.last_insert_id();
    for (index, bahan) in input.bahan.iter().enumerate() {
        sqlx::query(
            "INSERT INTO template_menu_bahan (id_template_menu, id_bahan_pangan, berat_gram, urutan) VALUES (?, ?, ?, ?)",
        )
        .bind(id_template)
        .bind(bahan.id_bahan_pangan)
        .bind(bahan.berat_gram)
        .bind((index + 1) as u8)
        .execute(&mut *transaksi)
        .await
        .map_err(kesalahan_database)?;
    }
    transaksi.commit().await.map_err(kesalahan_database)?;

    Ok((
        StatusCode::CREATED,
        Json(ResponsPesan {
            sukses: true,
            pesan: "Template menu berhasil disimpan",
        }),
    ))
}

async fn muat_bahan(state: &AppState) -> Result<Vec<BahanPangan>, ApiError> {
    let daftar = sqlx::query_as::<_, BahanDasar>(
        r#"
        SELECT id, kode_tkpi, nama, kategori,
               CAST(energi_per_100g AS DOUBLE) AS energi_per_100g,
               CAST(protein_per_100g AS DOUBLE) AS protein_per_100g,
               CAST(lemak_per_100g AS DOUBLE) AS lemak_per_100g,
               CAST(karbohidrat_per_100g AS DOUBLE) AS karbohidrat_per_100g,
               sumber_data, url_sumber, terverifikasi
        FROM bahan_pangan
        WHERE aktif = TRUE
        ORDER BY kategori, nama
        "#,
    )
    .fetch_all(&state.database)
    .await
    .map_err(kesalahan_database)?;
    let mut hasil = Vec::with_capacity(daftar.len());
    for item in daftar {
        let alergi = sqlx::query_scalar::<_, String>(
            "SELECT nama_alergi FROM alergi_bahan_pangan WHERE id_bahan_pangan = ? ORDER BY nama_alergi",
        )
        .bind(item.id)
        .fetch_all(&state.database)
        .await
        .map_err(kesalahan_database)?;
        hasil.push(BahanPangan {
            id: item.id,
            kode_tkpi: item.kode_tkpi,
            nama: item.nama,
            kategori: item.kategori,
            energi_per_100g: item.energi_per_100g,
            protein_per_100g: item.protein_per_100g,
            lemak_per_100g: item.lemak_per_100g,
            karbohidrat_per_100g: item.karbohidrat_per_100g,
            sumber_data: item.sumber_data,
            url_sumber: item.url_sumber,
            terverifikasi: item.terverifikasi,
            alergi,
        });
    }
    Ok(hasil)
}

fn hitung_nutrisi(bahan: &[BahanTemplate]) -> NilaiNutrisi {
    let mut energi = 0.0;
    let mut protein = 0.0;
    let mut lemak = 0.0;
    let mut karbohidrat = 0.0;
    for item in bahan {
        let faktor = item.berat_gram / 100.0;
        energi += item.bahan.energi_per_100g * faktor;
        protein += item.bahan.protein_per_100g * faktor;
        lemak += item.bahan.lemak_per_100g * faktor;
        karbohidrat += item.bahan.karbohidrat_per_100g * faktor;
    }
    NilaiNutrisi {
        kalori: energi.round().clamp(1.0, u16::MAX as f64) as u16,
        protein: bulatkan_dua(protein),
        lemak: bulatkan_dua(lemak),
        karbohidrat: bulatkan_dua(karbohidrat),
    }
}

fn bulatkan_dua(nilai: f64) -> f64 {
    (nilai * 100.0).round() / 100.0
}

fn kesalahan_database(error: sqlx::Error) -> ApiError {
    tracing::error!(%error, "Operasi katalog menu gagal");
    ApiError::kesalahan_internal()
}
