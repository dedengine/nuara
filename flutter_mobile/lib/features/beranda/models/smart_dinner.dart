import 'target_nutrisi.dart';

class SmartDinner {
  const SmartDinner({
    required this.makanSiang,
    required this.target,
    required this.kekurangan,
    required this.rekomendasi,
    required this.catatan,
  });

  final RingkasanMakanSiang makanSiang;
  final TargetNutrisi target;
  final NilaiNutrisi kekurangan;
  final List<RekomendasiMakanMalam> rekomendasi;
  final String catatan;

  factory SmartDinner.fromJson(Map<String, dynamic> json) {
    return SmartDinner(
      makanSiang: RingkasanMakanSiang.fromJson(
        json['makan_siang'] as Map<String, dynamic>,
      ),
      target: TargetNutrisi.fromJson(json),
      kekurangan: NilaiNutrisi.fromJson(
        json['kekurangan_setelah_makan_siang'] as Map<String, dynamic>,
      ),
      rekomendasi: (json['rekomendasi'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                RekomendasiMakanMalam.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      catatan: json['catatan'] as String,
    );
  }
}

class RingkasanMakanSiang {
  const RingkasanMakanSiang({
    required this.idMenu,
    required this.namaMenu,
    required this.tanggalMenu,
    required this.jenjang,
    required this.nutrisi,
  });

  final int idMenu;
  final String namaMenu;
  final DateTime tanggalMenu;
  final String jenjang;
  final NilaiNutrisi nutrisi;

  factory RingkasanMakanSiang.fromJson(Map<String, dynamic> json) {
    return RingkasanMakanSiang(
      idMenu: (json['id_menu_harian'] as num).toInt(),
      namaMenu: json['nama_menu'] as String,
      tanggalMenu: DateTime.parse(json['tanggal_menu'] as String),
      jenjang: json['jenjang'] as String,
      nutrisi: NilaiNutrisi.fromJson(json),
    );
  }
}

class NilaiNutrisi {
  const NilaiNutrisi({
    required this.kalori,
    required this.protein,
    required this.lemak,
    required this.karbohidrat,
  });

  final double kalori;
  final double protein;
  final double lemak;
  final double karbohidrat;

  factory NilaiNutrisi.fromJson(Map<String, dynamic> json) {
    return NilaiNutrisi(
      kalori: (json['kalori'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      lemak: (json['lemak'] as num).toDouble(),
      karbohidrat: (json['karbohidrat'] as num).toDouble(),
    );
  }
}

class RekomendasiMakanMalam {
  const RekomendasiMakanMalam({
    required this.id,
    required this.namaMenu,
    required this.deskripsi,
    required this.fokusNutrisi,
    required this.nutrisi,
    required this.serat,
    required this.sumberDataGizi,
    required this.urlSumberDataGizi,
    required this.skorKecocokan,
  });

  final int id;
  final String namaMenu;
  final String deskripsi;
  final String fokusNutrisi;
  final NilaiNutrisi nutrisi;
  final double serat;
  final String sumberDataGizi;
  final String urlSumberDataGizi;
  final double skorKecocokan;

  factory RekomendasiMakanMalam.fromJson(Map<String, dynamic> json) {
    return RekomendasiMakanMalam(
      id: (json['id'] as num).toInt(),
      namaMenu: json['nama_menu'] as String,
      deskripsi: json['deskripsi'] as String,
      fokusNutrisi: json['fokus_nutrisi'] as String,
      nutrisi: NilaiNutrisi.fromJson(json),
      serat: (json['serat'] as num).toDouble(),
      sumberDataGizi: json['sumber_data_gizi'] as String,
      urlSumberDataGizi: json['url_sumber_data_gizi'] as String,
      skorKecocokan: (json['skor_kecocokan'] as num).toDouble(),
    );
  }
}
