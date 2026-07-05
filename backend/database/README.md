# Database Nuara

Database lokal menggunakan MySQL 8.4 dari FlyEnv. Semua perubahan struktur disimpan sebagai migrasi agar lingkungan pengembangan dapat dibuat ulang dengan hasil yang sama.

## Susunan Folder

- `migrations`: perubahan struktur database yang dijalankan berurutan.
- `seeds`: data demonstrasi yang hanya dipakai untuk pengembangan dan tugas akhir.

Migrasi pertama membuat tabel SPPG, admin, sekolah, menu, komponen makanan, alergi, media, aduan, dan rekomendasi makan malam.

Migrasi kedua menambahkan soft delete menu dan unique constraint tanggal/cakupan sekolah. Kolom internal `kunci_cakupan` bernilai `0` untuk menu semua sekolah atau sama dengan ID sekolah untuk menu khusus.

Nilai nutrisi seed adalah estimasi realistis untuk demonstrasi, bukan hasil pemeriksaan laboratorium atau saran medis. Setiap menu menyimpan nama dan URL sumber agar asal data dapat ditelusuri.
