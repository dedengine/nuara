class TargetNutrisi {
  const TargetNutrisi({
    required this.kalori,
    required this.protein,
    required this.lemak,
    required this.karbohidrat,
    required this.sumber,
    required this.urlSumber,
  });

  final double kalori;
  final double protein;
  final double lemak;
  final double karbohidrat;
  final String sumber;
  final String urlSumber;

  factory TargetNutrisi.fromJson(Map<String, dynamic> json) {
    final target = json['target_hingga_makan_malam'] as Map<String, dynamic>;
    return TargetNutrisi(
      kalori: (target['kalori'] as num).toDouble(),
      protein: (target['protein'] as num).toDouble(),
      lemak: (target['lemak'] as num).toDouble(),
      karbohidrat: (target['karbohidrat'] as num).toDouble(),
      sumber: json['sumber_target'] as String,
      urlSumber: json['url_sumber_target'] as String,
    );
  }
}
