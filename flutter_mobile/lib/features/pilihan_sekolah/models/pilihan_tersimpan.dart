class PilihanTersimpan {
  const PilihanTersimpan({
    required this.idUnitSppg,
    required this.namaUnitSppg,
    required this.idSekolah,
    required this.namaSekolah,
    required this.jenjang,
    required this.wilayah,
  });

  final int idUnitSppg;
  final String namaUnitSppg;
  final int idSekolah;
  final String namaSekolah;
  final String jenjang;
  final String wilayah;

  factory PilihanTersimpan.fromJson(Map<String, dynamic> json) {
    return PilihanTersimpan(
      idUnitSppg: (json['id_unit_sppg'] as num).toInt(),
      namaUnitSppg: json['nama_unit_sppg'] as String,
      idSekolah: (json['id_sekolah'] as num).toInt(),
      namaSekolah: json['nama_sekolah'] as String,
      jenjang: json['jenjang'] as String,
      wilayah: json['wilayah'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_unit_sppg': idUnitSppg,
    'nama_unit_sppg': namaUnitSppg,
    'id_sekolah': idSekolah,
    'nama_sekolah': namaSekolah,
    'jenjang': jenjang,
    'wilayah': wilayah,
  };
}
