ALTER TABLE media_menu
    DROP CHECK ck_media_menu,
    ADD CONSTRAINT ck_media_menu CHECK (
        (jenis_media = 'foto' AND ukuran_byte <= 31457280 AND durasi_detik IS NULL)
        OR (jenis_media = 'video' AND ukuran_byte <= 104857600 AND durasi_detik BETWEEN 1 AND 60)
    );

ALTER TABLE media_aduan
    DROP CHECK ck_media_aduan,
    ADD CONSTRAINT ck_media_aduan CHECK (
        (jenis_media = 'foto' AND ukuran_byte <= 31457280 AND durasi_detik IS NULL)
        OR (jenis_media = 'video' AND ukuran_byte <= 104857600 AND durasi_detik BETWEEN 1 AND 60)
    );
