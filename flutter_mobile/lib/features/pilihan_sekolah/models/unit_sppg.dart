class UnitSppg {
  const UnitSppg({
    required this.id,
    required this.kode,
    required this.nama,
    required this.kodeProvinsi,
    required this.provinsi,
    required this.kodeKabupatenKota,
    required this.kabupatenKota,
    required this.kodeKecamatan,
    required this.kecamatan,
    required this.kodeKelurahanDesa,
    required this.kelurahanDesa,
    required this.kodePos,
    required this.jumlahSekolah,
  });

  final int id;
  final String kode;
  final String nama;
  final String? kodeProvinsi;
  final String provinsi;
  final String? kodeKabupatenKota;
  final String kabupatenKota;
  final String? kodeKecamatan;
  final String kecamatan;
  final String? kodeKelurahanDesa;
  final String kelurahanDesa;
  final String kodePos;
  final int jumlahSekolah;

  factory UnitSppg.fromJson(Map<String, dynamic> json) {
    return UnitSppg(
      id: (json['id'] as num).toInt(),
      kode: json['kode'] as String,
      nama: json['nama'] as String,
      kodeProvinsi: json['kode_provinsi'] as String?,
      provinsi: json['provinsi'] as String,
      kodeKabupatenKota: json['kode_kabupaten_kota'] as String?,
      kabupatenKota: json['kabupaten_kota'] as String,
      kodeKecamatan: json['kode_kecamatan'] as String?,
      kecamatan: json['kecamatan'] as String,
      kodeKelurahanDesa: json['kode_kelurahan_desa'] as String?,
      kelurahanDesa: json['kelurahan_desa'] as String,
      kodePos: json['kode_pos'] as String,
      jumlahSekolah: (json['jumlah_sekolah'] as num).toInt(),
    );
  }

  String get wilayah => '$kecamatan, $kabupatenKota';
}
