# Pengujian Integrasi Nuara

Dokumen ini mencatat pengujian alur Web Admin, Mobile API, backend Rust, penyimpanan media lokal, dan MySQL FlyEnv.

## Skenario Aduan Anonim

Tanggal pengujian: 28 Juni 2026.

Data yang digunakan:

| Data | Nilai |
|---|---|
| Unit SPPG | SPPG Mekarjaya |
| Sekolah | SD Nusantara Mekarjaya 01 |
| Menu | Paket Ayam Panggang |
| Kategori | Porsi |
| Kepuasan | 3 dari 5 |
| Bukti | Video MP4, 13 detik, 576x1024, 30 fps |
| Nomor aduan | 2 |

Alur pengujian:

1. Aplikasi Mobile membaca unit SPPG, sekolah, dan menu hari ini dari API publik.
2. Orang tua mengisi kategori, nilai kepuasan, isi aduan, dan satu bukti video.
3. Mobile mengirim formulir `multipart/form-data` tanpa identitas orang tua atau anak.
4. Backend memvalidasi relasi unit, sekolah, menu, isi laporan, serta metadata video.
5. Aduan disimpan di MySQL dan bukti disimpan pada storage lokal FlyEnv.
6. Admin SPPG login dan membaca aduan melalui Complaint Center.
7. Admin membuka bukti video dan mengubah status dari `baru` menjadi `diproses`.
8. Statistik aduan diperiksa kembali setelah perubahan status.

## Hasil Pengujian

| Pemeriksaan | Hasil |
|---|---|
| Kesehatan API | Berhasil, database terhubung |
| Penyimpanan aduan | Berhasil |
| Relasi unit, sekolah, dan menu | Sesuai |
| Akses media | `HTTP 206`, `video/mp4` |
| Daftar aduan Admin SPPG | Aduan ditemukan |
| Status awal | `baru` |
| Status akhir | `diproses` |
| Statistik sebelum perubahan | Baru: 1, Diproses: 0 |
| Statistik sesudah perubahan | Baru: 0, Diproses: 1 |
| Rata-rata kepuasan | 3 dari 5 |

Pengujian jaringan dilakukan langsung ke endpoint yang sama dengan aplikasi Mobile karena emulator Android tidak sedang aktif. Pengujian antarmuka Mobile tetap dilakukan melalui widget test pada viewport 390x844, sedangkan APK debug berhasil dibangun.

## Skenario Demonstrasi

1. Nyalakan MySQL FlyEnv dan backend Rust.
2. Buka Web Admin dan login menggunakan `admin@nuara.test`.
3. Jalankan aplikasi Mobile, lalu pilih SPPG Mekarjaya dan SD Nusantara Mekarjaya 01.
4. Buka tab **Aduan**, isi laporan, dan lampirkan foto atau video.
5. Kembali ke Web Admin, buka menu **Aduan**, lalu pilih ikon mata pada laporan terbaru.
6. Periksa isi laporan dan media, kemudian ubah status menjadi **Diproses**.
7. Buka Ringkasan untuk memastikan statistik aduan ikut berubah.
