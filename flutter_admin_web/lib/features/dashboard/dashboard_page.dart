import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/auth_session.dart';
import '../../core/models/dashboard_data.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import 'management_dialogs.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(complaintEventsProvider);
    final session = ref.watch(authControllerProvider).session!;
    final entries = _entries(session.admin);
    if (_selectedIndex >= entries.length) _selectedIndex = 0;
    final compact = MediaQuery.sizeOf(context).width < 980;

    return Scaffold(
      drawer: compact
          ? Drawer(
              width: 270,
              shape: const RoundedRectangleBorder(),
              child: _Sidebar(
                entries: entries,
                selectedIndex: _selectedIndex,
                onSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!compact)
            SizedBox(
              width: 248,
              child: _Sidebar(
                entries: entries,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: entries[_selectedIndex].label,
                  session: session,
                  showMenu: compact,
                ),
                Expanded(
                  child: _DashboardBody(
                    page: entries[_selectedIndex].page,
                    session: session,
                    onNavigate: _navigateTo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(_PageType page) {
    final admin = ref.read(authControllerProvider).session!.admin;
    final index = _entries(admin).indexWhere((entry) => entry.page == page);
    if (index >= 0) setState(() => _selectedIndex = index);
  }

  List<_NavEntry> _entries(AdminProfile admin) => admin.isSuperAdmin
      ? const [
          _NavEntry(
            'Dashboard',
            LucideIcons.layoutDashboard,
            _PageType.overview,
          ),
          _NavEntry('Unit SPPG', LucideIcons.building2, _PageType.units),
          _NavEntry('Sekolah', LucideIcons.school, _PageType.schools),
          _NavEntry('Menu & Gizi', LucideIcons.utensils, _PageType.menus),
          _NavEntry(
            'Aduan',
            LucideIcons.messageSquareWarning,
            _PageType.complaints,
          ),
        ]
      : const [
          _NavEntry(
            'Dashboard',
            LucideIcons.layoutDashboard,
            _PageType.overview,
          ),
          _NavEntry('Sekolah', LucideIcons.school, _PageType.schools),
          _NavEntry('Menu & Gizi', LucideIcons.utensils, _PageType.menus),
          _NavEntry(
            'Aduan',
            LucideIcons.messageSquareWarning,
            _PageType.complaints,
          ),
        ];
}

enum _PageType { overview, units, schools, menus, complaints }

class _NavEntry {
  const _NavEntry(this.label, this.icon, this.page);

  final String label;
  final IconData icon;
  final _PageType page;
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.entries,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ColoredBox(
    color: AppColors.sidebar,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                _SidebarLogo(),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NUARA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Dashboard Admin',
                      style: TextStyle(color: Color(0xFF8DB2AC), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (ref
              .watch(authControllerProvider)
              .session!
              .admin
              .isSuperAdmin) ...[
            const SizedBox(height: 26),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _SuperAdminUnitContext(),
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 34),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'NAVIGASI',
              style: TextStyle(
                color: Color(0xFF789D97),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: _NavButton(
                entry: entries[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(22),
            child: Text(
              'Nuara v1.0.0',
              style: TextStyle(color: Color(0xFF6F948E), fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Image.asset('assets/branding/nuara-mark.png'),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _NavEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF20413D) : Colors.transparent,
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Container(
              width: 3,
              height: 22,
              color: selected ? AppColors.orange : Colors.transparent,
            ),
            const SizedBox(width: 14),
            Icon(
              entry.icon,
              size: 19,
              color: selected ? Colors.white : const Color(0xFFA8C1BD),
            ),
            const SizedBox(width: 12),
            Text(
              entry.label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFFA8C1BD),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.title,
    required this.session,
    required this.showMenu,
  });

  final String title;
  final AuthSession session;
  final bool showMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showMenu) ...[
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Buka navigasi',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(LucideIcons.menu),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        IconButton(
          tooltip: Theme.of(context).brightness == Brightness.dark
              ? 'Gunakan mode terang'
              : 'Gunakan mode gelap',
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? LucideIcons.sun
                : LucideIcons.moon,
            size: 19,
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<_ProfileAction>(
          tooltip: 'Buka profil pengguna',
          offset: const Offset(0, 48),
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 320),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          onSelected: (action) async {
            if (action == _ProfileAction.editProfile) {
              final changed = await showSuperAdminProfileDialog(
                context,
                admin: session.admin,
              );
              if (!context.mounted || !changed) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil berhasil diperbarui')),
              );
              return;
            }
            if (action == _ProfileAction.logout) {
              await ref.read(authControllerProvider.notifier).logout();
              return;
            }
            if (action == _ProfileAction.changePassword) {
              final changed = await showChangePasswordDialog(context);
              if (!context.mounted || !changed) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password berhasil diperbarui')),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<_ProfileAction>(
              height: 0,
              padding: EdgeInsets.zero,
              child: _ProfileDetails(admin: session.admin),
            ),
            const PopupMenuDivider(height: 1),
            if (session.admin.isSuperAdmin)
              const PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.editProfile,
                child: Row(
                  children: [
                    Icon(LucideIcons.userRoundPen, size: 18),
                    SizedBox(width: 12),
                    Text('Lihat & ubah profil'),
                  ],
                ),
              ),
            if (!session.admin.isSuperAdmin)
              const PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.changePassword,
                child: Row(
                  children: [
                    Icon(LucideIcons.keyRound, size: 18),
                    SizedBox(width: 12),
                    Text('Ubah password'),
                  ],
                ),
              ),
            const PopupMenuItem<_ProfileAction>(
              value: _ProfileAction.logout,
              child: Row(
                children: [
                  Icon(LucideIcons.logOut, size: 18),
                  SizedBox(width: 12),
                  Text('Keluar dari akun'),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                _ProfileAvatar(name: session.admin.nama, size: 36),
                if (MediaQuery.sizeOf(context).width >= 680) ...[
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.admin.nama,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        session.admin.isSuperAdmin
                            ? 'Super Admin'
                            : 'Admin SPPG',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 8),
                const Icon(LucideIcons.chevronDown, size: 16),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  static String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }
}

class _SuperAdminUnitContext extends ConsumerWidget {
  const _SuperAdminUnitContext();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUnitId = ref.watch(selectedUnitProvider);
    final units = ref
        .watch(dashboardProvider)
        .maybeWhen(
          data: (data) =>
              data.units.where((unit) => unit['aktif'] == true).toList(),
          orElse: () => const <Map<String, dynamic>>[],
        );

    Map<String, dynamic>? selectedUnit;
    for (final unit in units) {
      if ((unit['id'] as num?)?.toInt() == selectedUnitId) {
        selectedUnit = unit;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'UNIT SPPG',
            style: TextStyle(
              color: Color(0xFF789D97),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFF20413D),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: units.isEmpty
                ? null
                : () async {
                    final id = await showDialog<int>(
                      context: context,
                      builder: (_) => _UnitScopeDialog(
                        units: units,
                        selectedUnitId: selectedUnitId,
                      ),
                    );
                    if (id != null) {
                      ref.read(selectedUnitProvider.notifier).select(id);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.mapPinned,
                    color: AppColors.orange,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedUnit?['nama']?.toString() ??
                              (units.isEmpty
                                  ? 'Belum ada unit aktif'
                                  : 'Pilih unit SPPG'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedUnit == null
                              ? 'Tentukan data yang dikelola'
                              : '${selectedUnit['kecamatan']}, ${selectedUnit['kabupaten_kota']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFA8C1BD),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.chevronsUpDown,
                    color: Color(0xFFA8C1BD),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitScopeDialog extends StatefulWidget {
  const _UnitScopeDialog({required this.units, required this.selectedUnitId});

  final List<Map<String, dynamic>> units;
  final int? selectedUnitId;

  @override
  State<_UnitScopeDialog> createState() => _UnitScopeDialogState();
}

class _UnitScopeDialogState extends State<_UnitScopeDialog> {
  final _searchController = TextEditingController();
  String? _province;
  String? _regency;
  String? _district;
  String? _village;
  String? _postalCode;

  @override
  void initState() {
    super.initState();
    final selected = widget.units.where(
      (unit) => (unit['id'] as num?)?.toInt() == widget.selectedUnitId,
    );
    if (selected.isNotEmpty) {
      final unit = selected.first;
      _province = unit['provinsi']?.toString();
      _regency = unit['kabupaten_kota']?.toString();
      _district = unit['kecamatan']?.toString();
      _village = unit['kelurahan_desa']?.toString();
      _postalCode = unit['kode_pos']?.toString();
    }
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final provinces = _values(widget.units, 'provinsi');
    final regencies = _values(
      _filter(widget.units, province: _province),
      'kabupaten_kota',
    );
    final districts = _values(
      _filter(widget.units, province: _province, regency: _regency),
      'kecamatan',
    );
    final villages = _values(
      _filter(
        widget.units,
        province: _province,
        regency: _regency,
        district: _district,
      ),
      'kelurahan_desa',
    );
    final postalCodes = _values(
      _filter(
        widget.units,
        province: _province,
        regency: _regency,
        district: _district,
        village: _village,
      ),
      'kode_pos',
    );
    final query = _searchController.text.trim().toLowerCase();
    final matches =
        _filter(
          widget.units,
          province: _province,
          regency: _regency,
          district: _district,
          village: _village,
          postalCode: _postalCode,
        ).where((unit) {
          if (query.isEmpty) return true;
          return [
            unit['kode'],
            unit['nama'],
            unit['kelurahan_desa'],
            unit['kecamatan'],
            unit['kabupaten_kota'],
          ].any((value) => value.toString().toLowerCase().contains(query));
        }).toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih unit yang dikelola',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Saring wilayah lalu pilih satu SPPG sebagai konteks kerja.',
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cari nama atau kode SPPG',
                  prefixIcon: Icon(LucideIcons.search, size: 19),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    _filterField(
                      label: 'Provinsi',
                      value: _province,
                      values: provinces,
                      onChanged: (value) => setState(() {
                        _province = value;
                        _regency = _district = _village = _postalCode = null;
                      }),
                    ),
                    _filterField(
                      label: 'Kabupaten/Kota',
                      value: _regency,
                      values: regencies,
                      enabled: _province != null,
                      onChanged: (value) => setState(() {
                        _regency = value;
                        _district = _village = _postalCode = null;
                      }),
                    ),
                    _filterField(
                      label: 'Kecamatan',
                      value: _district,
                      values: districts,
                      enabled: _regency != null,
                      onChanged: (value) => setState(() {
                        _district = value;
                        _village = _postalCode = null;
                      }),
                    ),
                    _filterField(
                      label: 'Kelurahan/Desa',
                      value: _village,
                      values: villages,
                      enabled: _district != null,
                      onChanged: (value) => setState(() {
                        _village = value;
                        _postalCode = null;
                      }),
                    ),
                    _filterField(
                      label: 'Kode pos',
                      value: _postalCode,
                      values: postalCodes,
                      enabled: _village != null,
                      onChanged: (value) => setState(() => _postalCode = value),
                    ),
                  ];
                  if (constraints.maxWidth < 620) {
                    return Column(
                      children: [
                        for (final field in fields) ...[
                          field,
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final field in fields)
                        SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: field,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${matches.length} unit ditemukan',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(LucideIcons.rotateCcw, size: 16),
                    label: const Text('Atur ulang'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('Tidak ada unit yang sesuai'))
                    : ListView.separated(
                        itemCount: matches.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final unit = matches[index];
                          final id = (unit['id'] as num).toInt();
                          final selected = id == widget.selectedUnitId;
                          return ListTile(
                            selected: selected,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            leading: Icon(
                              selected
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.building2,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            title: Text(
                              unit['nama']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${unit['kode']} | ${unit['kelurahan_desa']}, ${unit['kecamatan']}, ${unit['kabupaten_kota']} | ${unit['kode_pos']}',
                            ),
                            trailing: const Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                            ),
                            onTap: () => Navigator.pop(context, id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterField({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value-${values.length}'),
    initialValue: values.contains(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: values
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: enabled ? onChanged : null,
  );

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _province = _regency = _district = _village = _postalCode = null;
    });
  }

  static List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> units, {
    String? province,
    String? regency,
    String? district,
    String? village,
    String? postalCode,
  }) => units.where((unit) {
    return (province == null || unit['provinsi'] == province) &&
        (regency == null || unit['kabupaten_kota'] == regency) &&
        (district == null || unit['kecamatan'] == district) &&
        (village == null || unit['kelurahan_desa'] == village) &&
        (postalCode == null || unit['kode_pos'] == postalCode);
  }).toList();

  static List<String> _values(List<Map<String, dynamic>> units, String key) {
    final values =
        units
            .map((unit) => unit[key]?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }
}

enum _ProfileAction { editProfile, changePassword, logout }

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.primarySoft,
      shape: BoxShape.circle,
    ),
    child: Text(
      _TopBar._initials(name),
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.admin});
  final AdminProfile admin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ProfileAvatar(name: admin.nama, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.nama,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    admin.isSuperAdmin ? 'Super Admin' : 'Admin SPPG',
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProfileInfo(icon: LucideIcons.mail, text: admin.email),
        const SizedBox(height: 10),
        _ProfileInfo(
          icon: LucideIcons.badgeCheck,
          text: 'ID Admin: ${admin.id}',
        ),
        if (admin.idUnitSppg != null) ...[
          const SizedBox(height: 10),
          _ProfileInfo(
            icon: LucideIcons.building2,
            text: 'Unit SPPG: ${admin.idUnitSppg}',
          ),
        ],
      ],
    ),
  );
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textMuted(context)),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
        ),
      ),
    ],
  );
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.page,
    required this.session,
    required this.onNavigate,
  });

  final _PageType page;
  final AuthSession session;
  final ValueChanged<_PageType> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _ErrorView(onRetry: () => ref.invalidate(dashboardProvider)),
      data: (data) {
        final selectedUnitId = ref.watch(selectedUnitProvider);
        final needsUnit =
            page == _PageType.schools ||
            page == _PageType.menus ||
            page == _PageType.complaints;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child:
                session.admin.isSuperAdmin &&
                    needsUnit &&
                    selectedUnitId == null
                ? const _SelectUnitPrompt()
                : switch (page) {
                    _PageType.overview => _Overview(
                      session: session,
                      data: data,
                      selectedUnitId: selectedUnitId,
                      onNavigate: onNavigate,
                    ),
                    _PageType.units => _UnitsView(data: data.units),
                    _PageType.schools => _SchoolsView(data: data.schools),
                    _PageType.menus => _MenusView(
                      data: data.menus,
                      schools: data.schools,
                    ),
                    _PageType.complaints => _ComplaintsView(
                      data: data.complaints,
                      schools: data.schools,
                    ),
                  },
          ),
        );
      },
    );
  }
}

class _SelectUnitPrompt extends StatelessWidget {
  const _SelectUnitPrompt();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 420,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.building2,
            size: 38,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(height: 14),
          Text(
            'Pilih unit SPPG terlebih dahulu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Gunakan pilihan unit di bagian kanan atas dashboard.',
            style: TextStyle(color: AppColors.textMuted(context)),
          ),
        ],
      ),
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.session,
    required this.data,
    required this.selectedUnitId,
    required this.onNavigate,
  });

  final AuthSession session;
  final DashboardData data;
  final int? selectedUnitId;
  final ValueChanged<_PageType> onNavigate;

  @override
  Widget build(BuildContext context) {
    if (!session.admin.isSuperAdmin) {
      return _AdminOverview(data: data, onNavigate: onNavigate);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SuperOverview(data: data, onNavigate: onNavigate),
        if (selectedUnitId != null) ...[
          const SizedBox(height: 32),
          _AdminOverview(
            data: data,
            onNavigate: onNavigate,
            title: 'Ringkasan SPPG',
            subtitle: 'Progress operasional unit SPPG yang sedang dikelola.',
          ),
        ],
      ],
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({
    required this.data,
    required this.onNavigate,
    this.title = 'Ringkasan operasional',
    this.subtitle = 'Kondisi terbaru unit SPPG dan sekolah binaan.',
  });

  final DashboardData data;
  final ValueChanged<_PageType> onNavigate;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final activeSchools = data.schools
        .where((item) => item['aktif'] == true)
        .length;
    final publishedMenus = data.menus
        .where(
          (item) => item['aktif'] == true && item['status'] == 'dipublikasikan',
        )
        .length;
    final newComplaints = (data.stats['baru'] as num?)?.toInt() ?? 0;
    final satisfaction =
        (data.stats['rata_rata_kepuasan'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeading(title: title, subtitle: subtitle),
        const SizedBox(height: 20),
        _MetricGrid(
          onNavigate: onNavigate,
          metrics: [
            _Metric(
              'Sekolah aktif',
              '$activeSchools',
              LucideIcons.school,
              AppColors.primary,
              _PageType.schools,
            ),
            _Metric(
              'Menu tercatat',
              '$publishedMenus',
              LucideIcons.utensils,
              AppColors.orange,
              _PageType.menus,
            ),
            _Metric(
              'Aduan baru',
              '$newComplaints',
              LucideIcons.messageSquareWarning,
              AppColors.red,
              _PageType.complaints,
            ),
            _Metric(
              'Kepuasan rata-rata',
              satisfaction == 0
                  ? '—'
                  : '${satisfaction.toStringAsFixed(1)} / 5',
              LucideIcons.chartNoAxesColumnIncreasing,
              AppColors.blue,
              _PageType.complaints,
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final chart = _ComplaintChart(
              stats: data.stats,
              onTap: () => onNavigate(_PageType.complaints),
            );
            final menus = _LatestMenus(
              menus: data.menus,
              onTap: () => onNavigate(_PageType.menus),
            );
            return stacked
                ? Column(children: [chart, const SizedBox(height: 20), menus])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: chart),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: menus),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        _RecentComplaints(
          complaints: data.complaints,
          onTap: () => onNavigate(_PageType.complaints),
        ),
      ],
    );
  }
}

class _SuperOverview extends StatelessWidget {
  const _SuperOverview({required this.data, required this.onNavigate});

  final DashboardData data;
  final ValueChanged<_PageType> onNavigate;

  @override
  Widget build(BuildContext context) {
    final active = data.units.where((item) => item['aktif'] == true).length;
    final admins = data.units.where((item) => item['id_admin'] != null).length;
    final schools = data.units.fold<int>(
      0,
      (sum, item) => sum + ((item['jumlah_sekolah'] as num?)?.toInt() ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeading(
          title: 'Ringkasan Nuara',
          subtitle: 'Cakupan unit SPPG, admin, dan sekolah yang terhubung.',
        ),
        const SizedBox(height: 20),
        _MetricGrid(
          onNavigate: onNavigate,
          metrics: [
            _Metric(
              'Total unit',
              '${data.units.length}',
              LucideIcons.building2,
              AppColors.blue,
              _PageType.units,
            ),
            _Metric(
              'Unit aktif',
              '$active',
              LucideIcons.circleCheck,
              AppColors.primary,
              _PageType.units,
            ),
            _Metric(
              'Admin unit',
              '$admins',
              LucideIcons.userRoundCheck,
              AppColors.orange,
              _PageType.units,
            ),
            _Metric(
              'Sekolah binaan',
              '$schools',
              LucideIcons.school,
              AppColors.red,
              _PageType.schools,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _UnitsDataView(data: data.units),
      ],
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text(subtitle, style: TextStyle(color: AppColors.textMuted(context))),
      ],
    );
    if (action == null) return heading;

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 620
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: 14), action!],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heading),
                const SizedBox(width: 16),
                action!,
              ],
            ),
    );
  }
}

class _Metric {
  const _Metric(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.destination,
  );
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final _PageType destination;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, required this.onNavigate});
  final List<_Metric> metrics;
  final ValueChanged<_PageType> onNavigate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1120
          ? 4
          : constraints.maxWidth >= 620
          ? 2
          : 1;
      const gap = 16.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: metrics
            .map(
              (metric) => SizedBox(
                width: width,
                height: 118,
                child: _MetricCard(
                  metric: metric,
                  onTap: () => onNavigate(metric.destination),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.onTap});
  final _Metric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: metric.color.withAlpha(24),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(metric.icon, size: 22, color: metric.color),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ComplaintChart extends StatelessWidget {
  const _ComplaintChart({required this.stats, required this.onTap});
  final Map<String, dynamic> stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final values = [
      'baru',
      'diproses',
      'selesai',
      'ditolak',
    ].map((key) => (stats[key] as num?)?.toDouble() ?? 0).toList();
    final maxValue = math.max(4.0, values.fold<double>(0, math.max) + 1);
    const colors = [
      AppColors.red,
      AppColors.orange,
      AppColors.primary,
      AppColors.muted,
    ];
    return _Panel(
      title: 'Status aduan',
      onTap: onTap,
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            maxY: maxValue,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
            ),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, _) {
                    const labels = ['Baru', 'Diproses', 'Selesai', 'Ditolak'];
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(
              values.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index],
                    width: 28,
                    color: colors[index],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestMenus extends StatelessWidget {
  const _LatestMenus({required this.menus, required this.onTap});
  final List<Map<String, dynamic>> menus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = menus.take(4).toList();
    return _Panel(
      title: 'Menu terbaru',
      onTap: onTap,
      child: SizedBox(
        height: 250,
        child: latest.isEmpty
            ? const _EmptyState(
                icon: LucideIcons.utensils,
                message: 'Belum ada menu',
              )
            : ListView.separated(
                itemCount: latest.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final menu = latest[index];
                  return SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.orangeSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            LucideIcons.utensils,
                            size: 17,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                menu['nama_menu']?.toString() ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _date(menu['tanggal_menu']?.toString()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${menu['kalori'] ?? 0} kkal',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _RecentComplaints extends StatelessWidget {
  const _RecentComplaints({required this.complaints, required this.onTap});
  final List<Map<String, dynamic>> complaints;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Aduan terbaru',
    onTap: onTap,
    child: complaints.isEmpty
        ? const SizedBox(
            height: 130,
            child: _EmptyState(
              icon: LucideIcons.messageSquareCheck,
              message: 'Belum ada aduan masuk',
            ),
          )
        : _RecordRows(
            children: complaints
                .take(5)
                .map((item) => _ComplaintRecord(item: item))
                .toList(),
          ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.onTap});
  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _UnitsView extends ConsumerWidget {
  const _UnitsView({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PageHeading(
        title: 'Unit SPPG',
        subtitle: 'Daftar unit, wilayah layanan, sekolah, dan akun admin.',
        action: FilledButton.icon(
          onPressed: () => _openUnitForm(context, ref),
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Tambah unit'),
        ),
      ),
      const SizedBox(height: 20),
      _UnitsDataView(
        data: data,
        onEdit: (item) => _openUnitForm(context, ref, unit: item),
        onCreateAdmin: (item) => _openUnitAdmin(context, ref, item),
        onResetPassword: (item) => _resetUnitPassword(context, ref, item),
        onDeactivate: (item) => _deactivateUnit(context, ref, item),
        onDelete: (item) => _deleteUnit(context, ref, item),
      ),
    ],
  );

  Future<void> _openUnitForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? unit,
  }) async {
    final saved = await showUnitFormDialog(context, unit: unit);
    if (!context.mounted || !saved) return;
    _refreshDashboard(
      context,
      ref,
      unit == null ? 'Unit SPPG berhasil ditambahkan' : 'Unit SPPG diperbarui',
    );
  }

  Future<void> _openUnitAdmin(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> unit,
  ) async {
    final saved = await showUnitAdminDialog(context, unit: unit);
    if (!context.mounted || !saved) return;
    _refreshDashboard(
      context,
      ref,
      unit['id_admin'] == null
          ? 'Akun admin unit berhasil dibuat'
          : 'Akun admin unit berhasil diperbarui',
    );
  }

  Future<void> _deactivateUnit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> unit,
  ) async {
    final confirmed = await showDeactivateDialog(
      context,
      subject: unit['nama']?.toString() ?? 'Unit SPPG',
    );
    if (!context.mounted || !confirmed) return;
    await _runMutation(
      context,
      ref,
      () => ref
          .read(managementRepositoryProvider)
          .deactivateUnit((unit['id'] as num).toInt()),
      'Unit SPPG berhasil dinonaktifkan',
    );
  }

  Future<void> _resetUnitPassword(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> unit,
  ) async {
    final confirmed = await showResetUnitPasswordDialog(
      context,
      subject: unit['nama']?.toString() ?? 'unit SPPG',
    );
    if (!context.mounted || !confirmed) return;
    await _runMutation(
      context,
      ref,
      () => ref
          .read(managementRepositoryProvider)
          .resetUnitAdminPassword((unit['id'] as num).toInt()),
      'Password admin berhasil direset menjadi nuara123',
    );
  }

  Future<void> _deleteUnit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> unit,
  ) async {
    final confirmed = await showPermanentUnitDeleteDialog(
      context,
      subject: unit['nama']?.toString() ?? 'Unit SPPG',
    );
    if (!context.mounted || !confirmed) return;
    final id = (unit['id'] as num).toInt();
    try {
      await ref.read(managementRepositoryProvider).deleteUnitPermanently(id);
      if (!context.mounted) return;
      if (ref.read(selectedUnitProvider) == id) {
        ref.read(selectedUnitProvider.notifier).select(null);
      }
      _refreshDashboard(context, ref, 'Unit SPPG berhasil dihapus permanen');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(error)),
            backgroundColor: AppColors.red,
          ),
        );
    }
  }
}

class _UnitsDataView extends StatelessWidget {
  const _UnitsDataView({
    required this.data,
    this.onEdit,
    this.onCreateAdmin,
    this.onResetPassword,
    this.onDeactivate,
    this.onDelete,
  });
  final List<Map<String, dynamic>> data;
  final ValueChanged<Map<String, dynamic>>? onEdit;
  final ValueChanged<Map<String, dynamic>>? onCreateAdmin;
  final ValueChanged<Map<String, dynamic>>? onResetPassword;
  final ValueChanged<Map<String, dynamic>>? onDeactivate;
  final ValueChanged<Map<String, dynamic>>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _Panel(
        title: '0 unit tercatat',
        child: SizedBox(
          height: 160,
          child: _EmptyState(
            icon: LucideIcons.building2,
            message: 'Belum ada unit SPPG',
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final hasActions = onEdit != null;
        return compact
            ? _CompactRecordList(
                title: '${data.length} unit tercatat',
                children: data
                    .map(
                      (item) => _UnitRecord(
                        item: item,
                        actions: hasActions ? _unitActions(item) : const [],
                      ),
                    )
                    .toList(),
              )
            : _PaginatedMapTable(
                title: '${data.length} unit tercatat',
                data: data,
                columnFlex: [1.4, 2, 2.2, 0.8, 1.5, 1, if (hasActions) 1.5],
                cellAlignments: [
                  Alignment.center,
                  Alignment.center,
                  Alignment.center,
                  Alignment.center,
                  Alignment.center,
                  Alignment.center,
                  if (hasActions) Alignment.center,
                ],
                columns: [
                  const DataColumn(label: Text('KODE')),
                  const DataColumn(label: Text('UNIT SPPG')),
                  const DataColumn(label: Text('WILAYAH')),
                  const DataColumn(label: Text('SEKOLAH')),
                  const DataColumn(label: Text('ADMIN')),
                  const DataColumn(label: Text('STATUS')),
                  if (hasActions) const DataColumn(label: Text('TINDAKAN')),
                ],
                cellsBuilder: (item) => [
                  DataCell(
                    Text(
                      item['kode']?.toString() ?? '-',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataCell(
                    Text(
                      item['nama']?.toString() ?? '-',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataCell(
                    Text(
                      '${item['kecamatan'] ?? '-'}, ${item['kabupaten_kota'] ?? '-'}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataCell(
                    Text(
                      '${item['jumlah_sekolah'] ?? 0}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataCell(
                    Text(
                      item['nama_admin']?.toString() ?? 'Belum dibuat',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataCell(_StatusBadge.active(item['aktif'] == true)),
                  if (hasActions)
                    DataCell(_RowActions(children: _unitActions(item))),
                ],
              );
      },
    );
  }

  List<Widget> _unitActions(Map<String, dynamic> item) => [
    _editButton(() => onEdit!(item), 'Ubah unit'),
    if (item['aktif'] == true)
      IconButton(
        tooltip: item['id_admin'] == null
            ? 'Buat admin unit'
            : 'Ubah admin unit',
        onPressed: () => onCreateAdmin!(item),
        icon: Icon(
          item['id_admin'] == null
              ? LucideIcons.userRoundPlus
              : LucideIcons.userRoundCog,
          size: 18,
        ),
      ),
    PopupMenuButton<_UnitDangerAction>(
      tooltip: 'Tindakan unit lainnya',
      icon: const Icon(LucideIcons.ellipsisVertical, size: 18),
      onSelected: (action) {
        switch (action) {
          case _UnitDangerAction.deactivate:
            onDeactivate!(item);
            return;
          case _UnitDangerAction.resetPassword:
            onResetPassword!(item);
            return;
          case _UnitDangerAction.delete:
            onDelete!(item);
            return;
        }
      },
      itemBuilder: (context) => [
        if (item['aktif'] == true && item['id_admin'] != null)
          const PopupMenuItem(
            value: _UnitDangerAction.resetPassword,
            child: Row(
              children: [
                Icon(LucideIcons.keyRound, size: 17),
                SizedBox(width: 10),
                Text('Reset password admin'),
              ],
            ),
          ),
        if (item['aktif'] == true)
          const PopupMenuItem(
            value: _UnitDangerAction.deactivate,
            child: Row(
              children: [
                Icon(LucideIcons.circleOff, size: 17, color: AppColors.red),
                SizedBox(width: 10),
                Text('Nonaktifkan unit'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: _UnitDangerAction.delete,
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 17, color: AppColors.red),
              SizedBox(width: 10),
              Text('Hapus permanen'),
            ],
          ),
        ),
      ],
    ),
  ];
}

enum _UnitDangerAction { resetPassword, deactivate, delete }

class _SchoolsView extends ConsumerWidget {
  const _SchoolsView({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PageHeading(
        title: 'Sekolah binaan',
        subtitle: 'Sekolah yang menerima distribusi dari unit SPPG ini.',
        action: FilledButton.icon(
          onPressed: () => _openForm(context, ref),
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Tambah sekolah'),
        ),
      ),
      const SizedBox(height: 20),
      if (data.isEmpty)
        const _Panel(
          title: '0 sekolah tercatat',
          child: SizedBox(
            height: 160,
            child: _EmptyState(
              icon: LucideIcons.school,
              message: 'Belum ada sekolah',
            ),
          ),
        )
      else
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            return compact
                ? _CompactRecordList(
                    title: '${data.length} sekolah tercatat',
                    children: data
                        .map(
                          (item) => _SchoolRecord(
                            item: item,
                            actions: _actions(context, ref, item),
                          ),
                        )
                        .toList(),
                  )
                : _PaginatedMapTable(
                    title: '${data.length} sekolah tercatat',
                    data: data,
                    columnFlex: const [2.2, 0.7, 4.4, 0.8, 1.1],
                    cellAlignments: const [
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                    ],
                    columns: const [
                      DataColumn(label: Text('NAMA SEKOLAH')),
                      DataColumn(label: Text('JENJANG')),
                      DataColumn(label: Text('ALAMAT LENGKAP')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('TINDAKAN')),
                    ],
                    cellsBuilder: (item) => [
                      DataCell(Text(item['nama']?.toString() ?? '-')),
                      DataCell(Text(item['jenjang']?.toString() ?? '-')),
                      DataCell(_SchoolAddressCell(item: item)),
                      DataCell(_StatusBadge.active(item['aktif'] == true)),
                      DataCell(
                        _RowActions(children: _actions(context, ref, item)),
                      ),
                    ],
                  );
          },
        ),
    ],
  );

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) => [
    _editButton(() => _openForm(context, ref, school: item), 'Ubah sekolah'),
    if (item['aktif'] == true)
      _deactivateButton(
        () => _deactivate(context, ref, item),
        'Nonaktifkan sekolah',
      ),
  ];

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? school,
  }) async {
    final saved = await showSchoolFormDialog(context, school: school);
    if (!context.mounted || !saved) return;
    _refreshDashboard(
      context,
      ref,
      school == null ? 'Sekolah berhasil ditambahkan' : 'Sekolah diperbarui',
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> school,
  ) async {
    final confirmed = await showDeactivateDialog(
      context,
      subject: school['nama']?.toString() ?? 'Sekolah',
    );
    if (!context.mounted || !confirmed) return;
    await _runMutation(
      context,
      ref,
      () => ref
          .read(managementRepositoryProvider)
          .deactivateSchool((school['id'] as num).toInt()),
      'Sekolah berhasil dinonaktifkan',
    );
  }
}

class _MenusView extends ConsumerWidget {
  const _MenusView({required this.data, required this.schools});
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> schools;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PageHeading(
        title: 'Menu & gizi',
        subtitle: 'Menu harian, nilai nutrisi, cakupan sekolah, dan publikasi.',
        action: FilledButton.icon(
          onPressed: () => _openForm(context, ref),
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Tambah menu'),
        ),
      ),
      const SizedBox(height: 20),
      if (data.isEmpty)
        const _Panel(
          title: '0 menu tercatat',
          child: SizedBox(
            height: 160,
            child: _EmptyState(
              icon: LucideIcons.utensils,
              message: 'Belum ada menu',
            ),
          ),
        )
      else
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            return compact
                ? _CompactRecordList(
                    title: '${data.length} menu tercatat',
                    children: data
                        .map(
                          (item) => _MenuRecord(
                            item: item,
                            actions: _actions(context, ref, item),
                          ),
                        )
                        .toList(),
                  )
                : _PaginatedMapTable(
                    title: '${data.length} menu tercatat',
                    data: data,
                    columnFlex: const [1.1, 2.4, 3.6, 0.9, 1.5],
                    cellAlignments: const [
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                    ],
                    columns: const [
                      DataColumn(label: Text('TANGGAL')),
                      DataColumn(label: Text('MENU & CAKUPAN')),
                      DataColumn(label: Text('NILAI NUTRISI')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('TINDAKAN')),
                    ],
                    cellsBuilder: (item) => [
                      DataCell(Text(_date(item['tanggal_menu']?.toString()))),
                      DataCell(_MenuSummaryCell(item: item)),
                      DataCell(_NutritionCell(item: item)),
                      DataCell(_StatusBadge.menu(item)),
                      DataCell(
                        _RowActions(children: _actions(context, ref, item)),
                      ),
                    ],
                  );
          },
        ),
    ],
  );

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) => [
    _editButton(() => _openForm(context, ref, menu: item), 'Ubah menu'),
    IconButton(
      tooltip: 'Kelola media menu',
      onPressed: () => _openMedia(context, ref, item),
      icon: const Icon(LucideIcons.images, size: 18),
    ),
    if (item['aktif'] == true)
      _deactivateButton(
        () => _deactivate(context, ref, item),
        'Nonaktifkan menu',
      ),
    IconButton(
      tooltip: 'Hapus menu permanen',
      onPressed: () => _delete(context, ref, item),
      color: AppColors.red,
      icon: const Icon(LucideIcons.trash2, size: 18),
    ),
  ];

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? menu,
  }) async {
    final saved = await showMenuFormDialog(
      context,
      schools: schools,
      menu: menu,
    );
    if (!context.mounted || !saved) return;
    _refreshDashboard(
      context,
      ref,
      menu == null ? 'Menu berhasil ditambahkan' : 'Menu diperbarui',
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> menu,
  ) async {
    final confirmed = await showDeactivateDialog(
      context,
      subject: menu['nama_menu']?.toString() ?? 'Menu',
    );
    if (!context.mounted || !confirmed) return;
    await _runMutation(
      context,
      ref,
      () => ref
          .read(managementRepositoryProvider)
          .deactivateMenu((menu['id'] as num).toInt()),
      'Menu berhasil dinonaktifkan',
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> menu,
  ) async {
    final confirmed = await showPermanentDeleteDialog(
      context,
      subject: menu['nama_menu']?.toString() ?? 'Menu',
    );
    if (!context.mounted || !confirmed) return;
    await _runMutation(
      context,
      ref,
      () => ref
          .read(managementRepositoryProvider)
          .deleteMenuPermanently((menu['id'] as num).toInt()),
      'Menu berhasil dihapus permanen',
    );
  }

  Future<void> _openMedia(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> menu,
  ) async {
    final changed = await showMenuMediaDialog(context, menu: menu);
    if (!context.mounted || !changed) return;
    _refreshDashboard(context, ref, 'Media dokumentasi diperbarui');
  }
}

class _ComplaintsView extends ConsumerStatefulWidget {
  const _ComplaintsView({required this.data, required this.schools});

  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> schools;

  @override
  ConsumerState<_ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends ConsumerState<_ComplaintsView> {
  String _status = 'semua';
  int? _schoolId;

  List<Map<String, dynamic>> get _filtered => widget.data
      .where((item) {
        final statusMatch = _status == 'semua' || item['status'] == _status;
        final schoolMatch =
            _schoolId == null ||
            (item['id_sekolah'] as num?)?.toInt() == _schoolId;
        return statusMatch && schoolMatch;
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeading(
          title: 'Pusat aduan',
          subtitle:
              'Laporan anonim orang tua beserta bukti, kepuasan, dan tindak lanjut.',
        ),
        const SizedBox(height: 18),
        _ComplaintFilterBar(
          schools: widget.schools,
          status: _status,
          schoolId: _schoolId,
          shown: filtered.length,
          total: widget.data.length,
          onStatusChanged: (value) =>
              setState(() => _status = value ?? 'semua'),
          onSchoolChanged: (value) => setState(() => _schoolId = value),
          onReset: () => setState(() {
            _status = 'semua';
            _schoolId = null;
          }),
        ),
        const SizedBox(height: 16),
        if (widget.data.isEmpty)
          const _Panel(
            title: '0 aduan tercatat',
            child: SizedBox(
              height: 160,
              child: _EmptyState(
                icon: LucideIcons.messageSquareCheck,
                message: 'Belum ada aduan masuk',
              ),
            ),
          )
        else if (filtered.isEmpty)
          const _Panel(
            title: '0 aduan sesuai filter',
            child: SizedBox(
              height: 160,
              child: _EmptyState(
                icon: LucideIcons.listFilter,
                message: 'Tidak ada aduan yang sesuai dengan filter',
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              return compact
                  ? _CompactRecordList(
                      title: '${filtered.length} aduan ditampilkan',
                      children: filtered
                          .map(
                            (item) => _ComplaintRecord(
                              item: item,
                              actions: _actions(context, item),
                            ),
                          )
                          .toList(),
                    )
                  : _PaginatedMapTable(
                      title: '${filtered.length} aduan ditampilkan',
                      data: filtered,
                      columnFlex: const [1.7, 2.3, 1.5, 1, 1, 0.9],
                      cellAlignments: const [
                        Alignment.center,
                        Alignment.center,
                        Alignment.center,
                        Alignment.center,
                        Alignment.center,
                        Alignment.center,
                      ],
                      columns: const [
                        DataColumn(label: Text('WAKTU')),
                        DataColumn(label: Text('SEKOLAH')),
                        DataColumn(label: Text('KATEGORI')),
                        DataColumn(label: Center(child: Text('KEPUASAN'))),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Center(child: Text('TINDAKAN'))),
                      ],
                      cellsBuilder: (item) => [
                        DataCell(
                          Text(_dateTime(item['created_at']?.toString())),
                        ),
                        DataCell(Text(item['nama_sekolah']?.toString() ?? '-')),
                        DataCell(
                          Text(_humanize(item['kategori']?.toString() ?? '-')),
                        ),
                        DataCell(
                          Center(
                            child: Text('${item['nilai_kepuasan'] ?? 0} / 5'),
                          ),
                        ),
                        DataCell(
                          _StatusBadge.complaint(
                            item['status']?.toString() ?? 'baru',
                          ),
                        ),
                        DataCell(
                          Center(
                            child: _RowActions(
                              children: _actions(context, item),
                            ),
                          ),
                        ),
                      ],
                    );
            },
          ),
      ],
    );
  }

  List<Widget> _actions(BuildContext context, Map<String, dynamic> item) => [
    IconButton(
      tooltip: 'Lihat detail aduan',
      onPressed: () => _openDetail(context, item),
      icon: const Icon(LucideIcons.eye, size: 18),
    ),
  ];

  Future<void> _openDetail(
    BuildContext context,
    Map<String, dynamic> complaint,
  ) async {
    final saved = await showComplaintDetailDialog(
      context,
      complaint: complaint,
    );
    if (!context.mounted || !saved) return;
    _refreshDashboard(context, ref, 'Status aduan diperbarui');
  }
}

class _ComplaintFilterBar extends StatelessWidget {
  const _ComplaintFilterBar({
    required this.schools,
    required this.status,
    required this.schoolId,
    required this.shown,
    required this.total,
    required this.onStatusChanged,
    required this.onSchoolChanged,
    required this.onReset,
  });

  final List<Map<String, dynamic>> schools;
  final String status;
  final int? schoolId;
  final int shown;
  final int total;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int?> onSchoolChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final filtered = status != 'semua' || schoolId != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final statusField = DropdownButtonFormField<String>(
            key: ValueKey('complaint-status-$status'),
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'semua', child: Text('Semua status')),
              DropdownMenuItem(value: 'baru', child: Text('Baru')),
              DropdownMenuItem(value: 'diproses', child: Text('Diproses')),
              DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
              DropdownMenuItem(value: 'ditolak', child: Text('Ditolak')),
            ],
            onChanged: onStatusChanged,
          );
          final schoolField = DropdownButtonFormField<int?>(
            key: ValueKey('complaint-school-$schoolId'),
            initialValue: schoolId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Sekolah'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Semua sekolah'),
              ),
              ...schools.map(
                (school) => DropdownMenuItem<int?>(
                  value: (school['id'] as num?)?.toInt(),
                  child: Text(
                    school['nama']?.toString() ?? '-',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onSchoolChanged,
          );
          final count = Text(
            '$shown dari $total aduan',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
          );
          final reset = IconButton(
            tooltip: 'Reset filter',
            onPressed: filtered ? onReset : null,
            icon: const Icon(LucideIcons.listRestart, size: 19),
          );

          if (compact) {
            return Column(
              children: [
                statusField,
                const SizedBox(height: 10),
                schoolField,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: count),
                    reset,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 190, child: statusField),
              const SizedBox(width: 12),
              Expanded(child: schoolField),
              const SizedBox(width: 16),
              count,
              const SizedBox(width: 4),
              reset,
            ],
          );
        },
      ),
    );
  }
}

typedef _DataCellsBuilder = List<DataCell> Function(Map<String, dynamic> item);

class _PaginatedMapTable extends StatefulWidget {
  const _PaginatedMapTable({
    required this.title,
    required this.data,
    required this.columns,
    required this.cellsBuilder,
    this.columnFlex,
    this.cellAlignments,
  });

  final String title;
  final List<Map<String, dynamic>> data;
  final List<DataColumn> columns;
  final _DataCellsBuilder cellsBuilder;
  final List<double>? columnFlex;
  final List<Alignment>? cellAlignments;

  @override
  State<_PaginatedMapTable> createState() => _PaginatedMapTableState();
}

class _PaginatedMapTableState extends State<_PaginatedMapTable> {
  static const _rowOptions = [5, 10, 20];
  int _rowsPerPage = _rowOptions.first;
  int _page = 0;

  @override
  void didUpdateWidget(covariant _PaginatedMapTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lastPage = math.max(0, _pageCount(widget.data.length) - 1);
    if (_page > lastPage) _page = lastPage;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.columnFlex == null ||
          widget.columnFlex!.length == widget.columns.length,
      'Jumlah columnFlex harus sama dengan jumlah kolom.',
    );
    assert(
      widget.cellAlignments == null ||
          widget.cellAlignments!.length == widget.columns.length,
      'Jumlah cellAlignments harus sama dengan jumlah kolom.',
    );
    final start = math.min(_page * _rowsPerPage, widget.data.length);
    final end = math.min(start + _rowsPerPage, widget.data.length);
    final pageData = widget.data.sublist(start, end);
    final pageCount = _pageCount(widget.data.length);
    final headingStyle =
        Theme.of(context).dataTableTheme.headingTextStyle ??
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted(context),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              for (var index = 0; index < widget.columns.length; index++)
                index: FlexColumnWidth(widget.columnFlex?[index] ?? 1),
            },
            border: const TableBorder(
              horizontalInside: BorderSide(color: AppColors.border),
              top: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                children: widget.columns
                    .map(
                      (column) => _tableCell(
                        DefaultTextStyle(
                          style: headingStyle,
                          child: column.label,
                        ),
                        header: true,
                      ),
                    )
                    .toList(),
              ),
              for (final item in pageData)
                TableRow(
                  children: widget
                      .cellsBuilder(item)
                      .asMap()
                      .entries
                      .map(
                        (entry) => _tableCell(
                          entry.value.child,
                          alignment: widget.cellAlignments?[entry.key],
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Baris per halaman:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    isDense: true,
                    items: _rowOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _rowsPerPage = value;
                        _page = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 84,
                  child: Text(
                    '${start + 1}-$end dari ${widget.data.length}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Halaman pertama',
                  onPressed: _page == 0
                      ? null
                      : () => setState(() => _page = 0),
                  icon: const Icon(LucideIcons.chevronsLeft, size: 18),
                ),
                IconButton(
                  tooltip: 'Halaman sebelumnya',
                  onPressed: _page == 0
                      ? null
                      : () => setState(() => _page -= 1),
                  icon: const Icon(LucideIcons.chevronLeft, size: 18),
                ),
                IconButton(
                  tooltip: 'Halaman berikutnya',
                  onPressed: _page >= pageCount - 1
                      ? null
                      : () => setState(() => _page += 1),
                  icon: const Icon(LucideIcons.chevronRight, size: 18),
                ),
                IconButton(
                  tooltip: 'Halaman terakhir',
                  onPressed: _page >= pageCount - 1
                      ? null
                      : () => setState(() => _page = pageCount - 1),
                  icon: const Icon(LucideIcons.chevronsRight, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _pageCount(int itemCount) =>
      math.max(1, (itemCount / _rowsPerPage).ceil());

  Widget _tableCell(
    Widget child, {
    bool header = false,
    Alignment? alignment,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: header ? 48 : 56),
      child: Align(
        alignment:
            alignment ?? (header ? Alignment.center : Alignment.centerLeft),
        child: child,
      ),
    ),
  );
}

class _CompactRecordList extends StatelessWidget {
  const _CompactRecordList({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => _Panel(
    title: title,
    child: _RecordRows(children: children),
  );
}

class _RecordRows extends StatelessWidget {
  const _RecordRows({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index < children.length - 1) const Divider(height: 1),
      ],
    ],
  );
}

class _CompactRecord extends StatelessWidget {
  const _CompactRecord({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.status,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> details;
  final Widget status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 19, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  status,
                ],
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted(context),
                ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: details
                      .map(
                        (detail) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _RowActions(children: actions),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _UnitRecord extends StatelessWidget {
  const _UnitRecord({required this.item, this.actions = const []});
  final Map<String, dynamic> item;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => _CompactRecord(
    icon: LucideIcons.building2,
    title: item['nama']?.toString() ?? '-',
    subtitle:
        '${item['kode'] ?? '-'} | ${item['kecamatan'] ?? '-'}, ${item['kabupaten_kota'] ?? '-'}',
    details: [
      '${item['jumlah_sekolah'] ?? 0} sekolah',
      item['nama_admin']?.toString() ?? 'Admin belum dibuat',
    ],
    status: _StatusBadge.active(item['aktif'] == true),
    actions: actions,
  );
}

class _SchoolRecord extends StatelessWidget {
  const _SchoolRecord({required this.item, this.actions = const []});
  final Map<String, dynamic> item;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => _CompactRecord(
    icon: LucideIcons.school,
    title: item['nama']?.toString() ?? '-',
    subtitle: item['alamat_detail']?.toString() ?? '-',
    details: [
      item['jenjang']?.toString() ?? '-',
      '${item['kelurahan_desa'] ?? '-'}, ${item['kecamatan'] ?? '-'}, ${item['kabupaten_kota'] ?? '-'}, ${item['provinsi'] ?? '-'}',
      'Kode pos ${item['kode_pos'] ?? '-'} | RT ${item['rt'] ?? '-'} / RW ${item['rw'] ?? '-'}',
    ],
    status: _StatusBadge.active(item['aktif'] == true),
    actions: actions,
  );
}

class _SchoolAddressCell extends StatelessWidget {
  const _SchoolAddressCell({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          item['alamat_detail']?.toString() ?? '-',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          '${item['kelurahan_desa'] ?? '-'}, ${item['kecamatan'] ?? '-'}, '
          '${item['kabupaten_kota'] ?? '-'}, ${item['provinsi'] ?? '-'}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
        ),
        const SizedBox(height: 2),
        Text(
          'Kode pos ${item['kode_pos'] ?? '-'} | '
          'RT ${item['rt'] ?? '-'} / RW ${item['rw'] ?? '-'}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
        ),
      ],
    ),
  );
}

class _MenuRecord extends StatelessWidget {
  const _MenuRecord({required this.item, this.actions = const []});
  final Map<String, dynamic> item;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => _CompactRecord(
    icon: LucideIcons.utensils,
    title: item['nama_menu']?.toString() ?? '-',
    subtitle: _date(item['tanggal_menu']?.toString()),
    details: [
      item['id_sekolah'] == null ? 'Semua sekolah' : 'Sekolah khusus',
      '${item['kalori'] ?? 0} kkal',
      '${item['protein'] ?? 0} g protein',
      '${item['lemak'] ?? 0} g lemak',
      '${item['karbohidrat'] ?? 0} g karbohidrat',
    ],
    status: _StatusBadge.menu(item),
    actions: actions,
  );
}

class _MenuSummaryCell extends StatelessWidget {
  const _MenuSummaryCell({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          item['nama_menu']?.toString() ?? '-',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          item['id_sekolah'] == null ? 'Semua sekolah' : 'Sekolah khusus',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
        ),
      ],
    ),
  );
}

class _NutritionCell extends StatelessWidget {
  const _NutritionCell({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              child: _NutritionMetric(
                label: 'Kalori',
                value: '${item['kalori'] ?? 0} kkal',
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 155,
              child: _NutritionMetric(
                label: 'Protein',
                value: '${item['protein'] ?? 0} g',
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              child: _NutritionMetric(
                label: 'Lemak',
                value: '${item['lemak'] ?? 0} g',
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 155,
              child: _NutritionMetric(
                label: 'Karbohidrat',
                value: '${item['karbohidrat'] ?? 0} g',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NutritionMetric extends StatelessWidget {
  const _NutritionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 70,
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _ComplaintRecord extends StatelessWidget {
  const _ComplaintRecord({required this.item, this.actions = const []});
  final Map<String, dynamic> item;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => _CompactRecord(
    icon: LucideIcons.messageSquareWarning,
    title: item['nama_sekolah']?.toString() ?? '-',
    subtitle: _dateTime(item['created_at']?.toString()),
    details: [
      _humanize(item['kategori']?.toString() ?? '-'),
      '${item['nilai_kepuasan'] ?? 0} / 5',
    ],
    status: _StatusBadge.complaint(item['status']?.toString() ?? 'baru'),
    actions: actions,
  );
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: children);
}

Widget _editButton(VoidCallback onPressed, String tooltip) => IconButton(
  tooltip: tooltip,
  onPressed: onPressed,
  icon: const Icon(LucideIcons.pencil, size: 18),
);

Widget _deactivateButton(VoidCallback onPressed, String tooltip) => IconButton(
  tooltip: tooltip,
  onPressed: onPressed,
  color: AppColors.red,
  icon: const Icon(LucideIcons.circleOff, size: 18),
);

Future<void> _runMutation(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() mutation,
  String successMessage,
) async {
  try {
    await mutation();
    if (!context.mounted) return;
    _refreshDashboard(context, ref, successMessage);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ApiClient.errorMessage(error)),
          backgroundColor: AppColors.red,
        ),
      );
  }
}

void _refreshDashboard(BuildContext context, WidgetRef ref, String message) {
  ref.invalidate(dashboardProvider);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;

  factory _StatusBadge.active(bool active) => active
      ? const _StatusBadge(
          'Aktif',
          AppColors.primaryDark,
          AppColors.primarySoft,
        )
      : const _StatusBadge('Nonaktif', AppColors.muted, Color(0xFFEEF1F0));

  factory _StatusBadge.menu(Map<String, dynamic> menu) {
    if (menu['aktif'] != true) {
      return const _StatusBadge('Nonaktif', AppColors.muted, Color(0xFFEEF1F0));
    }
    return menu['status'] == 'dipublikasikan'
        ? const _StatusBadge(
            'Terbit',
            AppColors.primaryDark,
            AppColors.primarySoft,
          )
        : const _StatusBadge('Draf', Color(0xFF9A5D12), AppColors.orangeSoft);
  }

  factory _StatusBadge.complaint(String status) => switch (status) {
    'baru' => const _StatusBadge('Baru', AppColors.red, AppColors.redSoft),
    'diproses' => const _StatusBadge(
      'Diproses',
      Color(0xFF9A5D12),
      AppColors.orangeSoft,
    ),
    'selesai' => const _StatusBadge(
      'Selesai',
      AppColors.primaryDark,
      AppColors.primarySoft,
    ),
    _ => const _StatusBadge('Ditolak', AppColors.muted, Color(0xFFEEF1F0)),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: AppColors.textMuted(context)),
        const SizedBox(height: 10),
        Text(message, style: TextStyle(color: AppColors.textMuted(context))),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.serverOff, size: 38, color: AppColors.red),
        const SizedBox(height: 14),
        const Text('Data dashboard belum dapat dimuat'),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}

String _date(String? value) {
  if (value == null) return '-';
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? value
      : DateFormat('dd MMM yyyy', 'id').format(parsed);
}

String _dateTime(String? value) {
  if (value == null) return '-';
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? value
      : DateFormat('dd MMM yyyy, HH:mm', 'id').format(parsed);
}

String _humanize(String value) {
  if (value == 'makanan_rusak') return 'Makanan Basi';
  return value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
