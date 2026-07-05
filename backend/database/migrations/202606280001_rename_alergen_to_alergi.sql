CREATE TABLE alergi_menu (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_menu_harian BIGINT UNSIGNED NOT NULL,
    nama_alergi ENUM('telur', 'susu', 'kacang', 'seafood', 'gluten', 'kedelai', 'lainnya') NOT NULL,
    keterangan VARCHAR(255) NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_alergi_menu (id_menu_harian, nama_alergi),
    CONSTRAINT fk_alergi_menu_harian
        FOREIGN KEY (id_menu_harian) REFERENCES menu_harian (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO alergi_menu (
    id,
    id_menu_harian,
    nama_alergi,
    keterangan,
    created_at
)
SELECT
    id,
    id_menu_harian,
    nama_alergen,
    keterangan,
    created_at
FROM alergen_menu;

ALTER TABLE aduan
    MODIFY COLUMN kategori
        ENUM(
            'rasa',
            'porsi',
            'kebersihan',
            'makanan_rusak',
            'benda_asing',
            'alergen',
            'alergi',
            'lainnya'
        ) NOT NULL;

UPDATE aduan SET kategori = 'alergi' WHERE kategori = 'alergen';

ALTER TABLE aduan
    MODIFY COLUMN kategori
        ENUM(
            'rasa',
            'porsi',
            'kebersihan',
            'makanan_rusak',
            'benda_asing',
            'alergi',
            'lainnya'
        ) NOT NULL;
