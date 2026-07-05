INSERT INTO bahan_pangan (
    kode_tkpi, nama, kategori, energi_per_100g, protein_per_100g,
    lemak_per_100g, karbohidrat_per_100g, sumber_data, url_sumber,
    terverifikasi
) VALUES
('SIPERA-014', 'Beras merah, matang', 'Makanan pokok', 111, 2.6, 0.9, 22.8, 'SIPERA Kabupaten Ketapang - USDA', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('SIPERA-016', 'Ubi jalar, rebus', 'Makanan pokok', 76, 1.4, 0.1, 18.0, 'SIPERA Kabupaten Ketapang - USDA', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('SIPERA-023', 'Jagung manis, rebus', 'Makanan pokok', 96, 3.4, 1.3, 21.0, 'SIPERA Kabupaten Ketapang', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('SIPERA-009', 'Bayam, mentah', 'Sayuran', 23, 2.9, 0.4, 3.6, 'SIPERA Kabupaten Ketapang', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('SIPERA-010', 'Brokoli, mentah', 'Sayuran', 34, 2.8, 0.4, 6.6, 'SIPERA Kabupaten Ketapang', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('SIPERA-005', 'Jeruk manis', 'Buah', 45, 0.9, 0.2, 11.8, 'SIPERA Kabupaten Ketapang', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('SIPERA-007', 'Pepaya', 'Buah', 45, 0.5, 0.1, 11.8, 'SIPERA Kabupaten Ketapang', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('SIPERA-004', 'Apel dengan kulit', 'Buah', 52, 0.3, 0.2, 13.8, 'SIPERA Kabupaten Ketapang', 'https://sipera.ketapangkab.go.id/nutrisi-diet/zat-gizi', FALSE),
('TKPI-IKAN-KEMBUNG', 'Ikan kembung, segar', 'Protein hewani', 125, 21.3, 3.4, 2.2, 'TKPI Kementerian Kesehatan RI', 'https://repository.kemkes.go.id/book/668', FALSE);

INSERT INTO alergi_bahan_pangan (id_bahan_pangan, nama_alergi)
SELECT id, 'seafood' FROM bahan_pangan WHERE kode_tkpi = 'TKPI-IKAN-KEMBUNG';

INSERT INTO template_menu (id_unit_sppg, nama, deskripsi, catatan_validasi) VALUES
(NULL, 'Rice Bowl Ayam Bayam', 'Nasi, ayam rempah, bayam, dan jeruk dalam gaya rice bowl.', 'Referensi variasi sehat; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Ubi Bowl Ayam Brokoli', 'Ubi rebus, ayam panggang, brokoli, dan pepaya.', 'Referensi variasi sehat; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Ikan Kembung Pelangi', 'Nasi, ikan kembung, wortel, dan jeruk.', 'Referensi pangan lokal; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Jagung Bowl Ayam Bayam', 'Jagung manis, ayam, bayam, dan pepaya.', 'Referensi variasi sehat; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Bento Telur Tahu Brokoli', 'Nasi, telur, tahu, brokoli, dan apel dalam susunan bento.', 'Referensi variasi sehat; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Tempe Bayam Jeruk', 'Nasi, tempe, bayam, dan jeruk.', 'Referensi menu nabati; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Ubi Telur Tahu Pepaya', 'Ubi rebus, telur, tahu, dan pepaya.', 'Referensi variasi sehat; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Bowl Kembung Brokoli Pisang', 'Nasi, ikan kembung, brokoli, dan pisang.', 'Referensi pangan lokal; metode masak dan bumbu perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Merah Tempe Wortel Susu', 'Nasi merah, tempe, wortel, dan susu.', 'Referensi tinggi variasi pangan; validasi kelompok usia tetap diperlukan.');

INSERT INTO template_menu_bahan (id_template_menu, id_bahan_pangan, berat_gram, urutan)
SELECT t.id, b.id, x.berat_gram, x.urutan
FROM (
    SELECT 'Rice Bowl Ayam Bayam' AS template_nama, 'AP089' AS kode_tkpi, 140.00 AS berat_gram, 1 AS urutan
    UNION ALL SELECT 'Rice Bowl Ayam Bayam', 'FR004', 55.00, 2
    UNION ALL SELECT 'Rice Bowl Ayam Bayam', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Rice Bowl Ayam Bayam', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Ubi Bowl Ayam Brokoli', 'SIPERA-016', 180.00, 1
    UNION ALL SELECT 'Ubi Bowl Ayam Brokoli', 'FR004', 50.00, 2
    UNION ALL SELECT 'Ubi Bowl Ayam Brokoli', 'SIPERA-010', 50.00, 3
    UNION ALL SELECT 'Ubi Bowl Ayam Brokoli', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Nasi Ikan Kembung Pelangi', 'AP089', 140.00, 1
    UNION ALL SELECT 'Nasi Ikan Kembung Pelangi', 'TKPI-IKAN-KEMBUNG', 65.00, 2
    UNION ALL SELECT 'Nasi Ikan Kembung Pelangi', 'DP060', 50.00, 3
    UNION ALL SELECT 'Nasi Ikan Kembung Pelangi', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Jagung Bowl Ayam Bayam', 'SIPERA-023', 150.00, 1
    UNION ALL SELECT 'Jagung Bowl Ayam Bayam', 'FR004', 55.00, 2
    UNION ALL SELECT 'Jagung Bowl Ayam Bayam', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Jagung Bowl Ayam Bayam', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Bento Telur Tahu Brokoli', 'AP089', 140.00, 1
    UNION ALL SELECT 'Bento Telur Tahu Brokoli', 'HR002', 55.00, 2
    UNION ALL SELECT 'Bento Telur Tahu Brokoli', 'CP061', 60.00, 3
    UNION ALL SELECT 'Bento Telur Tahu Brokoli', 'SIPERA-010', 50.00, 4
    UNION ALL SELECT 'Bento Telur Tahu Brokoli', 'SIPERA-004', 75.00, 5
    UNION ALL SELECT 'Nasi Tempe Bayam Jeruk', 'AP089', 140.00, 1
    UNION ALL SELECT 'Nasi Tempe Bayam Jeruk', 'CP077', 60.00, 2
    UNION ALL SELECT 'Nasi Tempe Bayam Jeruk', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Nasi Tempe Bayam Jeruk', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Ubi Telur Tahu Pepaya', 'SIPERA-016', 180.00, 1
    UNION ALL SELECT 'Ubi Telur Tahu Pepaya', 'HR002', 55.00, 2
    UNION ALL SELECT 'Ubi Telur Tahu Pepaya', 'CP061', 50.00, 3
    UNION ALL SELECT 'Ubi Telur Tahu Pepaya', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Bowl Kembung Brokoli Pisang', 'AP089', 140.00, 1
    UNION ALL SELECT 'Bowl Kembung Brokoli Pisang', 'TKPI-IKAN-KEMBUNG', 65.00, 2
    UNION ALL SELECT 'Bowl Kembung Brokoli Pisang', 'SIPERA-010', 50.00, 3
    UNION ALL SELECT 'Bowl Kembung Brokoli Pisang', 'ER065', 75.00, 4
    UNION ALL SELECT 'Nasi Merah Tempe Wortel Susu', 'SIPERA-014', 160.00, 1
    UNION ALL SELECT 'Nasi Merah Tempe Wortel Susu', 'CP077', 50.00, 2
    UNION ALL SELECT 'Nasi Merah Tempe Wortel Susu', 'DP060', 50.00, 3
    UNION ALL SELECT 'Nasi Merah Tempe Wortel Susu', 'JR006', 150.00, 4
) x
INNER JOIN template_menu t ON t.nama = x.template_nama AND t.id_unit_sppg IS NULL
INNER JOIN bahan_pangan b ON b.kode_tkpi = x.kode_tkpi;
