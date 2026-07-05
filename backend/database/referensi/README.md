# Referensi Wilayah Indonesia

Data wilayah pada migrasi `202606290001_referensi_wilayah_indonesia.sql`
mencakup provinsi, kabupaten/kota, kecamatan, serta kelurahan/desa di Indonesia.

## Sumber

- Hierarki dan kode wilayah: `cahyadsn/wilayah`, berdasarkan Keputusan Menteri
  Dalam Negeri Nomor 300.2.2-2430 Tahun 2025.
- Pemetaan kode pos: `cahyadsn/wilayah_kodepos`, berdasarkan kode wilayah
  Kemendagri dan referensi kode pos Indonesia.

Kedua repositori sumber menggunakan lisensi MIT. Salinan lisensinya disimpan
di folder ini.

## Perilaku Aplikasi

- Data diminta bertingkat agar web dan mobile tidak memuat seluruh kelurahan
  sekaligus.
- Nama wilayah yang disimpan pada unit SPPG selalu diambil kembali dari tabel
  referensi berdasarkan kode wilayah.
- Jika suatu tingkat wilayah, kode pos, SPPG, atau sekolah belum tersedia,
  antarmuka menampilkan pesan `Segera Datang`.
