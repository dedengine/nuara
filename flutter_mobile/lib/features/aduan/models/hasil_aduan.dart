class HasilAduan {
  const HasilAduan({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String status;
  final DateTime createdAt;

  factory HasilAduan.fromJson(Map<String, dynamic> json) {
    return HasilAduan(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
