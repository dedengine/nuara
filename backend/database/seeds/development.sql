SET @awal_minggu = DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY);

INSERT INTO unit_sppg (
    id, kode, nama, provinsi, kabupaten_kota, kecamatan, kelurahan_desa,
    kode_pos, rt, rw, alamat_detail, nomor_telepon, aktif
) VALUES (
    1, 'SPPG-DPK-SMJ-001', 'SPPG Mekarjaya', 'Jawa Barat', 'Kota Depok',
    'Sukmajaya', 'Mekarjaya', '16411', '03', '05',
    'Jalan Nusantara No. 18', '021-77881234', TRUE
);

INSERT INTO admin (id, id_unit_sppg, nama, email, password, peran, aktif) VALUES
    (1, NULL, 'Nuara Super Admin', 'superadmin@nuara.test', '$argon2id$v=19$m=65536,t=4,p=1$Q3NpLklPamtaYWlTaDROWA$uorY0UdYBiVE1S5njXCswwNtWtHOPfW76RGeBeomtRc', 'super_admin', TRUE),
    (2, 1, 'Nuara Admin', 'admin@nuara.test', '$argon2id$v=19$m=65536,t=4,p=1$Q3NpLklPamtaYWlTaDROWA$uorY0UdYBiVE1S5njXCswwNtWtHOPfW76RGeBeomtRc', 'admin_sppg', TRUE);

INSERT INTO sekolah (
    id, id_unit_sppg, nama, jenjang, provinsi, kabupaten_kota, kecamatan,
    kelurahan_desa, kode_pos, rt, rw, alamat_detail, aktif
) VALUES
    (1, 1, 'SD Nusantara Mekarjaya 01', 'SD', 'Jawa Barat', 'Kota Depok', 'Sukmajaya', 'Mekarjaya', '16411', '02', '04', 'Jalan Merdeka Pendidikan No. 7', TRUE),
    (2, 1, 'SD Nusantara Mekarjaya 02', 'SD', 'Jawa Barat', 'Kota Depok', 'Sukmajaya', 'Mekarjaya', '16411', '06', '03', 'Jalan Tunas Bangsa No. 12', TRUE),
    (3, 1, 'SMP Harapan Sukmajaya', 'SMP', 'Jawa Barat', 'Kota Depok', 'Sukmajaya', 'Abadijaya', '16417', '01', '08', 'Jalan Pendidikan Raya No. 25', TRUE);

INSERT INTO menu_harian (
    id, id_unit_sppg, id_sekolah, tanggal_menu, nama_menu, deskripsi,
    kalori, protein, lemak, karbohidrat, sumber_data_gizi,
    url_sumber_data_gizi, status
) VALUES
    (1, 1, NULL, DATE_ADD(@awal_minggu, INTERVAL 0 DAY), 'Paket Ayam Semur', 'Nasi, ayam semur, tempe orek, sayur bening bayam, dan jeruk.', 635, 31.40, 18.20, 87.50, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/', 'dipublikasikan'),
    (2, 1, NULL, DATE_ADD(@awal_minggu, INTERVAL 1 DAY), 'Paket Ikan Kembung', 'Nasi, ikan kembung panggang, tahu kukus, tumis buncis wortel, dan pepaya.', 610, 34.80, 16.40, 80.20, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/', 'dipublikasikan'),
    (3, 1, NULL, DATE_ADD(@awal_minggu, INTERVAL 2 DAY), 'Paket Telur dan Ayam Suwir', 'Nasi, telur dadar sayur, ayam suwir, sup wortel kentang, dan pisang.', 650, 33.10, 19.60, 88.40, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/', 'dipublikasikan'),
    (4, 1, NULL, DATE_ADD(@awal_minggu, INTERVAL 3 DAY), 'Paket Ikan Nila', 'Nasi, ikan nila bakar, tempe panggang, sayur sop, dan semangka.', 605, 35.20, 15.80, 81.60, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/', 'dipublikasikan'),
    (5, 1, NULL, DATE_ADD(@awal_minggu, INTERVAL 4 DAY), 'Paket Ayam Kecap', 'Nasi, ayam kecap tanpa kulit, tahu isi sayur panggang, tumis kangkung, dan melon.', 625, 32.60, 17.10, 85.30, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/', 'dipublikasikan'),
    (6, 1, NULL, DATE_ADD(@awal_minggu, INTERVAL 5 DAY), 'Paket Bandeng Presto', 'Nasi, ikan bandeng presto, telur rebus, sayur bening jagung, dan pepaya.', 670, 36.40, 21.20, 83.70, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/', 'dipublikasikan'),
    (7, 1, NULL, DATE_ADD(@awal_minggu, INTERVAL 6 DAY), 'Paket Ayam Panggang', 'Nasi, ayam panggang, tempe kukus, capcay sayur, dan pisang.', 640, 35.00, 17.50, 86.10, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/', 'dipublikasikan');

INSERT INTO komponen_menu (id_menu_harian, nama_komponen, urutan) VALUES
    (1, 'Nasi', 1), (1, 'Ayam semur', 2), (1, 'Tempe orek', 3), (1, 'Sayur bening bayam', 4), (1, 'Jeruk', 5),
    (2, 'Nasi', 1), (2, 'Ikan kembung panggang', 2), (2, 'Tahu kukus', 3), (2, 'Tumis buncis wortel', 4), (2, 'Pepaya', 5),
    (3, 'Nasi', 1), (3, 'Telur dadar sayur', 2), (3, 'Ayam suwir', 3), (3, 'Sup wortel kentang', 4), (3, 'Pisang', 5),
    (4, 'Nasi', 1), (4, 'Ikan nila bakar', 2), (4, 'Tempe panggang', 3), (4, 'Sayur sop', 4), (4, 'Semangka', 5),
    (5, 'Nasi', 1), (5, 'Ayam kecap tanpa kulit', 2), (5, 'Tahu isi sayur panggang', 3), (5, 'Tumis kangkung', 4), (5, 'Melon', 5),
    (6, 'Nasi', 1), (6, 'Ikan bandeng presto', 2), (6, 'Telur rebus', 3), (6, 'Sayur bening jagung', 4), (6, 'Pepaya', 5),
    (7, 'Nasi', 1), (7, 'Ayam panggang', 2), (7, 'Tempe kukus', 3), (7, 'Capcay sayur', 4), (7, 'Pisang', 5);

INSERT INTO alergi_menu (id_menu_harian, nama_alergi) VALUES
    (1, 'kedelai'),
    (2, 'seafood'), (2, 'kedelai'),
    (3, 'telur'),
    (4, 'seafood'), (4, 'kedelai'),
    (5, 'kedelai'), (5, 'gluten'),
    (6, 'seafood'), (6, 'telur'),
    (7, 'kedelai');

INSERT INTO rekomendasi_makan_malam (
    id, nama_menu, deskripsi, fokus_nutrisi, kalori, protein, lemak,
    karbohidrat, serat, sumber_data_gizi, url_sumber_data_gizi
) VALUES
    (1, 'Ikan Kembung dan Bayam', 'Nasi, ikan kembung panggang, sayur bening bayam, dan pepaya.', 'Protein, zat besi, dan serat', 540, 29.50, 14.20, 73.00, 8.20, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (2, 'Ayam Panggang dan Buncis', 'Nasi, ayam panggang, tumis buncis wortel, dan jeruk.', 'Protein, vitamin, dan serat', 525, 31.00, 12.50, 71.50, 7.80, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (3, 'Telur Sayur dan Tempe', 'Nasi, telur dadar sayur, tempe kukus, dan sup sayur.', 'Protein dan karbohidrat', 560, 26.80, 17.00, 74.20, 8.00, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (4, 'Ubi dan Tongkol Suwir', 'Ubi kukus, ikan tongkol suwir, sayur bening, dan pisang.', 'Karbohidrat, protein, dan serat', 495, 27.40, 10.20, 73.80, 9.10, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (5, 'Tahu Tempe dan Capcay', 'Nasi, tahu dan tempe panggang, capcay sayur, dan melon.', 'Protein nabati dan serat', 515, 23.60, 15.50, 73.10, 10.40, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (6, 'Ikan Nila dan Kangkung', 'Nasi, ikan nila bakar, tumis kangkung, dan semangka.', 'Protein dan serat', 500, 30.20, 11.80, 69.00, 7.40, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (7, 'Kentang Telur dan Sup', 'Kentang rebus, telur rebus, sup wortel buncis, dan pepaya.', 'Protein, karbohidrat, dan vitamin', 470, 20.50, 13.40, 67.30, 9.60, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (8, 'Ayam Semur dan Sayur Sop', 'Nasi, ayam semur tanpa kulit, sayur sop, dan pisang.', 'Protein dan energi', 550, 29.80, 13.60, 78.50, 7.10, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (9, 'Jagung dan Tahu Sayur', 'Jagung rebus, tahu isi sayur panggang, sayur bayam, dan jeruk.', 'Karbohidrat, protein nabati, dan serat', 455, 19.20, 12.10, 69.80, 11.20, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (10, 'Bandeng Presto dan Sawi', 'Nasi, ikan bandeng presto, tumis sawi, dan melon.', 'Protein, lemak baik, dan serat', 535, 32.30, 16.70, 68.90, 7.60, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (11, 'Tempe Orek dan Telur', 'Nasi, tempe orek sedikit minyak, telur rebus, dan lalapan matang.', 'Protein dan energi', 570, 25.40, 18.20, 75.60, 8.30, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/'),
    (12, 'Mi Jagung dan Ayam Suwir', 'Mi jagung, ayam suwir, sayur pakcoy wortel, dan pepaya.', 'Karbohidrat, protein, dan vitamin', 510, 27.00, 12.30, 73.40, 8.70, 'PanganKu/TKPI - estimasi porsi demo', 'https://panganku.org/');

