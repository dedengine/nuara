# Nuara Mobile

Aplikasi orang tua Nuara untuk Android dan iOS. Aplikasi tidak meminta NIK, KK, nama anak, maupun akun pengguna.

## Fitur yang Tersedia

- Mengambil daftar unit SPPG aktif dari backend.
- Mengambil sekolah aktif berdasarkan unit yang dipilih.
- Menyimpan pilihan SPPG dan sekolah secara lokal di perangkat.
- Menampilkan kembali sekolah pilihan saat aplikasi dibuka ulang.
- Mengubah sekolah tanpa menghapus atau mengirim data pribadi.
- Menampilkan menu hari ini beserta komponen makanan dan kategori alergi.
- Menampilkan indikator kalori, protein, lemak, dan karbohidrat berdasarkan target jenjang.
- Membuka tautan sumber data gizi dan sumber target kecukupan.
- Menampilkan galeri foto serta memutar video dokumentasi dapur.
- Menangani kondisi menu belum diterbitkan, media kosong, dan kegagalan koneksi.
- Menampilkan riwayat menu 7, 14, atau 30 hari dengan detail nutrisi, komponen, alergi, dan media.
- Menampilkan Smart Dinner dengan kekurangan nutrisi dan 2-3 rekomendasi makan malam lokal.
- Menampilkan skor kecocokan, nilai gizi, fokus nutrisi, sumber data, dan catatan batasan rekomendasi.
- Mengirim aduan anonim dengan kategori, nilai kepuasan, uraian, dan bukti foto/video wajib.
- Mengambil bukti dari kamera atau galeri, memvalidasi ukuran dan durasi, serta menampilkan progres unggah.
- Mendukung JPG, PNG, WebP, MP4, WebM, dan MOV agar kamera Android maupun iOS dapat digunakan.
- Menyediakan navigasi bawah untuk Beranda, Riwayat, Dinner, dan Aduan tanpa kehilangan posisi halaman.

## Menjalankan

Pastikan backend Rust dan MySQL FlyEnv sudah aktif.

Android Emulator:

```powershell
flutter run -d <ID_EMULATOR> --dart-define=API_URL=http://10.0.2.2:8080
```

iOS Simulator dari macOS:

```bash
flutter run -d <ID_SIMULATOR> --dart-define=API_URL=http://127.0.0.1:8080
```

Perangkat fisik harus memakai alamat IP LAN komputer, misalnya:

```powershell
flutter run -d <ID_PERANGKAT> --dart-define=API_URL=http://192.168.1.10:8080
```

Backend untuk perangkat fisik perlu mendengarkan pada `0.0.0.0` dan komputer serta ponsel harus berada di jaringan yang sama.

## Pemeriksaan

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8080
```

Identifier aplikasi Android dan iOS: `id.nuara.mobile`.
