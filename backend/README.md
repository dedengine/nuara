# Backend Nuara

Web API Nuara menggunakan Rust, Axum, SQLx, dan MySQL. Konfigurasi development dibaca dari file `.env` di akar repository.

## Menjalankan

Pastikan MySQL di FlyEnv sudah aktif, lalu jalankan:

```powershell
cd backend
cargo run
```

Backend tersedia di `http://127.0.0.1:8080`. Migrasi yang belum pernah dijalankan akan diterapkan otomatis saat startup.

## Memeriksa

```powershell
cargo fmt --check
cargo check
cargo test
```

Endpoint pemeriksaan database tersedia melalui `GET /api/kesehatan`.

Endpoint autentikasi tersedia melalui `POST /api/admin/masuk`, `GET /api/admin/profil`, dan `POST /api/admin/keluar`. Token akses berlaku delapan jam dan dikirim memakai skema Bearer.

API saat ini juga menyediakan manajemen unit SPPG untuk Super Admin, manajemen sekolah untuk admin SPPG, serta daftar unit dan sekolah aktif untuk aplikasi mobile.

Upload media memerlukan `ffprobe` pada `PATH` untuk memeriksa durasi, resolusi, dan frame rate video. File development disimpan di `storage/uploads` dan disajikan melalui `/media` dengan dukungan streaming range.

Backend juga menyediakan aduan anonim dengan bukti wajib, Complaint Center, statistik kepuasan, dan tiga rekomendasi Smart Dinner dari koleksi menu lokal.

## Data Demo

Seed development tidak dijalankan otomatis agar tidak masuk ke database produksi. Untuk database lokal yang masih kosong, jalankan file `database/seeds/development.sql` menggunakan akun database Nuara.
