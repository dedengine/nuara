CREATE TABLE unit_sppg (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    kode VARCHAR(30) NOT NULL,
    nama VARCHAR(150) NOT NULL,
    provinsi VARCHAR(100) NOT NULL,
    kabupaten_kota VARCHAR(100) NOT NULL,
    kecamatan VARCHAR(100) NOT NULL,
    kelurahan_desa VARCHAR(100) NOT NULL,
    kode_pos VARCHAR(10) NOT NULL,
    rt VARCHAR(3) NOT NULL,
    rw VARCHAR(3) NOT NULL,
    alamat_detail TEXT NOT NULL,
    nomor_telepon VARCHAR(20) NULL,
    aktif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_unit_sppg_kode (kode),
    KEY idx_unit_sppg_wilayah (provinsi, kabupaten_kota, kecamatan),
    KEY idx_unit_sppg_aktif (aktif)
) ENGINE=InnoDB;

CREATE TABLE admin (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_unit_sppg BIGINT UNSIGNED NULL,
    nama VARCHAR(150) NOT NULL,
    email VARCHAR(190) NOT NULL,
    password VARCHAR(255) NOT NULL,
    peran ENUM('super_admin', 'admin_sppg') NOT NULL,
    aktif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_admin_email (email),
    UNIQUE KEY uk_admin_unit_sppg (id_unit_sppg),
    CONSTRAINT fk_admin_unit_sppg
        FOREIGN KEY (id_unit_sppg) REFERENCES unit_sppg (id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE sekolah (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_unit_sppg BIGINT UNSIGNED NOT NULL,
    nama VARCHAR(180) NOT NULL,
    jenjang ENUM('SD', 'SMP', 'SMA', 'SMK', 'SLB', 'LAINNYA') NOT NULL,
    provinsi VARCHAR(100) NOT NULL,
    kabupaten_kota VARCHAR(100) NOT NULL,
    kecamatan VARCHAR(100) NOT NULL,
    kelurahan_desa VARCHAR(100) NOT NULL,
    kode_pos VARCHAR(10) NOT NULL,
    rt VARCHAR(3) NOT NULL,
    rw VARCHAR(3) NOT NULL,
    alamat_detail TEXT NOT NULL,
    aktif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_sekolah_unit_nama (id_unit_sppg, nama),
    UNIQUE KEY uk_sekolah_id_unit (id, id_unit_sppg),
    KEY idx_sekolah_wilayah (provinsi, kabupaten_kota, kecamatan),
    KEY idx_sekolah_unit_aktif (id_unit_sppg, aktif),
    CONSTRAINT fk_sekolah_unit_sppg
        FOREIGN KEY (id_unit_sppg) REFERENCES unit_sppg (id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE menu_harian (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_unit_sppg BIGINT UNSIGNED NOT NULL,
    id_sekolah BIGINT UNSIGNED NULL,
    tanggal_menu DATE NOT NULL,
    nama_menu VARCHAR(180) NOT NULL,
    deskripsi TEXT NOT NULL,
    kalori SMALLINT UNSIGNED NOT NULL,
    protein DECIMAL(7,2) UNSIGNED NOT NULL,
    lemak DECIMAL(7,2) UNSIGNED NOT NULL,
    karbohidrat DECIMAL(7,2) UNSIGNED NOT NULL,
    sumber_data_gizi VARCHAR(180) NOT NULL,
    url_sumber_data_gizi VARCHAR(1000) NOT NULL,
    status ENUM('draf', 'dipublikasikan') NOT NULL DEFAULT 'draf',
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_menu_id_unit (id, id_unit_sppg),
    KEY idx_menu_unit_tanggal (id_unit_sppg, tanggal_menu),
    KEY idx_menu_sekolah_tanggal (id_sekolah, tanggal_menu),
    CONSTRAINT ck_menu_nutrisi CHECK (
        kalori > 0 AND protein >= 0 AND lemak >= 0 AND karbohidrat >= 0
    ),
    CONSTRAINT fk_menu_unit_sppg
        FOREIGN KEY (id_unit_sppg) REFERENCES unit_sppg (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_menu_sekolah_dalam_unit
        FOREIGN KEY (id_sekolah, id_unit_sppg) REFERENCES sekolah (id, id_unit_sppg)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE komponen_menu (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_menu_harian BIGINT UNSIGNED NOT NULL,
    nama_komponen VARCHAR(150) NOT NULL,
    keterangan_porsi VARCHAR(100) NULL,
    urutan TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_komponen_menu_nama (id_menu_harian, nama_komponen),
    CONSTRAINT fk_komponen_menu_harian
        FOREIGN KEY (id_menu_harian) REFERENCES menu_harian (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE alergen_menu (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_menu_harian BIGINT UNSIGNED NOT NULL,
    nama_alergen ENUM('telur', 'susu', 'kacang', 'seafood', 'gluten', 'kedelai', 'lainnya') NOT NULL,
    keterangan VARCHAR(255) NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_alergen_menu (id_menu_harian, nama_alergen),
    CONSTRAINT fk_alergen_menu_harian
        FOREIGN KEY (id_menu_harian) REFERENCES menu_harian (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE media_menu (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_menu_harian BIGINT UNSIGNED NOT NULL,
    jenis_media ENUM('foto', 'video') NOT NULL,
    url_berkas VARCHAR(1000) NOT NULL,
    nama_berkas VARCHAR(255) NOT NULL,
    ukuran_byte BIGINT UNSIGNED NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    durasi_detik SMALLINT UNSIGNED NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_media_menu (id_menu_harian, jenis_media),
    CONSTRAINT ck_media_menu CHECK (
        (jenis_media = 'foto' AND ukuran_byte <= 31457280 AND durasi_detik IS NULL)
        OR (jenis_media = 'video' AND ukuran_byte <= 104857600 AND durasi_detik BETWEEN 1 AND 30)
    ),
    CONSTRAINT fk_media_menu_harian
        FOREIGN KEY (id_menu_harian) REFERENCES menu_harian (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE aduan (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_unit_sppg BIGINT UNSIGNED NOT NULL,
    id_sekolah BIGINT UNSIGNED NOT NULL,
    id_menu_harian BIGINT UNSIGNED NULL,
    kategori ENUM('rasa', 'porsi', 'kebersihan', 'makanan_rusak', 'benda_asing', 'alergen', 'lainnya') NOT NULL,
    isi_aduan TEXT NOT NULL,
    nilai_kepuasan TINYINT UNSIGNED NOT NULL,
    status ENUM('baru', 'diproses', 'selesai', 'ditolak') NOT NULL DEFAULT 'baru',
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_aduan_unit_status_tanggal (id_unit_sppg, status, created_at),
    KEY idx_aduan_sekolah_tanggal (id_sekolah, created_at),
    KEY idx_aduan_menu (id_menu_harian),
    CONSTRAINT ck_aduan_kepuasan CHECK (nilai_kepuasan BETWEEN 1 AND 5),
    CONSTRAINT ck_aduan_isi CHECK (CHAR_LENGTH(TRIM(isi_aduan)) >= 10),
    CONSTRAINT fk_aduan_unit_sppg
        FOREIGN KEY (id_unit_sppg) REFERENCES unit_sppg (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aduan_sekolah_dalam_unit
        FOREIGN KEY (id_sekolah, id_unit_sppg) REFERENCES sekolah (id, id_unit_sppg)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aduan_menu_dalam_unit
        FOREIGN KEY (id_menu_harian, id_unit_sppg) REFERENCES menu_harian (id, id_unit_sppg)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE media_aduan (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_aduan BIGINT UNSIGNED NOT NULL,
    jenis_media ENUM('foto', 'video') NOT NULL,
    url_berkas VARCHAR(1000) NOT NULL,
    nama_berkas VARCHAR(255) NOT NULL,
    ukuran_byte BIGINT UNSIGNED NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    durasi_detik SMALLINT UNSIGNED NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_media_aduan (id_aduan, jenis_media),
    CONSTRAINT ck_media_aduan CHECK (
        (jenis_media = 'foto' AND ukuran_byte <= 31457280 AND durasi_detik IS NULL)
        OR (jenis_media = 'video' AND ukuran_byte <= 104857600 AND durasi_detik BETWEEN 1 AND 30)
    ),
    CONSTRAINT fk_media_aduan
        FOREIGN KEY (id_aduan) REFERENCES aduan (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE rekomendasi_makan_malam (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nama_menu VARCHAR(180) NOT NULL,
    deskripsi TEXT NOT NULL,
    fokus_nutrisi VARCHAR(255) NOT NULL,
    kalori SMALLINT UNSIGNED NOT NULL,
    protein DECIMAL(7,2) UNSIGNED NOT NULL,
    lemak DECIMAL(7,2) UNSIGNED NOT NULL,
    karbohidrat DECIMAL(7,2) UNSIGNED NOT NULL,
    serat DECIMAL(7,2) UNSIGNED NOT NULL DEFAULT 0,
    sumber_data_gizi VARCHAR(180) NOT NULL,
    url_sumber_data_gizi VARCHAR(1000) NOT NULL,
    aktif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_rekomendasi_nama (nama_menu),
    KEY idx_rekomendasi_aktif (aktif),
    CONSTRAINT ck_rekomendasi_nutrisi CHECK (
        kalori > 0 AND protein >= 0 AND lemak >= 0 AND karbohidrat >= 0 AND serat >= 0
    )
) ENGINE=InnoDB;
