INSERT INTO bahan_pangan (
    kode_tkpi, nama, kategori, energi_per_100g, protein_per_100g,
    lemak_per_100g, karbohidrat_per_100g, sumber_data, url_sumber,
    terverifikasi
) VALUES
('USDA-FDC-2514743', 'Daging sapi giling 90% tanpa lemak, mentah', 'Protein hewani', 185, 18.16, 12.85, 0, 'USDA FoodData Central - Foundation Foods', 'https://fdc.nal.usda.gov/food-details/2514743/nutrients', TRUE),
('USDA-FDC-2684445', 'Ikan lele budidaya, mentah', 'Protein hewani', 129, 16.47, 7.31, 0, 'USDA FoodData Central - Foundation Foods', 'https://fdc.nal.usda.gov/food-details/2684445/nutrients', TRUE),
('USDA-FDC-2684441', 'Ikan salmon Atlantik budidaya, mentah', 'Protein hewani', 197, 20.32, 13.11, 0, 'USDA FoodData Central - Foundation Foods', 'https://fdc.nal.usda.gov/food-details/2684441/nutrients', TRUE),
('USDA-FDC-2684442', 'Ikan nila budidaya, mentah', 'Protein hewani', 95, 19.00, 2.48, 0, 'USDA FoodData Central - Foundation Foods', 'https://fdc.nal.usda.gov/food-details/2684442/nutrients', TRUE);

INSERT INTO alergi_bahan_pangan (id_bahan_pangan, nama_alergi)
SELECT id, 'seafood'
FROM bahan_pangan
WHERE kode_tkpi IN ('USDA-FDC-2684445', 'USDA-FDC-2684441', 'USDA-FDC-2684442');

INSERT INTO template_menu (id_unit_sppg, nama, deskripsi, catatan_validasi) VALUES
(NULL, 'Nasi Sapi Brokoli', 'Nasi putih, daging sapi, brokoli, dan jeruk.', 'Referensi variasi protein hewani; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Merah Sapi Bayam', 'Nasi merah, daging sapi, bayam, dan pepaya.', 'Referensi variasi protein hewani; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Bento Sapi Wortel Telur', 'Nasi, daging sapi, telur, wortel, dan apel dalam susunan bento.', 'Referensi variasi protein hewani; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Ubi Sapi Brokoli Pepaya', 'Ubi rebus, daging sapi, brokoli, dan pepaya.', 'Referensi variasi protein hewani; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Rice Bowl Sapi Jagung', 'Nasi, daging sapi, jagung manis, dan jeruk.', 'Referensi variasi protein hewani; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Lele Bayam', 'Nasi, ikan lele, bayam, dan jeruk.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Lele Brokoli Jeruk', 'Nasi merah, ikan lele, brokoli, dan jeruk.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Ubi Lele Wortel Pepaya', 'Ubi rebus, ikan lele, wortel, dan pepaya.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Bento Lele Tahu', 'Nasi, ikan lele, tahu, brokoli, dan apel.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Jagung Lele Bayam', 'Jagung manis, ikan lele, bayam, dan pisang.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Salmon Brokoli', 'Nasi, ikan salmon, brokoli, dan jeruk.', 'Referensi variasi ikan; ketersediaan bahan, metode masak, dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Merah Salmon Bayam', 'Nasi merah, ikan salmon, bayam, dan pepaya.', 'Referensi variasi ikan; ketersediaan bahan, metode masak, dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Ubi Salmon Wortel', 'Ubi rebus, ikan salmon, wortel, dan apel.', 'Referensi variasi ikan; ketersediaan bahan, metode masak, dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Salmon Tahu Pelangi', 'Nasi, ikan salmon, tahu, brokoli, dan pepaya.', 'Referensi variasi ikan; ketersediaan bahan, metode masak, dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Bento Salmon Telur', 'Nasi, ikan salmon, telur, wortel, dan jeruk dalam susunan bento.', 'Referensi variasi ikan; ketersediaan bahan, metode masak, dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Nila Wortel', 'Nasi, ikan nila, wortel, dan jeruk.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Nasi Merah Nila Brokoli', 'Nasi merah, ikan nila, brokoli, dan pepaya.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Ubi Nila Bayam', 'Ubi rebus, ikan nila, bayam, dan apel.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Nila Tempe Pepaya', 'Nasi, ikan nila, tempe, bayam, dan pepaya.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.'),
(NULL, 'Jagung Nila Wortel', 'Jagung manis, ikan nila, wortel, dan pisang.', 'Referensi ikan budidaya; metode masak dan berat saji perlu divalidasi ahli gizi.');

INSERT INTO template_menu_bahan (id_template_menu, id_bahan_pangan, berat_gram, urutan)
SELECT t.id, b.id, x.berat_gram, x.urutan
FROM (
    SELECT 'Nasi Sapi Brokoli' AS template_nama, 'AP089' AS kode_tkpi, 140.00 AS berat_gram, 1 AS urutan
    UNION ALL SELECT 'Nasi Sapi Brokoli', 'USDA-FDC-2514743', 55.00, 2
    UNION ALL SELECT 'Nasi Sapi Brokoli', 'SIPERA-010', 50.00, 3
    UNION ALL SELECT 'Nasi Sapi Brokoli', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Nasi Merah Sapi Bayam', 'SIPERA-014', 160.00, 1
    UNION ALL SELECT 'Nasi Merah Sapi Bayam', 'USDA-FDC-2514743', 55.00, 2
    UNION ALL SELECT 'Nasi Merah Sapi Bayam', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Nasi Merah Sapi Bayam', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Bento Sapi Wortel Telur', 'AP089', 130.00, 1
    UNION ALL SELECT 'Bento Sapi Wortel Telur', 'USDA-FDC-2514743', 45.00, 2
    UNION ALL SELECT 'Bento Sapi Wortel Telur', 'HR002', 45.00, 3
    UNION ALL SELECT 'Bento Sapi Wortel Telur', 'DP060', 50.00, 4
    UNION ALL SELECT 'Bento Sapi Wortel Telur', 'SIPERA-004', 75.00, 5
    UNION ALL SELECT 'Ubi Sapi Brokoli Pepaya', 'SIPERA-016', 180.00, 1
    UNION ALL SELECT 'Ubi Sapi Brokoli Pepaya', 'USDA-FDC-2514743', 55.00, 2
    UNION ALL SELECT 'Ubi Sapi Brokoli Pepaya', 'SIPERA-010', 50.00, 3
    UNION ALL SELECT 'Ubi Sapi Brokoli Pepaya', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Rice Bowl Sapi Jagung', 'AP089', 130.00, 1
    UNION ALL SELECT 'Rice Bowl Sapi Jagung', 'USDA-FDC-2514743', 55.00, 2
    UNION ALL SELECT 'Rice Bowl Sapi Jagung', 'SIPERA-023', 60.00, 3
    UNION ALL SELECT 'Rice Bowl Sapi Jagung', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Nasi Lele Bayam', 'AP089', 140.00, 1
    UNION ALL SELECT 'Nasi Lele Bayam', 'USDA-FDC-2684445', 65.00, 2
    UNION ALL SELECT 'Nasi Lele Bayam', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Nasi Lele Bayam', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Lele Brokoli Jeruk', 'SIPERA-014', 160.00, 1
    UNION ALL SELECT 'Lele Brokoli Jeruk', 'USDA-FDC-2684445', 65.00, 2
    UNION ALL SELECT 'Lele Brokoli Jeruk', 'SIPERA-010', 50.00, 3
    UNION ALL SELECT 'Lele Brokoli Jeruk', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Ubi Lele Wortel Pepaya', 'SIPERA-016', 180.00, 1
    UNION ALL SELECT 'Ubi Lele Wortel Pepaya', 'USDA-FDC-2684445', 65.00, 2
    UNION ALL SELECT 'Ubi Lele Wortel Pepaya', 'DP060', 50.00, 3
    UNION ALL SELECT 'Ubi Lele Wortel Pepaya', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Bento Lele Tahu', 'AP089', 130.00, 1
    UNION ALL SELECT 'Bento Lele Tahu', 'USDA-FDC-2684445', 55.00, 2
    UNION ALL SELECT 'Bento Lele Tahu', 'CP061', 45.00, 3
    UNION ALL SELECT 'Bento Lele Tahu', 'SIPERA-010', 50.00, 4
    UNION ALL SELECT 'Bento Lele Tahu', 'SIPERA-004', 75.00, 5
    UNION ALL SELECT 'Jagung Lele Bayam', 'SIPERA-023', 150.00, 1
    UNION ALL SELECT 'Jagung Lele Bayam', 'USDA-FDC-2684445', 65.00, 2
    UNION ALL SELECT 'Jagung Lele Bayam', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Jagung Lele Bayam', 'ER065', 75.00, 4
    UNION ALL SELECT 'Nasi Salmon Brokoli', 'AP089', 140.00, 1
    UNION ALL SELECT 'Nasi Salmon Brokoli', 'USDA-FDC-2684441', 55.00, 2
    UNION ALL SELECT 'Nasi Salmon Brokoli', 'SIPERA-010', 50.00, 3
    UNION ALL SELECT 'Nasi Salmon Brokoli', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Nasi Merah Salmon Bayam', 'SIPERA-014', 160.00, 1
    UNION ALL SELECT 'Nasi Merah Salmon Bayam', 'USDA-FDC-2684441', 55.00, 2
    UNION ALL SELECT 'Nasi Merah Salmon Bayam', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Nasi Merah Salmon Bayam', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Ubi Salmon Wortel', 'SIPERA-016', 180.00, 1
    UNION ALL SELECT 'Ubi Salmon Wortel', 'USDA-FDC-2684441', 55.00, 2
    UNION ALL SELECT 'Ubi Salmon Wortel', 'DP060', 50.00, 3
    UNION ALL SELECT 'Ubi Salmon Wortel', 'SIPERA-004', 75.00, 4
    UNION ALL SELECT 'Salmon Tahu Pelangi', 'AP089', 130.00, 1
    UNION ALL SELECT 'Salmon Tahu Pelangi', 'USDA-FDC-2684441', 50.00, 2
    UNION ALL SELECT 'Salmon Tahu Pelangi', 'CP061', 45.00, 3
    UNION ALL SELECT 'Salmon Tahu Pelangi', 'SIPERA-010', 50.00, 4
    UNION ALL SELECT 'Salmon Tahu Pelangi', 'SIPERA-007', 80.00, 5
    UNION ALL SELECT 'Bento Salmon Telur', 'AP089', 130.00, 1
    UNION ALL SELECT 'Bento Salmon Telur', 'USDA-FDC-2684441', 45.00, 2
    UNION ALL SELECT 'Bento Salmon Telur', 'HR002', 45.00, 3
    UNION ALL SELECT 'Bento Salmon Telur', 'DP060', 50.00, 4
    UNION ALL SELECT 'Bento Salmon Telur', 'SIPERA-005', 80.00, 5
    UNION ALL SELECT 'Nasi Nila Wortel', 'AP089', 140.00, 1
    UNION ALL SELECT 'Nasi Nila Wortel', 'USDA-FDC-2684442', 65.00, 2
    UNION ALL SELECT 'Nasi Nila Wortel', 'DP060', 50.00, 3
    UNION ALL SELECT 'Nasi Nila Wortel', 'SIPERA-005', 80.00, 4
    UNION ALL SELECT 'Nasi Merah Nila Brokoli', 'SIPERA-014', 160.00, 1
    UNION ALL SELECT 'Nasi Merah Nila Brokoli', 'USDA-FDC-2684442', 65.00, 2
    UNION ALL SELECT 'Nasi Merah Nila Brokoli', 'SIPERA-010', 50.00, 3
    UNION ALL SELECT 'Nasi Merah Nila Brokoli', 'SIPERA-007', 80.00, 4
    UNION ALL SELECT 'Ubi Nila Bayam', 'SIPERA-016', 180.00, 1
    UNION ALL SELECT 'Ubi Nila Bayam', 'USDA-FDC-2684442', 65.00, 2
    UNION ALL SELECT 'Ubi Nila Bayam', 'SIPERA-009', 50.00, 3
    UNION ALL SELECT 'Ubi Nila Bayam', 'SIPERA-004', 75.00, 4
    UNION ALL SELECT 'Nila Tempe Pepaya', 'AP089', 130.00, 1
    UNION ALL SELECT 'Nila Tempe Pepaya', 'USDA-FDC-2684442', 55.00, 2
    UNION ALL SELECT 'Nila Tempe Pepaya', 'CP077', 35.00, 3
    UNION ALL SELECT 'Nila Tempe Pepaya', 'SIPERA-009', 50.00, 4
    UNION ALL SELECT 'Nila Tempe Pepaya', 'SIPERA-007', 80.00, 5
    UNION ALL SELECT 'Jagung Nila Wortel', 'SIPERA-023', 150.00, 1
    UNION ALL SELECT 'Jagung Nila Wortel', 'USDA-FDC-2684442', 65.00, 2
    UNION ALL SELECT 'Jagung Nila Wortel', 'DP060', 50.00, 3
    UNION ALL SELECT 'Jagung Nila Wortel', 'ER065', 75.00, 4
) x
INNER JOIN template_menu t ON t.nama = x.template_nama AND t.id_unit_sppg IS NULL
INNER JOIN bahan_pangan b ON b.kode_tkpi = x.kode_tkpi;
