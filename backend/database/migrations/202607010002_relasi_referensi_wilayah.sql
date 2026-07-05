ALTER TABLE referensi_wilayah
    MODIFY COLUMN kode_induk VARCHAR(13) NULL,
    ADD CONSTRAINT fk_referensi_wilayah_induk
        FOREIGN KEY (kode_induk) REFERENCES referensi_wilayah (kode)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE unit_sppg
    MODIFY COLUMN kode_provinsi VARCHAR(13) NULL,
    MODIFY COLUMN kode_kabupaten_kota VARCHAR(13) NULL,
    MODIFY COLUMN kode_kecamatan VARCHAR(13) NULL,
    MODIFY COLUMN kode_kelurahan_desa VARCHAR(13) NULL,
    ADD KEY idx_unit_sppg_kode_provinsi (kode_provinsi),
    ADD KEY idx_unit_sppg_kode_kabupaten_kota (kode_kabupaten_kota),
    ADD KEY idx_unit_sppg_kode_kecamatan (kode_kecamatan),
    ADD KEY idx_unit_sppg_kode_kelurahan_desa (kode_kelurahan_desa),
    ADD CONSTRAINT fk_unit_sppg_referensi_provinsi
        FOREIGN KEY (kode_provinsi) REFERENCES referensi_wilayah (kode)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_unit_sppg_referensi_kabupaten_kota
        FOREIGN KEY (kode_kabupaten_kota) REFERENCES referensi_wilayah (kode)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_unit_sppg_referensi_kecamatan
        FOREIGN KEY (kode_kecamatan) REFERENCES referensi_wilayah (kode)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_unit_sppg_referensi_kelurahan_desa
        FOREIGN KEY (kode_kelurahan_desa) REFERENCES referensi_wilayah (kode)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE urutan_kode_sppg
    ADD CONSTRAINT fk_urutan_kode_sppg_kelurahan_desa
        FOREIGN KEY (kode_kelurahan_desa) REFERENCES referensi_wilayah (kode)
        ON UPDATE CASCADE ON DELETE RESTRICT;
