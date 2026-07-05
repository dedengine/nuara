import 'dart:convert';

class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.nama,
    required this.email,
    required this.peran,
    this.idUnitSppg,
  });

  final int id;
  final int? idUnitSppg;
  final String nama;
  final String email;
  final String peran;

  bool get isSuperAdmin => peran == 'super_admin';

  factory AdminProfile.fromJson(Map<String, dynamic> json) => AdminProfile(
    id: json['id'] as int,
    idUnitSppg: json['id_unit_sppg'] as int?,
    nama: json['nama'] as String,
    email: json['email'] as String,
    peran: json['peran'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_unit_sppg': idUnitSppg,
    'nama': nama,
    'email': email,
    'peran': peran,
  };
}

class AuthSession {
  const AuthSession({required this.token, required this.admin});

  final String token;
  final AdminProfile admin;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String,
    admin: AdminProfile.fromJson(json['admin'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'token': token, 'admin': admin.toJson()};

  String encode() => jsonEncode(toJson());

  static AuthSession? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return AuthSession.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
