class DashboardData {
  const DashboardData({
    this.units = const [],
    this.schools = const [],
    this.menus = const [],
    this.complaints = const [],
    this.stats = const {},
  });

  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> schools;
  final List<Map<String, dynamic>> menus;
  final List<Map<String, dynamic>> complaints;
  final Map<String, dynamic> stats;
}
