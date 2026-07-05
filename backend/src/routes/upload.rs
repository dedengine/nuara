use std::{
    collections::HashMap,
    path::{Component, Path, PathBuf},
};

use axum::extract::Multipart;
use serde_json::Value;
use tokio::{fs, io::AsyncWriteExt, process::Command};
use uuid::Uuid;

const DURASI_VIDEO_MAKSIMAL_DETIK: f64 = 60.5;

use crate::error::ApiError;

const BATAS_FOTO: u64 = 30 * 1024 * 1024;
const BATAS_VIDEO: u64 = 100 * 1024 * 1024;

#[derive(Debug)]
pub struct FormUpload {
    pub field: HashMap<String, String>,
    pub berkas: BerkasUpload,
}

#[derive(Debug)]
pub struct BerkasUpload {
    pub jenis_media: &'static str,
    pub url_berkas: String,
    pub nama_berkas: String,
    pub ukuran_byte: u64,
    pub mime_type: String,
    pub durasi_detik: Option<u16>,
    pub path_lokal: PathBuf,
}

pub async fn simpan_multipart(
    mut multipart: Multipart,
    storage_path: &Path,
    subfolder: &str,
) -> Result<FormUpload, ApiError> {
    let folder = storage_path.join(subfolder);
    fs::create_dir_all(&folder)
        .await
        .map_err(kesalahan_storage)?;

    let mut field_teks = HashMap::new();
    let mut berkas: Option<(PathBuf, String, u64)> = None;

    while let Some(mut bagian) = multipart.next_field().await.map_err(|error| {
        tracing::warn!(%error, "Form multipart tidak dapat dibaca");
        ApiError::permintaan_tidak_valid("Form upload tidak valid")
    })? {
        let nama_field = bagian.name().unwrap_or_default().to_owned();
        if nama_field == "file" {
            if berkas.is_some() {
                return Err(ApiError::permintaan_tidak_valid(
                    "Satu request hanya boleh memuat satu berkas",
                ));
            }
            let nama_asli = bersihkan_nama_berkas(bagian.file_name().unwrap_or("media"));
            let path_sementara = folder.join(format!("{}.upload", Uuid::new_v4()));
            let mut file = fs::File::create(&path_sementara)
                .await
                .map_err(kesalahan_storage)?;
            let mut ukuran = 0_u64;

            while let Some(chunk) = bagian.chunk().await.map_err(|error| {
                tracing::warn!(%error, "Isi berkas multipart tidak dapat dibaca");
                ApiError::permintaan_tidak_valid("Berkas upload tidak dapat dibaca")
            })? {
                ukuran += chunk.len() as u64;
                if ukuran > BATAS_VIDEO {
                    drop(file);
                    hapus_berkas(&path_sementara).await;
                    return Err(ApiError::permintaan_tidak_valid(
                        "Ukuran berkas melebihi batas 100 MB",
                    ));
                }
                file.write_all(&chunk).await.map_err(kesalahan_storage)?;
            }
            file.flush().await.map_err(kesalahan_storage)?;
            berkas = Some((path_sementara, nama_asli, ukuran));
        } else if !nama_field.is_empty() {
            let nilai = bagian.text().await.map_err(|error| {
                tracing::warn!(%error, "Field multipart tidak dapat dibaca");
                ApiError::permintaan_tidak_valid("Field form upload tidak valid")
            })?;
            if nilai.len() > 10_000 {
                return Err(ApiError::permintaan_tidak_valid(
                    "Isi field form terlalu panjang",
                ));
            }
            field_teks.insert(nama_field, nilai.trim().to_owned());
        }
    }

    let (path_sementara, nama_asli, ukuran) = berkas.ok_or_else(|| {
        ApiError::permintaan_tidak_valid("Foto atau video bukti wajib dilampirkan")
    })?;
    if ukuran == 0 {
        hapus_berkas(&path_sementara).await;
        return Err(ApiError::permintaan_tidak_valid(
            "Berkas tidak boleh kosong",
        ));
    }

    let hasil = validasi_dan_finalisasi(path_sementara, nama_asli, ukuran, subfolder).await;
    match hasil {
        Ok(berkas) => Ok(FormUpload {
            field: field_teks,
            berkas,
        }),
        Err((error, path)) => {
            hapus_berkas(&path).await;
            Err(error)
        }
    }
}

async fn validasi_dan_finalisasi(
    path_sementara: PathBuf,
    nama_asli: String,
    ukuran: u64,
    subfolder: &str,
) -> Result<BerkasUpload, (ApiError, PathBuf)> {
    let jenis = infer::get_from_path(&path_sementara)
        .map_err(|error| (kesalahan_storage(error), path_sementara.clone()))?
        .ok_or_else(|| {
            (
                ApiError::permintaan_tidak_valid("Tipe berkas tidak dikenali"),
                path_sementara.clone(),
            )
        })?;
    let mime = jenis.mime_type();
    let (jenis_media, ekstensi, durasi_detik) = match mime {
        "image/jpeg" => {
            validasi_ukuran_foto(ukuran, &path_sementara)?;
            ("foto", "jpg", None)
        }
        "image/png" => {
            validasi_ukuran_foto(ukuran, &path_sementara)?;
            ("foto", "png", None)
        }
        "image/webp" => {
            validasi_ukuran_foto(ukuran, &path_sementara)?;
            ("foto", "webp", None)
        }
        "video/mp4" => {
            let durasi = validasi_video(&path_sementara)
                .await
                .map_err(|error| (error, path_sementara.clone()))?;
            ("video", "mp4", Some(durasi))
        }
        "video/webm" => {
            let durasi = validasi_video(&path_sementara)
                .await
                .map_err(|error| (error, path_sementara.clone()))?;
            ("video", "webm", Some(durasi))
        }
        "video/quicktime" => {
            let durasi = validasi_video(&path_sementara)
                .await
                .map_err(|error| (error, path_sementara.clone()))?;
            ("video", "mov", Some(durasi))
        }
        _ => {
            return Err((
                ApiError::permintaan_tidak_valid(
                    "Format yang diizinkan hanya JPG, PNG, WebP, MP4, WebM, dan MOV",
                ),
                path_sementara,
            ));
        }
    };

    let nama_final = format!("{}.{}", Uuid::new_v4(), ekstensi);
    let path_final = path_sementara.with_file_name(&nama_final);
    fs::rename(&path_sementara, &path_final)
        .await
        .map_err(|error| (kesalahan_storage(error), path_sementara.clone()))?;
    let subfolder_url = subfolder.replace('\\', "/");

    Ok(BerkasUpload {
        jenis_media,
        url_berkas: format!("/media/{subfolder_url}/{nama_final}"),
        nama_berkas: nama_asli,
        ukuran_byte: ukuran,
        mime_type: mime.to_owned(),
        durasi_detik,
        path_lokal: path_final,
    })
}

fn validasi_ukuran_foto(ukuran: u64, path: &Path) -> Result<(), (ApiError, PathBuf)> {
    if ukuran > BATAS_FOTO {
        return Err((
            ApiError::permintaan_tidak_valid("Ukuran foto melebihi batas 30 MB"),
            path.to_path_buf(),
        ));
    }
    Ok(())
}

async fn validasi_video(path: &Path) -> Result<u16, ApiError> {
    let output = Command::new("ffprobe")
        .args([
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=width,height,r_frame_rate:format=duration",
            "-of",
            "json",
        ])
        .arg(path)
        .output()
        .await
        .map_err(|error| {
            tracing::error!(%error, "ffprobe tidak dapat dijalankan");
            ApiError::kesalahan_internal()
        })?;
    if !output.status.success() {
        return Err(ApiError::permintaan_tidak_valid(
            "Video rusak atau metadata video tidak dapat dibaca",
        ));
    }

    let metadata: Value = serde_json::from_slice(&output.stdout).map_err(|error| {
        tracing::error!(%error, "Output ffprobe tidak valid");
        ApiError::kesalahan_internal()
    })?;
    let durasi = metadata["format"]["duration"]
        .as_str()
        .and_then(|nilai| nilai.parse::<f64>().ok())
        .ok_or_else(|| ApiError::permintaan_tidak_valid("Durasi video tidak ditemukan"))?;
    let stream = metadata["streams"]
        .as_array()
        .and_then(|streams| streams.first())
        .ok_or_else(|| ApiError::permintaan_tidak_valid("Stream video tidak ditemukan"))?;
    let lebar = stream["width"].as_u64().unwrap_or_default();
    let tinggi = stream["height"].as_u64().unwrap_or_default();
    let fps = stream["r_frame_rate"]
        .as_str()
        .and_then(parse_fps)
        .unwrap_or_default();

    if !durasi_video_valid(durasi) {
        return Err(ApiError::permintaan_tidak_valid(
            "Durasi video harus antara 1 dan 60 detik",
        ));
    }
    let resolusi_valid = (lebar <= 1920 && tinggi <= 1080) || (lebar <= 1080 && tinggi <= 1920);
    if lebar == 0 || tinggi == 0 || !resolusi_valid {
        return Err(ApiError::permintaan_tidak_valid(
            "Resolusi video maksimal 1920x1080 atau 1080x1920",
        ));
    }
    if fps <= 0.0 || fps > 60.5 {
        return Err(ApiError::permintaan_tidak_valid(
            "Frame rate video maksimal 60 fps",
        ));
    }

    Ok(durasi.ceil() as u16)
}

fn durasi_video_valid(durasi: f64) -> bool {
    durasi > 0.0 && durasi <= DURASI_VIDEO_MAKSIMAL_DETIK
}

fn parse_fps(nilai: &str) -> Option<f64> {
    let (pembilang, penyebut) = nilai.split_once('/')?;
    let pembilang = pembilang.parse::<f64>().ok()?;
    let penyebut = penyebut.parse::<f64>().ok()?;
    (penyebut > 0.0).then_some(pembilang / penyebut)
}

fn bersihkan_nama_berkas(nama: &str) -> String {
    let nama = Path::new(nama)
        .file_name()
        .and_then(|nama| nama.to_str())
        .unwrap_or("media");
    let bersih: String = nama
        .chars()
        .filter(|karakter| !karakter.is_control())
        .take(200)
        .collect();
    if bersih.trim().is_empty() {
        "media".to_owned()
    } else {
        bersih
    }
}

pub async fn hapus_berkas(path: &Path) {
    if let Err(error) = fs::remove_file(path).await
        && error.kind() != std::io::ErrorKind::NotFound
    {
        tracing::warn!(%error, path = %path.display(), "Berkas media gagal dihapus");
    }
}

pub fn path_dari_url(storage_path: &Path, url: &str) -> Option<PathBuf> {
    let relatif = url.strip_prefix("/media/")?;
    let path = Path::new(relatif);
    if path
        .components()
        .any(|komponen| !matches!(komponen, Component::Normal(_)))
    {
        return None;
    }
    Some(storage_path.join(path))
}

fn kesalahan_storage(error: impl std::fmt::Display) -> ApiError {
    tracing::error!(%error, "Operasi penyimpanan media gagal");
    ApiError::kesalahan_internal()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn frame_rate_fraction_dibaca_dengan_benar() {
        assert_eq!(parse_fps("30000/1001").unwrap().round(), 30.0);
        assert!(parse_fps("60/0").is_none());
    }

    #[test]
    fn durasi_video_maksimal_satu_menit() {
        assert!(durasi_video_valid(1.0));
        assert!(durasi_video_valid(60.5));
        assert!(!durasi_video_valid(0.0));
        assert!(!durasi_video_valid(60.6));
    }

    #[test]
    fn url_media_tidak_boleh_keluar_dari_storage() {
        let storage = Path::new("storage/uploads");
        assert!(path_dari_url(storage, "/media/menu/1/foto.jpg").is_some());
        assert!(path_dari_url(storage, "/media/../rahasia.env").is_none());
    }
}
