CREATE TABLE urutan_kode_sppg (
    kode_kelurahan_desa VARCHAR(13) NOT NULL,
    nomor_terakhir INT UNSIGNED NOT NULL DEFAULT 0,
    update_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (kode_kelurahan_desa)
) ENGINE=InnoDB;

INSERT INTO urutan_kode_sppg (kode_kelurahan_desa, nomor_terakhir)
SELECT kode_kelurahan_desa, COUNT(*)
FROM unit_sppg
WHERE kode_kelurahan_desa IS NOT NULL
GROUP BY kode_kelurahan_desa;
