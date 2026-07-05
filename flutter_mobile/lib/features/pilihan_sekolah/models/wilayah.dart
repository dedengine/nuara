class Wilayah {
  const Wilayah({required this.kode, required this.nama, this.kodePos});

  final String kode;
  final String nama;
  final String? kodePos;

  factory Wilayah.fromJson(Map<String, dynamic> json) => Wilayah(
    kode: json['kode'] as String,
    nama: json['nama'] as String,
    kodePos: json['kode_pos'] as String?,
  );

  @override
  bool operator ==(Object other) => other is Wilayah && other.kode == kode;

  @override
  int get hashCode => kode.hashCode;
}
