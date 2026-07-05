import '../../../core/config/api_config.dart';

class MenuHarian {
  const MenuHarian({
    required this.id,
    required this.tanggalMenu,
    required this.namaMenu,
    required this.deskripsi,
    required this.kalori,
    required this.protein,
    required this.lemak,
    required this.karbohidrat,
    required this.sumberDataGizi,
    required this.urlSumberDataGizi,
    required this.komponen,
    required this.alergi,
    required this.media,
  });

  final int id;
  final DateTime tanggalMenu;
  final String namaMenu;
  final String deskripsi;
  final double kalori;
  final double protein;
  final double lemak;
  final double karbohidrat;
  final String sumberDataGizi;
  final String urlSumberDataGizi;
  final List<KomponenMenu> komponen;
  final List<AlergiMenu> alergi;
  final List<MediaMenu> media;

  factory MenuHarian.fromJson(Map<String, dynamic> json) {
    return MenuHarian(
      id: (json['id'] as num).toInt(),
      tanggalMenu: DateTime.parse(json['tanggal_menu'] as String),
      namaMenu: json['nama_menu'] as String,
      deskripsi: json['deskripsi'] as String,
      kalori: (json['kalori'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      lemak: (json['lemak'] as num).toDouble(),
      karbohidrat: (json['karbohidrat'] as num).toDouble(),
      sumberDataGizi: json['sumber_data_gizi'] as String,
      urlSumberDataGizi: json['url_sumber_data_gizi'] as String,
      komponen: (json['komponen'] as List<dynamic>? ?? const [])
          .map((item) => KomponenMenu.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      alergi: (json['alergi'] as List<dynamic>? ?? const [])
          .map((item) => AlergiMenu.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((item) => MediaMenu.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class KomponenMenu {
  const KomponenMenu({
    required this.nama,
    required this.keteranganPorsi,
    required this.urutan,
  });

  final String nama;
  final String? keteranganPorsi;
  final int urutan;

  factory KomponenMenu.fromJson(Map<String, dynamic> json) {
    return KomponenMenu(
      nama: json['nama_komponen'] as String,
      keteranganPorsi: json['keterangan_porsi'] as String?,
      urutan: (json['urutan'] as num).toInt(),
    );
  }
}

class AlergiMenu {
  const AlergiMenu({required this.nama, required this.keterangan});

  final String nama;
  final String? keterangan;

  factory AlergiMenu.fromJson(Map<String, dynamic> json) {
    return AlergiMenu(
      nama: json['nama_alergi'] as String,
      keterangan: json['keterangan'] as String?,
    );
  }
}

class MediaMenu {
  const MediaMenu({
    required this.id,
    required this.jenis,
    required this.url,
    required this.namaBerkas,
    required this.mimeType,
    required this.durasiDetik,
  });

  final int id;
  final String jenis;
  final String url;
  final String namaBerkas;
  final String mimeType;
  final int? durasiDetik;

  bool get video => jenis == 'video';

  factory MediaMenu.fromJson(Map<String, dynamic> json) {
    return MediaMenu(
      id: (json['id'] as num).toInt(),
      jenis: json['jenis_media'] as String,
      url: ApiConfig.mediaUrl(json['url_berkas'] as String),
      namaBerkas: json['nama_berkas'] as String,
      mimeType: json['mime_type'] as String,
      durasiDetik: (json['durasi_detik'] as num?)?.toInt(),
    );
  }
}
