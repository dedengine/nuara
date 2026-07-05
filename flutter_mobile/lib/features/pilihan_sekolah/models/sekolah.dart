class Sekolah {
  const Sekolah({
    required this.id,
    required this.idUnitSppg,
    required this.nama,
    required this.jenjang,
    required this.kecamatan,
    required this.kabupatenKota,
  });

  final int id;
  final int idUnitSppg;
  final String nama;
  final String jenjang;
  final String kecamatan;
  final String kabupatenKota;

  factory Sekolah.fromJson(Map<String, dynamic> json) {
    return Sekolah(
      id: (json['id'] as num).toInt(),
      idUnitSppg: (json['id_unit_sppg'] as num).toInt(),
      nama: json['nama'] as String,
      jenjang: json['jenjang'] as String,
      kecamatan: json['kecamatan'] as String,
      kabupatenKota: json['kabupaten_kota'] as String,
    );
  }
}
