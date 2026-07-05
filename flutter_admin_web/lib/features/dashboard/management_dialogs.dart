import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../core/network/api_client.dart';
import '../../core/models/auth_session.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

const _schoolLevels = ['SD', 'SMP', 'SMA', 'SMK', 'SLB', 'LAINNYA'];

Future<bool> showUnitFormDialog(
  BuildContext context, {
  Map<String, dynamic>? unit,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UnitFormDialog(unit: unit),
    ) ??
    false;

Future<bool> showUnitAdminDialog(
  BuildContext context, {
  required Map<String, dynamic> unit,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UnitAdminDialog(unit: unit),
    ) ??
    false;

Future<bool> showSchoolFormDialog(
  BuildContext context, {
  Map<String, dynamic>? school,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SchoolFormDialog(school: school),
    ) ??
    false;

Future<bool> showMenuFormDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> schools,
  Map<String, dynamic>? menu,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MenuFormDialog(schools: schools, menu: menu),
    ) ??
    false;

Future<bool> showMenuMediaDialog(
  BuildContext context, {
  required Map<String, dynamic> menu,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MenuMediaDialog(menu: menu),
    ) ??
    false;

Future<bool> showComplaintDetailDialog(
  BuildContext context, {
  required Map<String, dynamic> complaint,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _ComplaintDetailDialog(complaint: complaint),
    ) ??
    false;

Future<bool> showChangePasswordDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    ) ??
    false;

Future<bool> showSuperAdminProfileDialog(
  BuildContext context, {
  required AdminProfile admin,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuperAdminProfileDialog(admin: admin),
    ) ??
    false;

Future<bool> showDeactivateDialog(
  BuildContext context, {
  required String subject,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi nonaktifkan'),
        content: Text(
          '$subject akan disembunyikan dari layanan aktif, tetapi riwayat datanya tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> showPermanentDeleteDialog(
  BuildContext context, {
  required String subject,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus menu permanen?'),
        content: Text(
          '$subject beserta komponen, alergi, foto, dan videonya akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(LucideIcons.trash2, size: 17),
            label: const Text('Hapus permanen'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> showPermanentUnitDeleteDialog(
  BuildContext context, {
  required String subject,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus unit SPPG permanen?'),
        content: Text(
          '$subject beserta akun admin, sekolah, menu, dokumentasi, aduan, dan seluruh bukti medianya akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(LucideIcons.trash2, size: 17),
            label: const Text('Hapus permanen'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> showResetUnitPasswordDialog(
  BuildContext context, {
  required String subject,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password admin?'),
        content: Text(
          'Password admin $subject akan direset menjadi nuara123. Berikan password ini hanya kepada admin unit dan minta admin menggantinya setelah berhasil masuk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(LucideIcons.keyRound, size: 17),
            label: const Text('Reset password'),
          ),
        ],
      ),
    ) ??
    false;

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _SuperAdminProfileDialog extends ConsumerStatefulWidget {
  const _SuperAdminProfileDialog({required this.admin});

  final AdminProfile admin;

  @override
  ConsumerState<_SuperAdminProfileDialog> createState() =>
      _SuperAdminProfileDialogState();
}

class _SuperAdminProfileDialogState
    extends ConsumerState<_SuperAdminProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.admin.nama);
    _email = TextEditingController(text: widget.admin.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
    title: 'Profil Super Admin',
    subtitle: 'Lihat dan perbarui identitas akun utama Nuara.',
    width: 540,
    saving: _saving,
    error: _error,
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _ProfileReadonlyField(
                  label: 'ID Admin',
                  value: widget.admin.id.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileReadonlyField(
                  label: 'Hak akses',
                  value: 'Super Admin',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
            validator: (value) {
              final length = value?.trim().characters.length ?? 0;
              return length < 3 || length > 150
                  ? 'Nama harus terdiri dari 3 sampai 150 karakter'
                  : null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              final email = value?.trim() ?? '';
              return email.isEmpty || !email.contains('@') || email.length > 190
                  ? 'Masukkan email yang valid'
                  : null;
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateSuperAdminProfile(name: _name.text, email: _email.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiClient.errorMessage(error);
      });
    }
  }
}

class _ProfileReadonlyField extends StatelessWidget {
  const _ProfileReadonlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirmation = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
    title: 'Ubah password',
    subtitle: 'Masukkan password lama untuk mengamankan perubahan akun.',
    width: 500,
    saving: _saving,
    error: _error,
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _passwordField(
            controller: _current,
            label: 'Password lama',
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 14),
          _passwordField(
            controller: _next,
            label: 'Password baru',
            obscure: _obscureNext,
            onToggle: () => setState(() => _obscureNext = !_obscureNext),
          ),
          const SizedBox(height: 14),
          _passwordField(
            controller: _confirmation,
            label: 'Konfirmasi password baru',
            obscure: _obscureConfirmation,
            onToggle: () =>
                setState(() => _obscureConfirmation = !_obscureConfirmation),
            validator: (value) => value == _next.text
                ? _passwordValidator(value)
                : 'Konfirmasi password tidak sama',
          ),
        ],
      ),
    ),
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator ?? _passwordValidator,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
        onPressed: onToggle,
        icon: Icon(obscure ? LucideIcons.eye : LucideIcons.eyeOff),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_current.text == _next.text) {
      setState(() => _error = 'Password baru harus berbeda dari password lama');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiClient.errorMessage(error);
      });
    }
  }
}

class _UnitFormDialog extends ConsumerStatefulWidget {
  const _UnitFormDialog({this.unit});
  final Map<String, dynamic>? unit;

  @override
  ConsumerState<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends ConsumerState<_UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late bool _active;
  bool _saving = false;
  bool _loadingRegions = true;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _error;
  String? _provinceCode;
  String? _regencyCode;
  String? _districtCode;
  String? _villageCode;
  String? _postalCode;
  List<Map<String, dynamic>> _provinces = const [];
  List<Map<String, dynamic>> _regencies = const [];
  List<Map<String, dynamic>> _districts = const [];
  List<Map<String, dynamic>> _villages = const [];
  List<String> _postalCodes = const [];

  @override
  void initState() {
    super.initState();
    _fields = _controllers(widget.unit, const [
      'kode',
      'nama',
      'rt',
      'rw',
      'alamat_detail',
      'nomor_telepon',
      'admin_nama',
      'admin_email',
      'admin_password',
      'konfirmasi_password',
    ]);
    _active = widget.unit?['aktif'] != false;
    _loadInitialRegions();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
    title: widget.unit == null ? 'Tambah unit SPPG' : 'Ubah unit SPPG',
    subtitle: widget.unit == null
        ? 'Lengkapi unit, wilayah layanan, dan akun adminnya.'
        : 'Perbarui identitas dan wilayah layanan unit.',
    saving: _saving,
    error: _error,
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldGrid(
            children: [
              TextFormField(
                controller: _fields['kode'],
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Kode SPPG',
                  hintText: widget.unit == null
                      ? 'Dibuat otomatis setelah disimpan'
                      : null,
                  prefixIcon: const Icon(LucideIcons.badgeCheck, size: 18),
                ),
              ),
              _textField(_fields['nama']!, 'Nama unit SPPG'),
            ],
          ),
          const SizedBox(height: 20),
          const _FormSectionTitle(
            icon: LucideIcons.mapPinned,
            title: 'Wilayah layanan',
          ),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _RegionDropdown(
                label: 'Provinsi',
                value: _provinceCode,
                items: _provinces,
                loading: _loadingRegions,
                enabled: !_loadingRegions,
                onChanged: _onProvinceChanged,
              ),
              _RegionDropdown(
                label: 'Kabupaten/Kota',
                value: _regencyCode,
                items: _regencies,
                loading: _loadingRegions && _provinceCode != null,
                enabled: _provinceCode != null,
                onChanged: _onRegencyChanged,
              ),
              _RegionDropdown(
                label: 'Kecamatan',
                value: _districtCode,
                items: _districts,
                loading: _loadingRegions && _regencyCode != null,
                enabled: _regencyCode != null,
                onChanged: _onDistrictChanged,
              ),
              _RegionDropdown(
                label: 'Kelurahan/Desa',
                value: _villageCode,
                items: _villages,
                loading: _loadingRegions && _districtCode != null,
                enabled: _districtCode != null,
                onChanged: _onVillageChanged,
              ),
              _PostalDropdown(
                value: _postalCode,
                items: _postalCodes,
                loading: _loadingRegions && _villageCode != null,
                enabled: _villageCode != null,
                onChanged: (value) => setState(() => _postalCode = value),
              ),
              _textField(
                _fields['nomor_telepon']!,
                'Nomor telepon (opsional)',
                required: false,
                keyboardType: TextInputType.phone,
              ),
              _textField(
                _fields['rt']!,
                'RT',
                validator: _rtRwValidator,
                keyboardType: TextInputType.number,
              ),
              _textField(
                _fields['rw']!,
                'RW',
                validator: _rtRwValidator,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _textField(_fields['alamat_detail']!, 'Alamat detail', maxLines: 3),
          if (widget.unit == null) ...[
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 18),
            const _FormSectionTitle(
              icon: LucideIcons.userRoundCog,
              title: 'Akun Admin SPPG',
            ),
            const SizedBox(height: 5),
            Text(
              'Akun ini hanya dapat mengelola unit SPPG yang sedang dibuat.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _FieldGrid(
              children: [
                _textField(_fields['admin_nama']!, 'Nama admin'),
                _textField(
                  _fields['admin_email']!,
                  'Email admin',
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                TextFormField(
                  controller: _fields['admin_password'],
                  obscureText: _obscurePassword,
                  validator: _passwordValidator,
                  decoration: InputDecoration(
                    labelText: 'Password awal',
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _fields['konfirmasi_password'],
                  obscureText: _obscureConfirmation,
                  validator: (value) => value != _fields['admin_password']!.text
                      ? 'Konfirmasi password tidak sama'
                      : _passwordValidator(value),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi password',
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmation
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      onPressed: () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                      icon: Icon(
                        _obscureConfirmation
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.unit != null) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Unit aktif'),
              subtitle: const Text(
                'Unit aktif dapat dikelola admin dan dipilih dari aplikasi mobile.',
              ),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_provinceCode == null ||
        _regencyCode == null ||
        _districtCode == null ||
        _villageCode == null ||
        _postalCode == null) {
      setState(() => _error = 'Lengkapi seluruh pilihan wilayah layanan');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(managementRepositoryProvider).saveUnit({
        'nama': _value('nama'),
        'kode_provinsi': _provinceCode,
        'provinsi': _regionName(_provinces, _provinceCode),
        'kode_kabupaten_kota': _regencyCode,
        'kabupaten_kota': _regionName(_regencies, _regencyCode),
        'kode_kecamatan': _districtCode,
        'kecamatan': _regionName(_districts, _districtCode),
        'kode_kelurahan_desa': _villageCode,
        'kelurahan_desa': _regionName(_villages, _villageCode),
        'kode_pos': _postalCode,
        'rt': _value('rt'),
        'rw': _value('rw'),
        'alamat_detail': _value('alamat_detail'),
        'nomor_telepon': _value('nomor_telepon'),
        'aktif': _active,
        if (widget.unit == null)
          'admin': {
            'nama': _value('admin_nama'),
            'email': _value('admin_email'),
            'password': _fields['admin_password']!.text,
          },
      }, id: _id(widget.unit));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiClient.errorMessage(error);
        });
      }
    }
  }

  dynamic _value(String key) {
    final value = _fields[key]!.text.trim();
    return key == 'nomor_telepon' && value.isEmpty ? null : value;
  }

  Future<void> _loadInitialRegions() async {
    try {
      final repository = ref.read(managementRepositoryProvider);
      final provinceCode = widget.unit?['kode_provinsi']?.toString();
      final regencyCode = widget.unit?['kode_kabupaten_kota']?.toString();
      final districtCode = widget.unit?['kode_kecamatan']?.toString();
      final villageCode = widget.unit?['kode_kelurahan_desa']?.toString();
      final provinces = await repository.getProvinces();
      final regencies = provinceCode == null
          ? <Map<String, dynamic>>[]
          : await repository.getRegencies(provinceCode);
      final districts = regencyCode == null
          ? <Map<String, dynamic>>[]
          : await repository.getDistricts(regencyCode);
      final villages = districtCode == null
          ? <Map<String, dynamic>>[]
          : await repository.getVillages(districtCode);
      final postalCodes = villageCode == null
          ? <String>[]
          : await repository.getPostalCodes(villageCode);
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _regencies = regencies;
        _districts = districts;
        _villages = villages;
        _postalCodes = postalCodes;
        _provinceCode = _containsCode(provinces, provinceCode)
            ? provinceCode
            : null;
        _regencyCode = _containsCode(regencies, regencyCode)
            ? regencyCode
            : null;
        _districtCode = _containsCode(districts, districtCode)
            ? districtCode
            : null;
        _villageCode = _containsCode(villages, villageCode)
            ? villageCode
            : null;
        _postalCode = postalCodes.contains(widget.unit?['kode_pos']?.toString())
            ? widget.unit!['kode_pos'].toString()
            : postalCodes.firstOrNull;
        _loadingRegions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRegions = false;
        _error = ApiClient.errorMessage(error);
      });
    }
  }

  Future<void> _onProvinceChanged(String? value) async {
    setState(() {
      _provinceCode = value;
      _regencyCode = null;
      _districtCode = null;
      _villageCode = null;
      _postalCode = null;
      _regencies = const [];
      _districts = const [];
      _villages = const [];
      _postalCodes = const [];
      _loadingRegions = value != null;
    });
    if (value == null) return;
    await _loadRegionLevel(
      () => ref.read(managementRepositoryProvider).getRegencies(value),
      (data) => _regencies = data,
    );
  }

  Future<void> _onRegencyChanged(String? value) async {
    setState(() {
      _regencyCode = value;
      _districtCode = null;
      _villageCode = null;
      _postalCode = null;
      _districts = const [];
      _villages = const [];
      _postalCodes = const [];
      _loadingRegions = value != null;
    });
    if (value == null) return;
    await _loadRegionLevel(
      () => ref.read(managementRepositoryProvider).getDistricts(value),
      (data) => _districts = data,
    );
  }

  Future<void> _onDistrictChanged(String? value) async {
    setState(() {
      _districtCode = value;
      _villageCode = null;
      _postalCode = null;
      _villages = const [];
      _postalCodes = const [];
      _loadingRegions = value != null;
    });
    if (value == null) return;
    await _loadRegionLevel(
      () => ref.read(managementRepositoryProvider).getVillages(value),
      (data) => _villages = data,
    );
  }

  Future<void> _onVillageChanged(String? value) async {
    setState(() {
      _villageCode = value;
      _postalCode = null;
      _postalCodes = const [];
      _loadingRegions = value != null;
    });
    if (value == null) return;
    try {
      final data = await ref
          .read(managementRepositoryProvider)
          .getPostalCodes(value);
      if (!mounted || _villageCode != value) return;
      setState(() {
        _postalCodes = data;
        _postalCode = data.firstOrNull;
        _loadingRegions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRegions = false;
        _error = ApiClient.errorMessage(error);
      });
    }
  }

  Future<void> _loadRegionLevel(
    Future<List<Map<String, dynamic>>> Function() request,
    void Function(List<Map<String, dynamic>>) assign,
  ) async {
    try {
      final data = await request();
      if (!mounted) return;
      setState(() {
        assign(data);
        _loadingRegions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRegions = false;
        _error = ApiClient.errorMessage(error);
      });
    }
  }
}

class _UnitAdminDialog extends ConsumerStatefulWidget {
  const _UnitAdminDialog({required this.unit});
  final Map<String, dynamic> unit;

  @override
  ConsumerState<_UnitAdminDialog> createState() => _UnitAdminDialogState();
}

class _UnitAdminDialogState extends ConsumerState<_UnitAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  bool _obscureConfirmation = true;
  String? _error;

  bool get _editing => widget.unit['id_admin'] != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.unit['nama_admin']?.toString() ?? '',
    );
    _email = TextEditingController(
      text: widget.unit['email_admin']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
    title: _editing ? 'Ubah admin unit' : 'Buat admin unit',
    subtitle: widget.unit['nama']?.toString() ?? 'Unit SPPG',
    width: 520,
    saving: _saving,
    error: _error,
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _textField(_name, 'Nama admin'),
          const SizedBox(height: 14),
          _textField(
            _email,
            'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (!text.contains('@') || !text.contains('.')) {
                return 'Masukkan email yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            validator: (value) {
              if (_editing && (value?.isEmpty ?? true)) return null;
              return _passwordValidator(value);
            },
            decoration: InputDecoration(
              labelText: _editing
                  ? 'Password baru (opsional)'
                  : 'Password awal',
              helperText: _editing
                  ? 'Kosongkan jika password tidak ingin diubah.'
                  : null,
              suffixIcon: IconButton(
                tooltip: _obscure
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmation,
            obscureText: _obscureConfirmation,
            validator: (value) {
              if (_editing &&
                  _password.text.isEmpty &&
                  (value?.isEmpty ?? true)) {
                return null;
              }
              return value == _password.text
                  ? null
                  : 'Konfirmasi password tidak sama';
            },
            decoration: InputDecoration(
              labelText: 'Konfirmasi password',
              suffixIcon: IconButton(
                tooltip: _obscureConfirmation
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                icon: Icon(
                  _obscureConfirmation ? LucideIcons.eye : LucideIcons.eyeOff,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(managementRepositoryProvider);
      final data = {
        'nama': _name.text.trim(),
        'email': _email.text.trim(),
        if (!_editing || _password.text.isNotEmpty) 'password': _password.text,
      };
      if (_editing) {
        await repository.updateUnitAdmin(_id(widget.unit)!, data);
      } else {
        await repository.createUnitAdmin(_id(widget.unit)!, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiClient.errorMessage(error);
        });
      }
    }
  }
}

class _SchoolFormDialog extends ConsumerStatefulWidget {
  const _SchoolFormDialog({this.school});
  final Map<String, dynamic>? school;

  @override
  ConsumerState<_SchoolFormDialog> createState() => _SchoolFormDialogState();
}

class _SchoolFormDialogState extends ConsumerState<_SchoolFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late String _level;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fields = _controllers(widget.school, const [
      'nama',
      'rt',
      'rw',
      'alamat_detail',
    ]);
    _level = widget.school?['jenjang']?.toString() ?? 'SD';
    _active = widget.school?['aktif'] != false;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
    title: widget.school == null ? 'Tambah sekolah' : 'Ubah sekolah',
    subtitle: 'Sekolah akan terhubung dengan unit SPPG dari akun ini.',
    saving: _saving,
    error: _error,
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FormSectionTitle(
            title: 'Informasi sekolah',
            subtitle: 'Identitas utama sekolah binaan.',
          ),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _textField(_fields['nama']!, 'Nama sekolah'),
              DropdownButtonFormField<String>(
                initialValue: _level,
                isExpanded: true,
                menuMaxHeight: 300,
                borderRadius: BorderRadius.circular(8),
                elevation: 5,
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: const Icon(LucideIcons.chevronDown, size: 17),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(labelText: 'Jenjang'),
                selectedItemBuilder: (context) => _schoolLevels
                    .map(
                      (value) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                items: _schoolLevels
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            Expanded(child: Text(value)),
                            if (value == _level)
                              const Icon(
                                LucideIcons.check,
                                size: 16,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _level = value ?? 'SD'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.mapPinned, color: AppColors.primary, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Provinsi, kabupaten/kota, kecamatan, kelurahan/desa, dan kode pos otomatis mengikuti unit SPPG.',
                    style: TextStyle(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _FormSectionTitle(
            title: 'Detail alamat',
            subtitle: 'Lengkapi RT/RW dan alamat detail sekolah.',
          ),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _textField(
                _fields['rt']!,
                'RT',
                validator: _rtRwValidator,
                keyboardType: TextInputType.number,
              ),
              _textField(
                _fields['rw']!,
                'RW',
                validator: _rtRwValidator,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _textField(_fields['alamat_detail']!, 'Alamat detail', maxLines: 3),
          if (widget.school != null) ...[
            const SizedBox(height: 16),
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text('Sekolah aktif'),
                subtitle: const Text(
                  'Sekolah aktif dapat dipilih pada aplikasi orang tua.',
                ),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(managementRepositoryProvider).saveSchool({
        for (final key in _fields.keys) key: _fields[key]!.text.trim(),
        'jenjang': _level,
        'aktif': _active,
      }, id: _id(widget.school));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiClient.errorMessage(error);
        });
      }
    }
  }
}

class _MenuFormDialog extends ConsumerStatefulWidget {
  const _MenuFormDialog({required this.schools, this.menu});
  final List<Map<String, dynamic>> schools;
  final Map<String, dynamic>? menu;

  @override
  ConsumerState<_MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends ConsumerState<_MenuFormDialog> {
  static const _allergenOptions = [
    'telur',
    'susu',
    'kacang',
    'seafood',
    'gluten',
    'kedelai',
    'lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late final List<_ComponentDraft> _components;
  late final Map<String, TextEditingController> _allergenNotes;
  late final Set<String> _allergens;
  late int _schoolId;
  late String _status;
  late bool _active;
  final _templateName = TextEditingController();
  List<Map<String, dynamic>> _catalogIngredients = const [];
  List<Map<String, dynamic>> _menuTemplates = const [];
  int? _selectedTemplateId;
  late bool _automatic;
  bool _saveAsTemplate = false;
  bool _catalogLoading = true;
  String? _catalogError;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fields = _controllers(widget.menu, const [
      'tanggal_menu',
      'nama_menu',
      'deskripsi',
      'kalori',
      'protein',
      'lemak',
      'karbohidrat',
      'sumber_data_gizi',
      'url_sumber_data_gizi',
    ]);
    if (_fields['tanggal_menu']!.text.isEmpty) {
      _fields['tanggal_menu']!.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
    }
    if (_fields['sumber_data_gizi']!.text.isEmpty) {
      _fields['sumber_data_gizi']!.text = 'PanganKu/TKPI';
      _fields['url_sumber_data_gizi']!.text = 'https://panganku.org/';
    }
    final rawComponents =
        widget.menu?['komponen'] as List<dynamic>? ?? const [];
    _components = rawComponents.isEmpty
        ? [_ComponentDraft()]
        : rawComponents
              .map(
                (item) => _ComponentDraft.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
    _automatic =
        widget.menu == null ||
        (rawComponents.isNotEmpty &&
            rawComponents.every(
              (item) => (item as Map)['id_bahan_pangan'] != null,
            ));
    if (_automatic) _setOfficialSource();
    final rawAllergens = widget.menu?['alergi'] as List<dynamic>? ?? const [];
    _allergens = rawAllergens
        .map((item) => (item as Map)['nama_alergi']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    _allergenNotes = {
      for (final option in _allergenOptions)
        option: TextEditingController(
          text: rawAllergens
              .cast<Map>()
              .where((item) => item['nama_alergi'] == option)
              .map((item) => item['keterangan']?.toString() ?? '')
              .firstOrNull,
        ),
    };
    _schoolId = (widget.menu?['id_sekolah'] as num?)?.toInt() ?? 0;
    _status = widget.menu?['status']?.toString() ?? 'draf';
    _active = widget.menu?['aktif'] != false;
    _loadCatalog();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final component in _components) {
      component.dispose();
    }
    for (final controller in _allergenNotes.values) {
      controller.dispose();
    }
    _templateName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
    title: widget.menu == null ? 'Tambah menu harian' : 'Ubah menu harian',
    subtitle: 'Nilai gizi diisi berdasarkan sumber data yang dapat diperiksa.',
    width: 820,
    saving: _saving,
    error: _error,
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _catalogComposer(),
          const SizedBox(height: 24),
          _sectionTitle('Informasi menu'),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              TextFormField(
                controller: _fields['tanggal_menu'],
                readOnly: true,
                onTap: _selectDate,
                validator: _requiredValidator,
                decoration: const InputDecoration(
                  labelText: 'Tanggal menu',
                  suffixIcon: Icon(LucideIcons.calendarDays),
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: _schoolId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cakupan sekolah'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Semua sekolah'),
                  ),
                  ...widget.schools
                      .where((item) => item['aktif'] == true)
                      .map(
                        (item) => DropdownMenuItem(
                          value: (item['id'] as num).toInt(),
                          child: Text(item['nama']?.toString() ?? '-'),
                        ),
                      ),
                ],
                onChanged: (value) => setState(() => _schoolId = value ?? 0),
              ),
              _textField(_fields['nama_menu']!, 'Nama menu'),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status publikasi',
                ),
                items: const [
                  DropdownMenuItem(value: 'draf', child: Text('Draf')),
                  DropdownMenuItem(
                    value: 'dipublikasikan',
                    child: Text('Dipublikasikan'),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'draf'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _textField(_fields['deskripsi']!, 'Deskripsi menu', maxLines: 3),
          const SizedBox(height: 24),
          _sectionTitle('Nilai nutrisi'),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _nutritionField(
                _fields['kalori']!,
                'Kalori',
                'kkal',
                readOnly: _automatic,
              ),
              _nutritionField(
                _fields['protein']!,
                'Protein',
                'gram',
                readOnly: _automatic,
              ),
              _nutritionField(
                _fields['lemak']!,
                'Lemak',
                'gram',
                readOnly: _automatic,
              ),
              _nutritionField(
                _fields['karbohidrat']!,
                'Karbohidrat',
                'gram',
                readOnly: _automatic,
              ),
              _textField(
                _fields['sumber_data_gizi']!,
                'Sumber data gizi',
                readOnly: _automatic,
              ),
              _textField(
                _fields['url_sumber_data_gizi']!,
                'Tautan sumber data',
                readOnly: _automatic,
                keyboardType: TextInputType.url,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (!text.startsWith('http://') &&
                      !text.startsWith('https://')) {
                    return 'Tautan harus diawali http:// atau https://';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _sectionTitle('Komponen makanan')),
              TextButton.icon(
                onPressed: _components.length >= 20 ? null : _addComponent,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Tambah komponen'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < _components.length; index++)
            _componentRow(index),
          const SizedBox(height: 20),
          _sectionTitle('Kategori alergi'),
          const SizedBox(height: 8),
          Text(
            'Centang berdasarkan bahan pada menu, lalu tambahkan keterangan bila diperlukan.',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_automatic)
            _automaticAllergySummary()
          else
            for (final option in _allergenOptions) _allergenField(option),
          if (_automatic) ...[
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simpan komposisi sebagai template unit'),
              subtitle: const Text(
                'Template dapat dipakai kembali oleh admin unit ini.',
              ),
              value: _saveAsTemplate,
              onChanged: (value) => setState(() => _saveAsTemplate = value),
            ),
            if (_saveAsTemplate)
              _textField(
                _templateName,
                'Nama template baru',
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Nama template minimal 3 karakter'
                    : null,
              ),
          ],
          if (widget.menu != null) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Menu aktif'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _catalogComposer() {
    if (_catalogLoading) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_catalogError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.redSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.triangleAlert, color: AppColors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(_catalogError!)),
            TextButton(
              onPressed: () => setState(() => _automatic = false),
              child: const Text('Pakai manual'),
            ),
            TextButton(onPressed: _loadCatalog, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.calculator,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalkulator menu berbasis bahan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Nilai nutrisi dan alergi dihitung otomatis dari berat bahan TKPI.',
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
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(LucideIcons.sparkles, size: 17),
                label: Text('Otomatis'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(LucideIcons.pencilLine, size: 17),
                label: Text('Manual'),
              ),
            ],
            selected: {_automatic},
            onSelectionChanged: (value) => _setAutomatic(value.first),
          ),
          if (_automatic) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              key: ValueKey(
                'menu-template-$_selectedTemplateId-${_menuTemplates.length}',
              ),
              initialValue:
                  _menuTemplates.any(
                    (item) =>
                        (item['id'] as num?)?.toInt() == _selectedTemplateId,
                  )
                  ? _selectedTemplateId
                  : null,
              isExpanded: true,
              menuMaxHeight: 340,
              decoration: const InputDecoration(
                labelText: 'Mulai dari template (opsional)',
                prefixIcon: Icon(LucideIcons.layoutTemplate, size: 18),
              ),
              hint: const Text('Susun sendiri dari katalog bahan'),
              items: _menuTemplates
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: (item['id'] as num).toInt(),
                      child: Text(
                        '${item['nama']}${item['bawaan_sistem'] == true ? (item['terverifikasi'] == true ? ' - Terverifikasi' : ' - Referensi') : ' - Unit'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id != null) _applyTemplate(id);
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Template adalah komposisi awal, bukan daftar menu wajib BGN. Ahli gizi tetap perlu menilai kelompok usia, proses memasak, dan kebutuhan penerima.',
              style: TextStyle(
                color: AppColors.textMuted(context),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _automaticAllergySummary() {
    if (_allergens.isEmpty) {
      return Text(
        'Tidak ada kategori alergi yang terdeteksi dari bahan terpilih.',
        style: TextStyle(color: AppColors.textMuted(context)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final allergy in _allergens)
          Chip(
            avatar: const Icon(LucideIcons.triangleAlert, size: 15),
            label: Text(_label(allergy)),
          ),
      ],
    );
  }

  Future<void> _loadCatalog() async {
    if (mounted) {
      setState(() {
        _catalogLoading = true;
        _catalogError = null;
      });
    }
    try {
      final data = await ref
          .read(managementRepositoryProvider)
          .getMenuCatalog();
      if (!mounted) return;
      setState(() {
        _catalogIngredients = (data['bahan'] as List<dynamic>? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _menuTemplates = (data['template'] as List<dynamic>? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _catalogLoading = false;
      });
      if (_automatic && widget.menu != null) _recalculateNutrition();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = ApiClient.errorMessage(error);
      });
    }
  }

  void _setAutomatic(bool value) {
    setState(() {
      _automatic = value;
      _selectedTemplateId = null;
      if (value) {
        for (final component in _components) {
          component.dispose();
        }
        _components
          ..clear()
          ..add(_ComponentDraft());
        _allergens.clear();
        _setOfficialSource();
        _recalculateNutrition(notify: false);
      }
    });
  }

  void _applyTemplate(int id) {
    final template = _menuTemplates.firstWhere(
      (item) => (item['id'] as num).toInt() == id,
    );
    final ingredients = template['bahan'] as List<dynamic>? ?? const [];
    setState(() {
      _selectedTemplateId = id;
      for (final component in _components) {
        component.dispose();
      }
      _components
        ..clear()
        ..addAll(
          ingredients.map(
            (item) => _ComponentDraft.fromCatalogMap(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
      _fields['nama_menu']!.text = template['nama']?.toString() ?? '';
      _fields['deskripsi']!.text = template['deskripsi']?.toString() ?? '';
      _templateName.text = '${template['nama']} - variasi';
      _setOfficialSource();
      _recalculateNutrition(notify: false);
    });
  }

  void _setOfficialSource() {
    _fields['sumber_data_gizi']!.text = 'TKPI Kementerian Kesehatan RI 2020';
    _fields['url_sumber_data_gizi']!.text =
        'https://repository.kemkes.go.id/book/668';
  }

  void _recalculateNutrition({bool notify = true}) {
    var calories = 0.0;
    var protein = 0.0;
    var fat = 0.0;
    var carbs = 0.0;
    final allergies = <String>{};
    for (final component in _components) {
      final ingredientId = component.ingredientId;
      final weight = double.tryParse(component.weight.text.trim());
      if (ingredientId == null || weight == null || weight <= 0) continue;
      final ingredient = _catalogIngredients.where(
        (item) => (item['id'] as num?)?.toInt() == ingredientId,
      );
      if (ingredient.isEmpty) continue;
      final item = ingredient.first;
      final factor = weight / 100;
      calories += ((item['energi_per_100g'] as num?)?.toDouble() ?? 0) * factor;
      protein += ((item['protein_per_100g'] as num?)?.toDouble() ?? 0) * factor;
      fat += ((item['lemak_per_100g'] as num?)?.toDouble() ?? 0) * factor;
      carbs +=
          ((item['karbohidrat_per_100g'] as num?)?.toDouble() ?? 0) * factor;
      allergies.addAll(
        (item['alergi'] as List<dynamic>? ?? const []).map((e) => e.toString()),
      );
    }
    void update() {
      _fields['kalori']!.text = calories.round().toString();
      _fields['protein']!.text = _formatNutrient(protein);
      _fields['lemak']!.text = _formatNutrient(fat);
      _fields['karbohidrat']!.text = _formatNutrient(carbs);
      _allergens
        ..clear()
        ..addAll(allergies);
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  String _formatNutrient(double value) {
    final result = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return result.isEmpty ? '0' : result;
  }

  Widget _componentRow(int index) {
    final component = _components[index];
    if (_automatic) return _catalogComponentRow(index, component);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final removeButton = IconButton(
            tooltip: 'Hapus komponen',
            onPressed: _components.length == 1
                ? null
                : () => _removeComponent(index),
            icon: const Icon(LucideIcons.trash2, size: 18),
          );
          final name = _textField(component.name, 'Nama komponen ${index + 1}');
          final portion = _textField(
            component.portion,
            'Porsi (opsional)',
            required: false,
          );

          if (constraints.maxWidth < 520) {
            return Column(
              children: [
                name,
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: portion),
                    const SizedBox(width: 4),
                    removeButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: name),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: portion),
              const SizedBox(width: 4),
              removeButton,
            ],
          );
        },
      ),
    );
  }

  Widget _catalogComponentRow(int index, _ComponentDraft component) {
    final removeButton = IconButton(
      tooltip: 'Hapus bahan',
      onPressed: _components.length == 1 ? null : () => _removeComponent(index),
      icon: const Icon(LucideIcons.trash2, size: 18),
    );
    final ingredient = DropdownButtonFormField<int>(
      key: ValueKey(
        'ingredient-$index-${component.ingredientId}-${_catalogIngredients.length}',
      ),
      initialValue:
          _catalogIngredients.any(
            (item) => (item['id'] as num?)?.toInt() == component.ingredientId,
          )
          ? component.ingredientId
          : null,
      isExpanded: true,
      menuMaxHeight: 340,
      decoration: InputDecoration(labelText: 'Bahan ${index + 1}'),
      validator: (value) => value == null ? 'Pilih bahan dari katalog' : null,
      items: _catalogIngredients
          .map(
            (item) => DropdownMenuItem<int>(
              value: (item['id'] as num).toInt(),
              child: Text(
                '${item['nama']} (${item['kode_tkpi']})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        component.ingredientId = value;
        _selectedTemplateId = null;
        _recalculateNutrition();
      },
    );
    final weight = TextFormField(
      controller: component.weight,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Berat saji',
        suffixText: 'gram',
      ),
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');
        return number == null || number <= 0 || number > 2000
            ? 'Isi 0-2000 gram'
            : null;
      },
      onChanged: (_) {
        _selectedTemplateId = null;
        _recalculateNutrition();
      },
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                ingredient,
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: weight),
                    const SizedBox(width: 4),
                    removeButton,
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: ingredient),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: weight),
              const SizedBox(width: 4),
              removeButton,
            ],
          );
        },
      ),
    );
  }

  Widget _allergenField(String option) => Column(
    children: [
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(_label(option)),
        value: _allergens.contains(option),
        onChanged: (selected) {
          setState(() {
            selected == true
                ? _allergens.add(option)
                : _allergens.remove(option);
          });
        },
      ),
      if (_allergens.contains(option)) ...[
        _textField(
          _allergenNotes[option]!,
          'Keterangan ${_label(option)} (opsional)',
          required: false,
        ),
        const SizedBox(height: 8),
      ],
    ],
  );

  void _addComponent() => setState(() {
    _components.add(_ComponentDraft());
    _selectedTemplateId = null;
  });

  void _removeComponent(int index) {
    setState(() {
      final removed = _components.removeAt(index);
      removed.dispose();
      _selectedTemplateId = null;
      if (_automatic) _recalculateNutrition(notify: false);
    });
  }

  Future<void> _selectDate() async {
    final initial =
        DateTime.tryParse(_fields['tanggal_menu']!.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected != null) {
      _fields['tanggal_menu']!.text = DateFormat('yyyy-MM-dd').format(selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_automatic && _saveAsTemplate) {
        await ref.read(managementRepositoryProvider).createMenuTemplate({
          'nama': _templateName.text.trim(),
          'deskripsi': _fields['deskripsi']!.text.trim(),
          'bahan': [
            for (final component in _components)
              {
                'id_bahan_pangan': component.ingredientId,
                'berat_gram': double.parse(component.weight.text.trim()),
              },
          ],
        });
      }
      await ref.read(managementRepositoryProvider).saveMenu({
        'id_sekolah': _schoolId == 0 ? null : _schoolId,
        'tanggal_menu': _fields['tanggal_menu']!.text.trim(),
        'nama_menu': _fields['nama_menu']!.text.trim(),
        'deskripsi': _fields['deskripsi']!.text.trim(),
        'kalori': int.parse(_fields['kalori']!.text.trim()),
        'protein': double.parse(_fields['protein']!.text.trim()),
        'lemak': double.parse(_fields['lemak']!.text.trim()),
        'karbohidrat': double.parse(_fields['karbohidrat']!.text.trim()),
        'sumber_data_gizi': _fields['sumber_data_gizi']!.text.trim(),
        'url_sumber_data_gizi': _fields['url_sumber_data_gizi']!.text.trim(),
        'status': _status,
        'aktif': _active,
        'komponen': [
          for (var index = 0; index < _components.length; index++)
            {
              'id_bahan_pangan': _automatic
                  ? _components[index].ingredientId
                  : null,
              'nama_komponen': _components[index].name.text.trim(),
              'keterangan_porsi': _nullable(_components[index].portion.text),
              'berat_gram': _automatic
                  ? double.parse(_components[index].weight.text.trim())
                  : null,
              'urutan': index + 1,
            },
        ],
        'alergi': [
          for (final option in _allergens)
            {
              'nama_alergi': option,
              'keterangan': _nullable(_allergenNotes[option]!.text),
            },
        ],
      }, id: _id(widget.menu));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiClient.errorMessage(error);
        });
      }
    }
  }
}

class _MenuMediaDialog extends ConsumerStatefulWidget {
  const _MenuMediaDialog({required this.menu});
  final Map<String, dynamic> menu;

  @override
  ConsumerState<_MenuMediaDialog> createState() => _MenuMediaDialogState();
}

class _MenuMediaDialogState extends ConsumerState<_MenuMediaDialog> {
  late final List<Map<String, dynamic>> _media;
  final Set<int> _deleting = {};
  bool _uploading = false;
  bool _changed = false;
  double _progress = 0;
  int _uploadCurrent = 0;
  int _uploadTotal = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final source = widget.menu['media'] as List<dynamic>? ?? const [];
    _media = source
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 820, maxHeight: size.height - 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Media dokumentasi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.menu['nama_menu']?.toString() ?? 'Menu harian',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: _uploading
                        ? null
                        : () => Navigator.pop(context, _changed),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _uploading ? null : _pickAndUpload,
                          icon: const Icon(LucideIcons.images, size: 18),
                          label: const Text('Pilih foto & video'),
                        ),
                        Text(
                          '${_media.length} berkas | Pilih maksimal 10 berkas campuran',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Foto maksimal 30 MB. Video maksimal 100 MB, 60 detik, 1080p, dan 60 fps.',
                      style: TextStyle(
                        color: AppColors.textMuted(context),
                        fontSize: 12,
                      ),
                    ),
                    if (_uploading) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 6),
                      Text(
                        'Mengunggah $_uploadCurrent dari $_uploadTotal | ${(_progress * 100).round()}%',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.redSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_media.isEmpty)
                      Container(
                        height: 180,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.images,
                              size: 30,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Belum ada media dokumentasi',
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 660 ? 2 : 1;
                          const gap = 14.0;
                          final cardWidth =
                              (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: _media
                                .map(
                                  (item) => SizedBox(
                                    width: cardWidth,
                                    child: _MediaItem(
                                      item: item,
                                      mediaUrl: _absoluteMediaUrl(
                                        baseUrl,
                                        item['url_berkas']?.toString() ?? '',
                                      ),
                                      deleting: _deleting.contains(
                                        (item['id'] as num).toInt(),
                                      ),
                                      onDelete: () => _deleteMedia(item),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _uploading
                      ? null
                      : () => Navigator.pop(context, _changed),
                  child: const Text('Selesai'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'mp4',
        'webm',
        'mov',
      ],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;
    final files = result.files;
    if (files.length > 10) {
      setState(() => _error = 'Pilih maksimal 10 berkas dalam satu unggahan');
      return;
    }

    final validationErrors = <String>[];
    for (final file in files) {
      final extension = file.extension?.toLowerCase() ?? '';
      final photo = ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
      final limit = photo ? 30 * 1024 * 1024 : 100 * 1024 * 1024;
      if (file.bytes == null) {
        validationErrors.add('${file.name}: berkas tidak dapat dibaca');
      } else if (file.size > limit) {
        validationErrors.add(
          '${file.name}: maksimal ${photo ? '30 MB' : '100 MB'}',
        );
      }
    }
    if (validationErrors.isNotEmpty) {
      setState(() => _error = validationErrors.join('\n'));
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
      _uploadCurrent = 1;
      _uploadTotal = files.length;
      _error = null;
    });

    final uploadedItems = <Map<String, dynamic>>[];
    final failedItems = <String>[];
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      if (!mounted) return;
      setState(() => _uploadCurrent = index + 1);
      try {
        final uploaded = await ref
            .read(managementRepositoryProvider)
            .uploadMenuMedia(
              _id(widget.menu)!,
              bytes: file.bytes!,
              fileName: file.name,
              onSendProgress: (sent, total) {
                if (!mounted || total <= 0) return;
                final fileProgress = sent / total;
                setState(
                  () => _progress = (index + fileProgress) / files.length,
                );
              },
            );
        uploadedItems.add(uploaded);
      } catch (error) {
        failedItems.add('${file.name}: ${ApiClient.errorMessage(error)}');
      }
    }

    if (!mounted) return;
    setState(() {
      _media.insertAll(0, uploadedItems);
      _uploading = false;
      _progress = 1;
      _changed = _changed || uploadedItems.isNotEmpty;
      _error = failedItems.isEmpty ? null : failedItems.join('\n');
    });
    if (uploadedItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${uploadedItems.length} media berhasil diunggah'),
        ),
      );
    }
  }

  Future<void> _deleteMedia(Map<String, dynamic> item) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus media?'),
            content: Text(
              '${item['nama_berkas'] ?? 'Media'} akan dihapus dari dokumentasi menu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final id = (item['id'] as num).toInt();
    setState(() {
      _deleting.add(id);
      _error = null;
    });
    try {
      await ref.read(managementRepositoryProvider).deleteMenuMedia(id);
      if (!mounted) return;
      setState(() {
        _deleting.remove(id);
        _media.removeWhere((media) => (media['id'] as num).toInt() == id);
        _changed = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting.remove(id);
        _error = ApiClient.errorMessage(error);
      });
    }
  }
}

class _MediaItem extends StatelessWidget {
  const _MediaItem({
    required this.item,
    required this.mediaUrl,
    required this.deleting,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final String mediaUrl;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final photo = item['jenis_media'] == 'foto';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: photo
                  ? Image.network(
                      mediaUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          LucideIcons.imageOff,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  : _VideoPreview(url: mediaUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama_berkas']?.toString() ?? 'Media',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${photo ? 'Foto' : 'Video'} | ${_formatBytes(item['ukuran_byte'])}',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                deleting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Hapus media',
                        onPressed: onDelete,
                        color: AppColors.red,
                        icon: const Icon(LucideIcons.trash2, size: 18),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintDetailDialog extends ConsumerStatefulWidget {
  const _ComplaintDetailDialog({required this.complaint});
  final Map<String, dynamic> complaint;

  @override
  ConsumerState<_ComplaintDetailDialog> createState() =>
      _ComplaintDetailDialogState();
}

class _ComplaintDetailDialogState
    extends ConsumerState<_ComplaintDetailDialog> {
  late String _status;
  late String _savedStatus;
  bool _saving = false;
  bool _changed = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _status = widget.complaint['status']?.toString() ?? 'baru';
    _savedStatus = _status;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final media = (widget.complaint['media'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 980, maxHeight: size.height - 32),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.redSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.messageSquareWarning,
                      color: AppColors.red,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail aduan #${widget.complaint['id'] ?? '-'}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.complaint['nama_sekolah'] ?? '-'} | ${_complaintDate(widget.complaint['created_at']?.toString())}',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context, _changed),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = _ComplaintDetails(
                      complaint: widget.complaint,
                    );
                    final evidence = _ComplaintEvidence(
                      media: media,
                      baseUrl: baseUrl,
                    );
                    if (constraints.maxWidth < 760) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          details,
                          const SizedBox(height: 24),
                          evidence,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: details),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: evidence),
                      ],
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null || _message != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _error == null
                            ? AppColors.primarySoft
                            : AppColors.redSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _error ?? _message!,
                        style: TextStyle(
                          color: _error == null
                              ? AppColors.primaryDark
                              : AppColors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final statusField = DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status tindak lanjut',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'baru', child: Text('Baru')),
                          DropdownMenuItem(
                            value: 'diproses',
                            child: Text('Diproses'),
                          ),
                          DropdownMenuItem(
                            value: 'selesai',
                            child: Text('Selesai'),
                          ),
                          DropdownMenuItem(
                            value: 'ditolak',
                            child: Text('Ditolak'),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() {
                                _status = value ?? 'baru';
                                _message = null;
                              }),
                      );
                      final saveButton = FilledButton.icon(
                        onPressed: _saving || _status == _savedStatus
                            ? null
                            : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.save, size: 18),
                        label: Text(_saving ? 'Menyimpan...' : 'Simpan status'),
                      );
                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            statusField,
                            const SizedBox(height: 10),
                            saveButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: statusField),
                          const SizedBox(width: 12),
                          saveButton,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      await ref
          .read(managementRepositoryProvider)
          .updateComplaintStatus(_id(widget.complaint)!, _status);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _changed = true;
        _savedStatus = _status;
        _message = 'Status aduan berhasil diperbarui.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiClient.errorMessage(error);
        });
      }
    }
  }
}

class _ComplaintDetails extends StatelessWidget {
  const _ComplaintDetails({required this.complaint});

  final Map<String, dynamic> complaint;

  @override
  Widget build(BuildContext context) {
    final rating = (complaint['nilai_kepuasan'] as num?)?.toInt() ?? 0;
    final menu = complaint['nama_menu']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailTitle('Informasi laporan'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DetailTag(
              icon: LucideIcons.tag,
              label: _complaintLabel(
                complaint['kategori']?.toString() ?? 'lainnya',
              ),
              color: AppColors.orange,
              background: AppColors.orangeSoft,
            ),
            _DetailTag(
              icon: LucideIcons.circleDot,
              label: _complaintLabel(complaint['status']?.toString() ?? 'baru'),
              color: AppColors.primaryDark,
              background: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DetailLine(
          icon: LucideIcons.school,
          label: 'Sekolah',
          value: complaint['nama_sekolah']?.toString() ?? '-',
        ),
        if (menu != null && menu.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DetailLine(
            icon: LucideIcons.utensils,
            label: 'Menu terkait',
            value: menu,
          ),
        ],
        const SizedBox(height: 12),
        _DetailLine(
          icon: LucideIcons.calendarClock,
          label: 'Waktu diterima',
          value: _complaintDate(complaint['created_at']?.toString()),
        ),
        const SizedBox(height: 20),
        _detailTitle('Nilai kepuasan'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var index = 1; index <= 5; index++) ...[
              Icon(
                LucideIcons.star,
                size: 20,
                color: index <= rating ? AppColors.orange : AppColors.border,
              ),
              if (index < 5) const SizedBox(width: 4),
            ],
            const SizedBox(width: 10),
            Text(
              '$rating / 5',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _detailTitle('Isi aduan'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            complaint['isi_aduan']?.toString() ?? '-',
            style: const TextStyle(color: AppColors.ink, height: 1.55),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.shieldCheck, size: 17, color: AppColors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Laporan anonim. Sistem tidak menyimpan NIK, KK, nama anak, atau identitas orang tua.',
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComplaintEvidence extends StatelessWidget {
  const _ComplaintEvidence({required this.media, required this.baseUrl});

  final List<Map<String, dynamic>> media;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailTitle('Bukti laporan'),
        const SizedBox(height: 12),
        if (media.isEmpty)
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.fileX, size: 30, color: AppColors.muted),
                SizedBox(height: 8),
                Text('Bukti media tidak tersedia'),
              ],
            ),
          )
        else
          for (var index = 0; index < media.length; index++) ...[
            _ComplaintMediaItem(
              item: media[index],
              url: _absoluteMediaUrl(
                baseUrl,
                media[index]['url_berkas']?.toString() ?? '',
              ),
            ),
            if (index < media.length - 1) const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _ComplaintMediaItem extends StatelessWidget {
  const _ComplaintMediaItem({required this.item, required this.url});

  final Map<String, dynamic> item;
  final String url;

  @override
  Widget build(BuildContext context) {
    final photo = item['jenis_media'] == 'foto';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: photo
                  ? Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          LucideIcons.imageOff,
                          color: AppColors.muted,
                          size: 30,
                        ),
                      ),
                    )
                  : _VideoPreview(url: url),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_berkas']?.toString() ?? 'Bukti media',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${photo ? 'Foto' : 'Video'} | ${_formatBytes(item['ukuran_byte'])}${photo ? '' : ' | ${item['durasi_detik'] ?? 0} detik'}',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.url});

  final String url;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final VideoPlayerController _controller;
  Object? _error;
  bool _fullscreenOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
        .initialize()
        .then((_) async {
          await _controller.setLooping(false);
          if (mounted) setState(() {});
        })
        .catchError((Object error) {
          if (mounted) setState(() => _error = error);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileWarning, color: AppColors.muted, size: 30),
            SizedBox(height: 7),
            Text('Video belum dapat diputar'),
          ],
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: _fullscreenOpen
                  ? const ColoredBox(color: Colors.black)
                  : VideoPlayer(_controller),
            ),
          ),
          Center(
            child: IconButton.filled(
              tooltip: _controller.value.isPlaying ? 'Jeda' : 'Putar video',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_controller.value.isPlaying) {
                  await _controller.pause();
                } else {
                  if (_controller.value.position >=
                      _controller.value.duration) {
                    await _controller.seekTo(Duration.zero);
                  }
                  await _controller.play();
                }
                if (mounted) setState(() {});
              },
              icon: Icon(
                _controller.value.isPlaying
                    ? LucideIcons.pause
                    : LucideIcons.play,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: 'Tonton layar penuh',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              onPressed: _openFullscreen,
              icon: const Icon(LucideIcons.maximize, size: 19),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 7,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullscreen() async {
    setState(() => _fullscreenOpen = true);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _FullscreenVideo(controller: _controller),
    );
    if (mounted) setState(() => _fullscreenOpen = false);
  }
}

class _FullscreenVideo extends StatelessWidget {
  const _FullscreenVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.black,
    child: SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: IconButton.filledTonal(
                tooltip: 'Keluar dari layar penuh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.minimize, size: 21),
              ),
            ),
            Center(
              child: IconButton.filled(
                tooltip: controller.value.isPlaying ? 'Jeda' : 'Putar video',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(58, 58),
                ),
                onPressed: () async {
                  if (controller.value.isPlaying) {
                    await controller.pause();
                  } else {
                    if (controller.value.position >=
                        controller.value.duration) {
                      await controller.seekTo(Duration.zero);
                    }
                    await controller.play();
                  }
                },
                icon: Icon(
                  controller.value.isPlaying
                      ? LucideIcons.pause
                      : LucideIcons.play,
                  size: 28,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 22,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailTag extends StatelessWidget {
  const _DetailTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _detailTitle(String text) => Text(
  text,
  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
);

String _complaintLabel(String value) {
  if (value == 'makanan_rusak') return 'Makanan Basi';
  return value
      .split('_')
      .map((part) => part.isEmpty ? part : _label(part))
      .join(' ');
}

String _complaintDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(date);
}

class _FormDialog extends StatelessWidget {
  const _FormDialog({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.saving,
    required this.onSave,
    this.error,
    this.width = 740,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool saving;
  final VoidCallback onSave;
  final String? error;
  final double width;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogTheme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
          gapPadding: 6,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
          gapPadding: 6,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.6,
          ),
          gapPadding: 6,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.red),
          gapPadding: 6,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.red, width: 1.6),
          gapPadding: 6,
        ),
      ),
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: size.height - 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Theme(
                  data: dialogTheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      child,
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.redSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            error!,
                            style: const TextStyle(color: AppColors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.save, size: 18),
                    label: Text(saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
      if (subtitle case final text?) ...[
        const SizedBox(height: 3),
        Text(
          text,
          style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
        ),
      ],
    ],
  );
}

class _RegionDropdown extends StatelessWidget {
  const _RegionDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<Map<String, dynamic>> items;
  final bool loading;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = items.isNotEmpty;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value-${items.length}-$loading'),
      initialValue: available ? value : null,
      isExpanded: true,
      menuMaxHeight: 320,
      icon: loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.chevronDown, size: 17),
      hint: Text(
        loading
            ? 'Memuat data...'
            : enabled && !available
            ? 'Segera Datang'
            : 'Pilih $label',
      ),
      decoration: InputDecoration(labelText: label),
      validator: (selected) {
        if (enabled && !loading && !available) {
          return 'Data belum tersedia - Segera Datang';
        }
        return selected == null ? 'Pilih $label' : null;
      },
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item['kode']?.toString(),
              child: Text(
                item['nama']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: enabled && available && !loading ? onChanged : null,
    );
  }
}

class _PostalDropdown extends StatelessWidget {
  const _PostalDropdown({
    required this.value,
    required this.items,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final List<String> items;
  final bool loading;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = items.isNotEmpty;
    return DropdownButtonFormField<String>(
      key: ValueKey('kode-pos-$value-${items.length}-$loading'),
      initialValue: available ? value : null,
      isExpanded: true,
      icon: loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.chevronDown, size: 17),
      hint: Text(
        loading
            ? 'Memuat data...'
            : enabled && !available
            ? 'Segera Datang'
            : 'Pilih kode pos',
      ),
      decoration: const InputDecoration(labelText: 'Kode pos'),
      validator: (selected) {
        if (enabled && !loading && !available) {
          return 'Kode pos belum tersedia - Segera Datang';
        }
        return selected == null ? 'Pilih kode pos' : null;
      },
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(growable: false),
      onChanged: enabled && available && !loading ? onChanged : null,
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 580 ? 2 : 1;
      const gap = 18.0;
      final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class _ComponentDraft {
  _ComponentDraft({
    String name = '',
    String portion = '',
    this.ingredientId,
    String weight = '',
  }) : name = TextEditingController(text: name),
       portion = TextEditingController(text: portion),
       weight = TextEditingController(text: weight);

  factory _ComponentDraft.fromMap(Map<String, dynamic> data) => _ComponentDraft(
    name: data['nama_komponen']?.toString() ?? '',
    portion: data['keterangan_porsi']?.toString() ?? '',
    ingredientId: (data['id_bahan_pangan'] as num?)?.toInt(),
    weight: data['berat_gram']?.toString() ?? '',
  );

  factory _ComponentDraft.fromCatalogMap(Map<String, dynamic> data) =>
      _ComponentDraft(
        name: data['nama']?.toString() ?? '',
        portion: '${data['berat_gram']} gram',
        ingredientId: (data['id'] as num?)?.toInt(),
        weight: data['berat_gram']?.toString() ?? '',
      );

  final TextEditingController name;
  final TextEditingController portion;
  final TextEditingController weight;
  int? ingredientId;

  void dispose() {
    name.dispose();
    portion.dispose();
    weight.dispose();
  }
}

Map<String, TextEditingController> _controllers(
  Map<String, dynamic>? source,
  List<String> keys,
) => {
  for (final key in keys)
    key: TextEditingController(text: source?[key]?.toString() ?? ''),
};

TextFormField _textField(
  TextEditingController controller,
  String label, {
  bool required = true,
  int maxLines = 1,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  bool readOnly = false,
}) => TextFormField(
  controller: controller,
  readOnly: readOnly,
  maxLines: maxLines,
  keyboardType: keyboardType,
  validator: validator ?? (required ? _requiredValidator : null),
  decoration: InputDecoration(labelText: label),
);

TextFormField _nutritionField(
  TextEditingController controller,
  String label,
  String suffix, {
  bool readOnly = false,
}) => TextFormField(
  controller: controller,
  readOnly: readOnly,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  validator: (value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < 0 || (label == 'Kalori' && number == 0)) {
      return 'Masukkan angka yang valid';
    }
    if (label == 'Kalori' && number != number.roundToDouble()) {
      return 'Kalori harus berupa bilangan bulat';
    }
    return null;
  },
  decoration: InputDecoration(labelText: label, suffixText: suffix),
);

Widget _sectionTitle(String text) => Text(
  text,
  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
);

String? _requiredValidator(String? value) =>
    (value?.trim().isEmpty ?? true) ? 'Kolom ini wajib diisi' : null;

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  return email.contains('@') && email.contains('.')
      ? null
      : 'Masukkan email yang valid';
}

String? _passwordValidator(String? value) =>
    (value?.length ?? 0) >= 8 ? null : 'Password minimal 8 karakter';

String? _rtRwValidator(String? value) =>
    RegExp(r'^\d{1,3}$').hasMatch(value?.trim() ?? '')
    ? null
    : 'Isi dengan 1 sampai 3 angka';

int? _id(Map<String, dynamic>? data) => (data?['id'] as num?)?.toInt();

bool _containsCode(List<Map<String, dynamic>> data, String? code) =>
    code != null && data.any((item) => item['kode']?.toString() == code);

String _regionName(List<Map<String, dynamic>> data, String? code) =>
    data
        .firstWhere(
          (item) => item['kode']?.toString() == code,
          orElse: () => const {},
        )['nama']
        ?.toString() ??
    '';

String? _nullable(String value) {
  final result = value.trim();
  return result.isEmpty ? null : result;
}

String _label(String value) => '${value[0].toUpperCase()}${value.substring(1)}';

String _absoluteMediaUrl(String baseUrl, String relativeUrl) {
  final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
  return base.resolve(relativeUrl).toString();
}

String _formatBytes(dynamic value) {
  final bytes = (value as num?)?.toDouble() ?? 0;
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${bytes.toInt()} B';
}
