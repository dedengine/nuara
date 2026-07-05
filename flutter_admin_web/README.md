# Nuara Admin

Dashboard operasional Nuara berbasis Flutter Web untuk Super Admin dan admin SPPG.

Fitur pengelolaan yang tersedia:

- Super Admin dapat menambah dan mengubah unit SPPG, menonaktifkan unit, serta membuat satu admin untuk setiap unit.
- Admin SPPG dapat menambah, mengubah, dan menonaktifkan sekolah binaan.
- Admin SPPG dapat mengelola menu, nutrisi, sumber data, komponen makanan, cakupan sekolah, status publikasi, dan kategori alergi.
- Admin SPPG dapat mengunggah dan menghapus dokumentasi foto atau video pada setiap menu. Foto dibatasi 30 MB, sedangkan video dibatasi 100 MB, 60 detik, 1080p, dan 60 fps.
- Admin SPPG dapat memfilter aduan berdasarkan status dan sekolah, membuka detail laporan, melihat nilai kepuasan, serta memperbarui status tindak lanjut.
- Bukti foto ditampilkan langsung dan bukti video dapat diputar dari dialog detail aduan.
- Tabel desktop memakai pagination 5, 10, atau 20 baris dan berubah menjadi daftar vertikal pada layar sempit.

## Menjalankan

Pastikan MySQL FlyEnv dan backend Rust sudah aktif, lalu jalankan:

```powershell
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8080
```

## Pemeriksaan

```powershell
flutter analyze
flutter test
flutter build web --release --dart-define=API_URL=http://127.0.0.1:8080
```

Login demo:

- Admin SPPG: `admin@nuara.test` / `nuara123`
- Super Admin: `superadmin@nuara.test` / `nuara123`

Token demo disimpan melalui `shared_preferences`. Untuk deployment produksi, aplikasi harus memakai HTTPS dan kebijakan penyimpanan token yang disesuaikan dengan lingkungan hosting.
