# Dokumentasi API Nuara

Base URL development: `http://127.0.0.1:8080`

Semua respons memakai JSON. Pesan yang ditampilkan kepada pengguna memakai bahasa Indonesia.

## Endpoint Dasar

| Method | Endpoint | Autentikasi | Fungsi |
|---|---|---|---|
| `GET` | `/` | Tidak | Menampilkan nama dan versi API. |
| `GET` | `/api/kesehatan` | Tidak | Memeriksa apakah API dan MySQL dapat dihubungi. |
| `POST` | `/api/admin/masuk` | Tidak | Login Super Admin atau admin SPPG. |
| `GET` | `/api/admin/profil` | Bearer token | Mengambil profil admin yang sedang masuk. |
| `PUT` | `/api/admin/profil` | Super Admin | Mengubah nama dan email profil Super Admin sendiri. |
| `POST` | `/api/admin/keluar` | Bearer token | Memvalidasi logout; klien kemudian menghapus token. |

Contoh respons kesehatan:

```json
{
  "status": "sehat",
  "layanan": "aktif",
  "database": "terhubung",
  "versi": "0.1.0"
}
```

Route yang tidak ditemukan mengembalikan status `404` dengan format:

```json
{
  "sukses": false,
  "error": {
    "kode": "ROUTE_TIDAK_DITEMUKAN",
    "pesan": "Alamat API yang diminta tidak tersedia"
  }
}
```

## Autentikasi Admin

Request login:

```json
{
  "email": "admin@nuara.test",
  "password": "nuara123"
}
```

Login yang berhasil mengembalikan `token_akses` bertipe `Bearer`, masa berlaku delapan jam, dan profil admin. Token dikirim pada endpoint terlindungi melalui header berikut:

```text
Authorization: Bearer <token_akses>
```

Password disimpan sebagai hash Argon2id. Respons login gagal tidak membedakan apakah email atau password yang salah. Logout pada MVP bersifat stateless, sehingga aplikasi wajib menghapus token lokal setelah menerima respons berhasil.

## Unit SPPG

| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| `GET` | `/api/unit-sppg` | Publik | Daftar unit SPPG aktif untuk aplikasi mobile. |
| `GET` | `/api/super-admin/unit-sppg` | Super Admin | Daftar semua unit, termasuk status dan admin unit. |
| `POST` | `/api/super-admin/unit-sppg` | Super Admin | Membuat unit SPPG baru. |
| `PUT` | `/api/super-admin/unit-sppg/{id}` | Super Admin | Mengubah data atau status unit. |
| `DELETE` | `/api/super-admin/unit-sppg/{id}` | Super Admin | Menonaktifkan unit dan akun adminnya. |
| `DELETE` | `/api/super-admin/unit-sppg/{id}/permanen` | Super Admin | Menghapus unit beserta seluruh sekolah, menu, media, aduan, dan akun adminnya secara permanen. |
| `POST` | `/api/super-admin/unit-sppg/{id}/admin` | Super Admin | Membuat satu akun admin untuk unit. |
| `PUT` | `/api/super-admin/unit-sppg/{id}/admin` | Super Admin | Mengubah nama, email, atau password admin unit. |
| `POST` | `/api/super-admin/unit-sppg/{id}/admin/reset-password` | Super Admin | Mereset password admin unit menjadi `nuara123`. |

Alamat unit wajib berisi provinsi, kabupaten/kota, kecamatan, kelurahan/desa, kode pos lima angka, RT, RW, dan alamat detail. Satu unit hanya dapat mempunyai satu akun `admin_sppg`. Reset password hanya dapat dijalankan oleh Super Admin dan nilai default tetap disimpan sebagai hash Argon2id.

## Sekolah

| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| `GET` | `/api/unit-sppg/{id}/sekolah` | Publik | Daftar sekolah aktif pada unit aktif. |
| `GET` | `/api/admin/sekolah` | Admin SPPG | Daftar semua sekolah milik unit admin. |
| `POST` | `/api/admin/sekolah` | Admin SPPG | Menambah sekolah pada unit dari token. |
| `PUT` | `/api/admin/sekolah/{id}` | Admin SPPG | Mengubah sekolah milik unit admin. |
| `DELETE` | `/api/admin/sekolah/{id}` | Admin SPPG | Menonaktifkan sekolah tanpa menghapus riwayat. |

Admin tidak dapat mengirim `id_unit_sppg` sendiri. Backend selalu mengambil unit dari token dan memeriksa bahwa akun serta unit masih aktif. Jenjang yang diterima adalah `SD`, `SMP`, `SMA`, `SMK`, `SLB`, dan `LAINNYA`.

## Menu, Nutrisi, dan Alergi

| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| `GET` | `/api/admin/menu-harian` | Admin SPPG | Daftar seluruh menu milik unit, termasuk yang nonaktif. |
| `GET` | `/api/admin/katalog-menu` | Admin SPPG | Katalog bahan TKPI dan template menu yang tersedia. |
| `POST` | `/api/admin/katalog-menu` | Admin SPPG | Menyimpan susunan bahan sebagai template milik unit. |
| `POST` | `/api/admin/menu-harian` | Admin SPPG | Menambah menu beserta komponen dan alergi. |
| `PUT` | `/api/admin/menu-harian/{id}` | Admin SPPG | Mengubah menu, nutrisi, komponen, dan alergi. |
| `DELETE` | `/api/admin/menu-harian/{id}` | Admin SPPG | Menonaktifkan menu tanpa menghapus riwayat. |
| `GET` | `/api/mobile/menu-harian?id_sekolah={id}&tanggal={YYYY-MM-DD}` | Publik | Menu sekolah pada tanggal tertentu; tanggal boleh dikosongkan untuk hari ini. |
| `GET` | `/api/mobile/menu-harian/riwayat?id_sekolah={id}&jumlah_hari={1-30}` | Publik | Riwayat menu sampai tanggal lokal hari ini. |

Request menu memuat data utama berikut:

```json
{
  "id_sekolah": null,
  "tanggal_menu": "2026-06-27",
  "nama_menu": "Paket Ikan Kembung",
  "deskripsi": "Nasi, ikan, sayur, dan buah.",
  "kalori": 610,
  "protein": 34.8,
  "lemak": 16.4,
  "karbohidrat": 80.2,
  "sumber_data_gizi": "PanganKu/TKPI",
  "url_sumber_data_gizi": "https://panganku.org/",
  "status": "dipublikasikan",
  "komponen": [
    { "nama_komponen": "Nasi", "keterangan_porsi": "150 gram", "urutan": 1 }
  ],
  "alergi": [
    { "nama_alergi": "seafood", "keterangan": "Ikan kembung" }
  ]
}
```

Pada mode otomatis, setiap komponen juga mengirim `id_bahan_pangan` dan `berat_gram`. Backend mengambil nama, nutrisi per 100 gram, sumber, dan alergi dari katalog lalu menghitung ulang totalnya. Contoh komponen otomatis:

```json
{
  "id_bahan_pangan": 1,
  "nama_komponen": "",
  "keterangan_porsi": null,
  "berat_gram": 150,
  "urutan": 1
}
```

Template bawaan berjumlah 32 dan merupakan komposisi awal berbasis TKPI, SIPERA, serta USDA FoodData Central, bukan daftar nama menu wajib BGN. Variasinya mencakup ayam, telur, tahu, tempe, ikan kembung, sapi, lele, salmon, dan nila. Admin dapat menyesuaikan berat bahan dan menyimpan variasi sebagai template unit; hasil akhir tetap perlu divalidasi ahli gizi sesuai kelompok penerima dan proses memasak.

Respons template memiliki penanda `terverifikasi`. Nilai `true` hanya muncul jika semua bahan penyusunnya telah ditandai terverifikasi di katalog. Template berlabel `Referensi` tetap dihitung oleh backend dari berat setiap bahan, tetapi belum boleh dianggap sebagai persetujuan ahli gizi.

Nilai `id_sekolah: null` berarti menu berlaku untuk semua sekolah pada unit. Bila pada tanggal yang sama tersedia menu umum dan menu khusus sekolah, mobile memilih menu khusus. Satu tanggal dan cakupan sekolah hanya boleh mempunyai satu menu. Status yang tersedia adalah `draf` dan `dipublikasikan`; hanya menu aktif yang sudah dipublikasikan dapat dibaca mobile.

## Media Menu

| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| `POST` | `/api/admin/menu-harian/{id}/media` | Admin SPPG | Mengunggah satu foto atau video untuk menu milik unit. |
| `DELETE` | `/api/admin/media-menu/{id}` | Admin SPPG | Menghapus metadata dan file media menu. |
| `GET` | `/media/{path}` | Publik | Membaca atau streaming media yang sudah disimpan. |

Upload memakai `multipart/form-data` dengan field file bernama `file`. Foto menerima JPG, PNG, atau WebP maksimal 30 MB. Video menerima MP4, WebM, atau MOV maksimal 100 MB, durasi maksimal 60 detik, resolusi maksimal 1920x1080/1080x1920, dan frame rate maksimal 60 fps. Metadata video diperiksa memakai `ffprobe`. MOV didukung agar rekaman kamera iOS dapat langsung digunakan. Dashboard dapat memilih maksimal 10 foto dan video secara bersamaan; berkas dikirim berurutan ke endpoint ini agar penggunaan memori dan ukuran request tetap terkendali.

## Aduan Anonim

| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| `POST` | `/api/mobile/aduan` | Publik | Mengirim aduan anonim dengan satu bukti wajib. |
| `GET` | `/api/admin/aduan` | Admin SPPG | Daftar aduan unit, dengan filter `status` dan `id_sekolah`. |
| `GET` | `/api/admin/aduan/statistik` | Admin SPPG | Total per status dan rata-rata kepuasan. |
| `PUT` | `/api/admin/aduan/{id}/status` | Admin SPPG | Mengubah status aduan unit. |
| `POST` | `/api/admin/events/tiket` | Admin SPPG | Membuat tiket SSE terbatas untuk unit yang sedang dikelola. |
| `GET` | `/api/admin/events?tiket={tiket}` | Tiket SSE | Menerima notifikasi perubahan aduan secara real-time. |

Request aduan memakai `multipart/form-data` dengan field `id_unit_sppg`, `id_sekolah`, `id_menu_harian` opsional, `kategori`, `isi_aduan`, `nilai_kepuasan`, dan `file`. Backend memastikan unit, sekolah, dan menu saling berkaitan. Kategori yang diterima: `rasa`, `porsi`, `kebersihan`, `makanan_rusak`, `benda_asing`, `alergi`, dan `lainnya`.

Flutter Web meminta tiket SSE menggunakan Bearer token dan konteks unit aktif. Tiket acak berlaku 12 jam dan hanya menerima event dari unit tersebut. Ketika aduan baru masuk atau status berubah, backend mengirim event berisi jenis perubahan dan ID aduan; dashboard kemudian mengambil ulang data melalui endpoint admin biasa. Stream mengirim heartbeat setiap 15 detik dan klien mencoba terhubung kembali otomatis jika koneksi terputus.

## Smart Dinner

| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| `GET` | `/api/mobile/rekomendasi-makan-malam?id_sekolah={id}&tanggal={YYYY-MM-DD}` | Publik | Mengambil tiga rekomendasi yang paling mendekati kekurangan nutrisi. |

Backend menghitung selisih nutrisi menu makan siang terhadap target umum gabungan makan siang dan malam berdasarkan jenjang, lalu memberi skor pada 12 menu lokal. Target demonstrasi disederhanakan dengan rujukan AKG Permenkes Nomor 28 Tahun 2019. Hasil ini bersifat umum dan bukan diagnosis atau rekomendasi medis personal.
