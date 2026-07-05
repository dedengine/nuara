CREATE TABLE bahan_pangan (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    kode_tkpi VARCHAR(20) NOT NULL,
    nama VARCHAR(180) NOT NULL,
    kategori VARCHAR(80) NOT NULL,
    energi_per_100g DECIMAL(8,2) UNSIGNED NOT NULL,
    protein_per_100g DECIMAL(8,2) UNSIGNED NOT NULL,
    lemak_per_100g DECIMAL(8,2) UNSIGNED NOT NULL,
    karbohidrat_per_100g DECIMAL(8,2) UNSIGNED NOT NULL,
    sumber_data VARCHAR(180) NOT NULL,
    url_sumber VARCHAR(1000) NOT NULL,
    terverifikasi BOOLEAN NOT NULL DEFAULT FALSE,
    aktif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_bahan_pangan_kode_tkpi (kode_tkpi),
    KEY idx_bahan_pangan_nama (nama),
    KEY idx_bahan_pangan_aktif (aktif)
) ENGINE=InnoDB;

CREATE TABLE alergi_bahan_pangan (
    id_bahan_pangan BIGINT UNSIGNED NOT NULL,
    nama_alergi ENUM('telur', 'susu', 'kacang', 'seafood', 'gluten', 'kedelai', 'lainnya') NOT NULL,
    PRIMARY KEY (id_bahan_pangan, nama_alergi),
    CONSTRAINT fk_alergi_bahan_pangan
        FOREIGN KEY (id_bahan_pangan) REFERENCES bahan_pangan (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE template_menu (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_unit_sppg BIGINT UNSIGNED NULL,
    nama VARCHAR(180) NOT NULL,
    deskripsi TEXT NOT NULL,
    catatan_validasi VARCHAR(255) NOT NULL,
    aktif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_template_menu_unit (id_unit_sppg, aktif),
    CONSTRAINT fk_template_menu_unit
        FOREIGN KEY (id_unit_sppg) REFERENCES unit_sppg (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE template_menu_bahan (
    id_template_menu BIGINT UNSIGNED NOT NULL,
    id_bahan_pangan BIGINT UNSIGNED NOT NULL,
    berat_gram DECIMAL(8,2) UNSIGNED NOT NULL,
    urutan TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (id_template_menu, id_bahan_pangan),
    KEY idx_template_menu_bahan_urutan (id_template_menu, urutan),
    CONSTRAINT fk_template_menu_bahan_template
        FOREIGN KEY (id_template_menu) REFERENCES template_menu (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_template_menu_bahan_pangan
        FOREIGN KEY (id_bahan_pangan) REFERENCES bahan_pangan (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_template_menu_bahan_berat CHECK (berat_gram > 0 AND berat_gram <= 2000)
) ENGINE=InnoDB;

ALTER TABLE komponen_menu
    ADD COLUMN id_bahan_pangan BIGINT UNSIGNED NULL AFTER id_menu_harian,
    ADD COLUMN berat_gram DECIMAL(8,2) UNSIGNED NULL AFTER keterangan_porsi,
    ADD KEY idx_komponen_menu_bahan (id_bahan_pangan),
    ADD CONSTRAINT fk_komponen_menu_bahan
        FOREIGN KEY (id_bahan_pangan) REFERENCES bahan_pangan (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT ck_komponen_menu_berat
        CHECK (berat_gram IS NULL OR (berat_gram > 0 AND berat_gram <= 2000));

INSERT INTO bahan_pangan (
    kode_tkpi, nama, kategori, energi_per_100g, protein_per_100g,
    lemak_per_100g, karbohidrat_per_100g, sumber_data, url_sumber,
    terverifikasi
) VALUES
('AP089', 'Nasi putih', 'Makanan pokok', 180, 3.0, 0.3, 39.8, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE),
('CP077', 'Tempe kedelai murni, mentah', 'Protein nabati', 201, 20.8, 8.8, 13.5, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE),
('CP061', 'Tahu, mentah', 'Protein nabati', 80, 10.9, 4.7, 0.8, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE),
('FR004', 'Ayam, daging, segar', 'Protein hewani', 298, 18.2, 25.0, 0.0, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE),
('HR002', 'Telur ayam ras, segar', 'Protein hewani', 154, 12.4, 10.8, 0.7, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE),
('DP060', 'Wortel', 'Sayuran', 45, 1.0, 0.6, 8.3, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE),
('ER065', 'Pisang mas bali, segar', 'Buah', 92, 1.4, 0.2, 21.0, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE),
('JR006', 'Susu sapi, segar', 'Susu', 61, 3.2, 3.5, 4.3, 'TKPI Kementerian Kesehatan RI 2020', 'https://repository.kemkes.go.id/book/668', TRUE);

INSERT INTO alergi_bahan_pangan (id_bahan_pangan, nama_alergi)
SELECT id, 'kedelai' FROM bahan_pangan WHERE kode_tkpi IN ('CP077', 'CP061');
INSERT INTO alergi_bahan_pangan (id_bahan_pangan, nama_alergi)
SELECT id, 'telur' FROM bahan_pangan WHERE kode_tkpi = 'HR002';
INSERT INTO alergi_bahan_pangan (id_bahan_pangan, nama_alergi)
SELECT id, 'susu' FROM bahan_pangan WHERE kode_tkpi = 'JR006';

INSERT INTO template_menu (id_unit_sppg, nama, deskripsi, catatan_validasi) VALUES
(NULL, 'Paket Ayam dan Wortel', 'Nasi putih, ayam, wortel, dan pisang.', 'Template awal berbasis TKPI; validasi ahli gizi tetap diperlukan.'),
(NULL, 'Paket Tempe Tahu', 'Nasi putih, tempe, tahu, wortel, dan pisang.', 'Template awal berbasis TKPI; validasi ahli gizi tetap diperlukan.'),
(NULL, 'Paket Telur Tempe dan Susu', 'Nasi putih, telur, tempe, wortel, dan susu.', 'Template awal berbasis TKPI; validasi ahli gizi tetap diperlukan.');

INSERT INTO template_menu_bahan (id_template_menu, id_bahan_pangan, berat_gram, urutan)
SELECT t.id, b.id, x.berat_gram, x.urutan
FROM (
    SELECT 'Paket Ayam dan Wortel' AS template_nama, 'AP089' AS kode_tkpi, 150.00 AS berat_gram, 1 AS urutan
    UNION ALL SELECT 'Paket Ayam dan Wortel', 'FR004', 60.00, 2
    UNION ALL SELECT 'Paket Ayam dan Wortel', 'DP060', 50.00, 3
    UNION ALL SELECT 'Paket Ayam dan Wortel', 'ER065', 75.00, 4
    UNION ALL SELECT 'Paket Tempe Tahu', 'AP089', 150.00, 1
    UNION ALL SELECT 'Paket Tempe Tahu', 'CP077', 50.00, 2
    UNION ALL SELECT 'Paket Tempe Tahu', 'CP061', 50.00, 3
    UNION ALL SELECT 'Paket Tempe Tahu', 'DP060', 50.00, 4
    UNION ALL SELECT 'Paket Tempe Tahu', 'ER065', 75.00, 5
    UNION ALL SELECT 'Paket Telur Tempe dan Susu', 'AP089', 150.00, 1
    UNION ALL SELECT 'Paket Telur Tempe dan Susu', 'HR002', 55.00, 2
    UNION ALL SELECT 'Paket Telur Tempe dan Susu', 'CP077', 35.00, 3
    UNION ALL SELECT 'Paket Telur Tempe dan Susu', 'DP060', 50.00, 4
    UNION ALL SELECT 'Paket Telur Tempe dan Susu', 'JR006', 150.00, 5
) x
INNER JOIN template_menu t ON t.nama = x.template_nama AND t.id_unit_sppg IS NULL
INNER JOIN bahan_pangan b ON b.kode_tkpi = x.kode_tkpi;
