ALTER TABLE menu_harian
    ADD COLUMN aktif BOOLEAN NOT NULL DEFAULT TRUE AFTER status,
    ADD COLUMN kunci_cakupan BIGINT UNSIGNED NOT NULL DEFAULT 0 AFTER id_sekolah,
    ADD UNIQUE KEY uk_menu_cakupan_tanggal (
        id_unit_sppg,
        tanggal_menu,
        kunci_cakupan
    ),
    ADD KEY idx_menu_publik (
        id_unit_sppg,
        tanggal_menu,
        status,
        aktif
    );
