<p align="center">
  <img src="NUARA/assets/branding/nuara-logo.png" alt="Logo NUARA" width="180">
</p>

<h1 align="center">NUARA</h1>

<p align="center">
  <strong>Nutrisi Anak Nusantara</strong><br>
  Sistem terintegrasi untuk transparansi menu, nutrisi, dokumentasi dapur, dan aduan program makanan sekolah.
</p>

## Tentang NUARA

NUARA menghubungkan pengelola SPPG dengan orang tua murid melalui tiga komponen utama:

- **Web Admin** untuk Super Admin dan Admin SPPG.
- **Aplikasi Mobile** untuk orang tua murid tanpa pendaftaran data pribadi.
- **REST API** sebagai penghubung aplikasi dengan database MySQL dan penyimpanan media.

Proyek ini dikembangkan sebagai tugas akhir dan saat ini berada pada tahap **MVP (Minimum Viable Product)**. Fitur utama sudah dapat digunakan untuk mendemonstrasikan alur pengelolaan SPPG dari dapur hingga orang tua.

## Fitur Utama

### Web Admin

- Login berbasis peran untuk Super Admin dan Admin SPPG.
- Pengelolaan unit SPPG beserta alamat wilayah Indonesia.
- Pengelolaan akun Admin SPPG dan reset password.
- Pengelolaan sekolah binaan.
- Penyusunan menu harian menggunakan katalog bahan dan template menu.
- Perhitungan nutrisi berdasarkan komponen dan berat bahan.
- Informasi alergi makanan.
- Unggah beberapa foto dan video dokumentasi secara bersamaan.
- Pusat aduan, statistik kepuasan, dan pembaruan data melalui SSE.
- Tema terang dan gelap.

### Aplikasi Mobile

- Pemilihan wilayah, unit SPPG, dan sekolah secara bertahap.
- Riwayat pilihan SPPG dan sekolah pada perangkat.
- Menu harian, komponen makanan, nutrisi, alergi, dan sumber data.
- Riwayat menu sekolah.
- Foto dan video dokumentasi dapur.
- Rekomendasi Smart Dinner berdasarkan kekurangan nutrisi makan siang.
- Aduan anonim dengan bukti foto atau video.
- Deteksi otomatis jika SPPG atau sekolah dinonaktifkan.
- Tema terang dan gelap.

## Teknologi

| Komponen | Teknologi |
|---|---|
| Web Admin | Flutter Web, Riverpod, Dio, `fl_chart` |
| Mobile | Flutter Android/iOS, Riverpod, Dio |
| Backend | Rust, Axum, Tokio, SQLx |
| Database | MySQL melalui FlyEnv |
| Autentikasi | JWT dan Argon2id |
| Real-time | Server-Sent Events (SSE) |
| Media demo | Penyimpanan lokal backend |

## Arsitektur

```mermaid
flowchart LR
    WEB["Flutter Web Admin"] --> API["Rust REST API"]
    MOBILE["Flutter Mobile"] --> API
    API --> DB[("MySQL")]
    API --> MEDIA["Penyimpanan Media Lokal"]
    API -- "SSE aduan" --> WEB
```

Web dan Mobile tidak mengakses MySQL secara langsung. Seluruh validasi, otorisasi, perhitungan nutrisi, dan pengelolaan media dilakukan oleh backend.

## Struktur Repository

```text
NUARA/
|-- README.md
|-- DOKUMENTASI BARU/          # Dokumentasi teknis terbaru
|-- DOKUMENTASI LAMA/          # Arsip perencanaan sebelumnya
`-- NUARA/                     # Source code aplikasi
    |-- backend/               # API Rust, migrasi, dan seed MySQL
    |-- flutter_admin_web/     # Dashboard Flutter Web
    |-- flutter_mobile/        # Aplikasi Flutter Android/iOS
    |-- assets/                # Identitas visual
    |-- docs/                  # Dokumentasi source
    `-- scripts/               # Utilitas pengembangan
```

## Prasyarat

- Flutter SDK stable.
- Rust dan Cargo.
- FlyEnv dengan MySQL Server.
- Android Studio untuk Android SDK dan emulator.
- VS Code atau editor lain.
- Python opsional untuk menyajikan hasil build Flutter Web.
- FFmpeg/`ffprobe` untuk validasi video pada backend.

Periksa instalasi:

```powershell
flutter doctor
rustc --version
cargo --version
```

## Persiapan Database

Jalankan MySQL melalui FlyEnv, kemudian buat database dan pengguna aplikasi:

```sql
CREATE DATABASE nuara
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'nuara_app'@'localhost'
  IDENTIFIED BY 'password_lokal_yang_kuat';

GRANT ALL PRIVILEGES ON nuara.* TO 'nuara_app'@'localhost';
FLUSH PRIVILEGES;
```

Hak `CREATE`, `ALTER`, dan `DROP` diperlukan selama migrasi development.

## Konfigurasi Backend

Masuk ke folder source, salin konfigurasi contoh, lalu sesuaikan nilainya:

```powershell
cd NUARA
Copy-Item .env.example .env
```

Contoh isi `.env`:

```env
DATABASE_URL=mysql://nuara_app:PASSWORD_LOKAL@127.0.0.1:3306/nuara
HOST=127.0.0.1
PORT=8080
JWT_SECRET=GANTI_DENGAN_KUNCI_ACAK_MINIMAL_32_KARAKTER
STORAGE_PATH=storage/uploads
```

Jangan memasukkan `.env`, password database, atau JWT secret ke GitHub.

## Menjalankan Project

### 1. Backend

```powershell
cd NUARA\backend
cargo run
```

Backend tersedia di `http://127.0.0.1:8080`. Migrasi SQLx dijalankan otomatis saat backend dimulai.

Untuk database development yang masih kosong, jalankan seed secara manual melalui phpMyAdmin atau MySQL:

```text
NUARA/backend/database/seeds/development.sql
```

### 2. Web Admin

Buka terminal baru dari folder akar repository:

```powershell
cd NUARA\flutter_admin_web
flutter pub get
flutter run -d chrome --web-port 5173
```

Web tersedia di `http://127.0.0.1:5173`.

### 3. Mobile pada Android Emulator

Jalankan emulator melalui Android Studio Device Manager, kemudian:

```powershell
cd NUARA\flutter_mobile
flutter pub get
flutter run
```

Android Emulator menggunakan `http://10.0.2.2:8080` untuk mengakses backend komputer.

### HP Fisik

Ubah `HOST` backend menjadi `0.0.0.0`, pastikan HP dan komputer berada pada jaringan yang sama, lalu jalankan:

```powershell
flutter run --dart-define=API_URL=http://IP_KOMPUTER:8080
```

## Akun Demo Development

| Peran | Email | Password awal |
|---|---|---|
| Super Admin | `superadmin@nuara.test` | `nuara123` |
| Admin SPPG | `admin@nuara.test` | `nuara123` |

Akun tersedia setelah seed development dijalankan. Password disimpan sebagai hash Argon2id dan sebaiknya langsung diubah di luar lingkungan demo.

## Build

### Backend Windows

```powershell
cd NUARA\backend
cargo build --release
.\target\release\nuara_api.exe
```

### Flutter Web

```powershell
cd NUARA\flutter_admin_web
flutter build web --dart-define=API_URL=http://127.0.0.1:8080
py -m http.server 5173 -d build\web
```

### Android APK

```powershell
cd NUARA\flutter_mobile
flutter build apk --release --dart-define=API_URL=http://ALAMAT_SERVER:8080
```

APK dihasilkan di `build/app/outputs/flutter-apk/app-release.apk`. Build iOS memerlukan macOS dan Xcode.

## Pengujian

```powershell
cd NUARA\backend
cargo test

cd ..\flutter_admin_web
flutter analyze
flutter test

cd ..\flutter_mobile
flutter analyze
flutter test
```

## Dokumentasi

Dokumentasi lengkap tersedia di [DOKUMENTASI BARU](DOKUMENTASI%20BARU/README.md):

- [Gambaran umum](DOKUMENTASI%20BARU/01-gambaran-umum.md)
- [Arsitektur sistem](DOKUMENTASI%20BARU/02-arsitektur-sistem.md)
- [Instalasi dan menjalankan](DOKUMENTASI%20BARU/03-instalasi-dan-menjalankan.md)
- [Panduan Web Admin](DOKUMENTASI%20BARU/04-panduan-web-admin.md)
- [Panduan aplikasi Mobile](DOKUMENTASI%20BARU/05-panduan-aplikasi-mobile.md)
- [Database dan relasi](DOKUMENTASI%20BARU/06-database-dan-relasi.md)
- [API dan SSE](DOKUMENTASI%20BARU/07-api-dan-sse.md)
- [Pengujian dan pemeliharaan](DOKUMENTASI%20BARU/08-pengujian-dan-pemeliharaan.md)
- [ERD dan LRS](DOKUMENTASI%20BARU/09-diagram-erd-dan-lrs.md)

## Sumber Data Nutrisi

- [PanganKu/TKPI](https://panganku.org/) untuk komposisi pangan Indonesia.
- [Permenkes Nomor 28 Tahun 2019](https://peraturan.bpk.go.id/Details/138621/permenkes-no-28-tahun-2019) untuk acuan AKG.
- [USDA FoodData Central](https://fdc.nal.usda.gov/) untuk beberapa bahan tambahan.

Nilai nutrisi pada aplikasi merupakan dukungan informasi untuk demonstrasi. Penggunaan operasional tetap memerlukan pemeriksaan ahli gizi sesuai penerima, bahan, porsi, dan proses memasak.

## Catatan Repository

- File `.env`, hasil build, cache, media upload, dan video demo tidak disimpan ke Git.
- Media runtime disimpan di `NUARA/backend/storage/uploads` untuk kebutuhan demo lokal.
- Video demo berukuran besar dapat disimpan menggunakan Git LFS atau layanan penyimpanan terpisah.
- Jalankan `NUARA/scripts/bersihkan-cache.ps1` untuk membersihkan cache development.

## Status

NUARA masih dikembangkan untuk kebutuhan akademik. Integrasi cloud storage, notifikasi perangkat, audit aktivitas, dan validasi ahli gizi formal dapat menjadi pengembangan berikutnya.
