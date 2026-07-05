import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nuara_page_header.dart';
import '../../beranda/providers/beranda_providers.dart';
import '../../pilihan_sekolah/models/pilihan_tersimpan.dart';
import '../providers/aduan_providers.dart';

class AduanPage extends ConsumerStatefulWidget {
  const AduanPage({super.key, required this.pilihan});

  final PilihanTersimpan pilihan;

  @override
  ConsumerState<AduanPage> createState() => _AduanPageState();
}

class _AduanPageState extends ConsumerState<AduanPage> {
  static const _kategori = <String, String>{
    'rasa': 'Rasa makanan',
    'porsi': 'Porsi makanan',
    'kebersihan': 'Kebersihan',
    'makanan_rusak': 'Makanan basi',
    'benda_asing': 'Benda asing',
    'alergi': 'Masalah alergi',
    'lainnya': 'Lainnya',
  };
  static const _batasFoto = 30 * 1024 * 1024;
  static const _batasVideo = 100 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _isiController = TextEditingController();
  final _picker = ImagePicker();

  String? _kategoriTerpilih;
  int _kepuasan = 3;
  XFile? _bukti;
  int _ukuranBukti = 0;
  bool _buktiVideo = false;
  bool _mengirim = false;
  double _progres = 0;

  @override
  void initState() {
    super.initState();
    _pulihkanBukti();
  }

  @override
  void dispose() {
    _isiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NuaraPageHeader(
                    eyebrow: 'Aduan anonim',
                    title: 'Suara Orang Tua',
                    subtitle:
                        'Laporkan kondisi makanan dengan bukti agar dapat segera ditindaklanjuti.',
                    icon: LucideIcons.messageSquareWarning,
                  ),
                  const SizedBox(height: 16),
                  _IdentitasSekolah(pilihan: widget.pilihan),
                  const SizedBox(height: 16),
                  const _CatatanAnonim(),
                  const SizedBox(height: 18),
                  _BagianForm(
                    nomor: 1,
                    judul: 'Kategori aduan',
                    wajib: true,
                    child: DropdownButtonFormField<String>(
                      initialValue: _kategoriTerpilih,
                      isExpanded: true,
                      icon: const Icon(LucideIcons.chevronDown, size: 19),
                      hint: const Text('Pilih kategori masalah'),
                      items: _kategori.entries
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.key,
                              child: Text(
                                item.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _mengirim
                          ? null
                          : (value) =>
                                setState(() => _kategoriTerpilih = value),
                      validator: (value) => value == null
                          ? 'Pilih kategori aduan terlebih dahulu'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BagianForm(
                    nomor: 2,
                    judul: 'Nilai kepuasan',
                    child: _KepuasanField(
                      nilai: _kepuasan,
                      aktif: !_mengirim,
                      onChanged: (value) =>
                          setState(() => _kepuasan = value.round()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BagianForm(
                    nomor: 3,
                    judul: 'Ceritakan masalahnya',
                    wajib: true,
                    child: TextFormField(
                      controller: _isiController,
                      enabled: !_mengirim,
                      minLines: 5,
                      maxLines: 8,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText:
                            'Jelaskan kondisi makanan, waktu ditemukan, dan bagian yang bermasalah.',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final panjang = value?.trim().characters.length ?? 0;
                        if (panjang < 10) {
                          return 'Isi aduan minimal 10 karakter';
                        }
                        if (panjang > 2000) {
                          return 'Isi aduan maksimal 2000 karakter';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BagianForm(
                    nomor: 4,
                    judul: 'Bukti foto atau video',
                    wajib: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BuktiField(
                          file: _bukti,
                          ukuran: _ukuranBukti,
                          video: _buktiVideo,
                          aktif: !_mengirim,
                          onPilih: _tampilkanPilihanBukti,
                          onHapus: () {
                            setState(() {
                              _bukti = null;
                              _ukuranBukti = 0;
                              _buktiVideo = false;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Foto maksimal 30 MB. Video maksimal 100 MB dan 60 detik.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_mengirim) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: _progres),
                    const SizedBox(height: 7),
                    Text(
                      'Mengunggah ${(_progres * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _mengirim ? null : _kirim,
                    icon: const Icon(LucideIcons.send, size: 19),
                    label: Text(
                      _mengirim ? 'Mengirim aduan...' : 'Kirim aduan',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pulihkanBukti() async {
    final LostDataResponse response;
    try {
      response = await _picker.retrieveLostData();
    } catch (_) {
      return;
    }
    if (!mounted || response.isEmpty) return;
    final file = response.files?.firstOrNull;
    if (file != null) {
      await _terimaBukti(file);
      return;
    }
    _tampilkanPesan('Bukti sebelumnya tidak dapat dipulihkan. Pilih ulang.');
  }

  Future<void> _tampilkanPilihanBukti() async {
    final aksi = await showModalBottomSheet<_AksiBukti>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(context, _AksiBukti.fotoKamera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.video),
              title: const Text('Rekam video'),
              subtitle: const Text('Maksimal 60 detik'),
              onTap: () => Navigator.pop(context, _AksiBukti.videoKamera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Pilih foto dari galeri'),
              onTap: () => Navigator.pop(context, _AksiBukti.fotoGaleri),
            ),
            ListTile(
              leading: const Icon(LucideIcons.film),
              title: const Text('Pilih video dari galeri'),
              onTap: () => Navigator.pop(context, _AksiBukti.videoGaleri),
            ),
          ],
        ),
      ),
    );
    if (aksi == null) return;

    try {
      final XFile? file;
      switch (aksi) {
        case _AksiBukti.fotoKamera:
          file = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 90,
            requestFullMetadata: false,
          );
        case _AksiBukti.videoKamera:
          file = await _picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(seconds: 60),
          );
        case _AksiBukti.fotoGaleri:
          file = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
            requestFullMetadata: false,
          );
        case _AksiBukti.videoGaleri:
          file = await _picker.pickVideo(source: ImageSource.gallery);
      }
      if (file != null) await _terimaBukti(file);
    } catch (_) {
      _tampilkanPesan('Kamera atau galeri belum dapat dibuka.');
    }
  }

  Future<void> _terimaBukti(XFile file) async {
    final ekstensi = _ekstensi(file.name);
    final video = const ['mp4', 'webm', 'mov'].contains(ekstensi);
    final foto = const ['jpg', 'jpeg', 'png', 'webp'].contains(ekstensi);
    if (!video && !foto) {
      _tampilkanPesan('Gunakan JPG, PNG, WebP, MP4, WebM, atau MOV.');
      return;
    }

    final ukuran = await file.length();
    if (foto && ukuran > _batasFoto) {
      _tampilkanPesan('Ukuran foto melebihi batas 30 MB.');
      return;
    }
    if (video && ukuran > _batasVideo) {
      _tampilkanPesan('Ukuran video melebihi batas 100 MB.');
      return;
    }
    if (video && !await _durasiVideoValid(file)) return;
    if (!mounted) return;

    setState(() {
      _bukti = file;
      _ukuranBukti = ukuran;
      _buktiVideo = video;
    });
  }

  Future<bool> _durasiVideoValid(XFile file) async {
    final controller = VideoPlayerController.file(File(file.path));
    try {
      await controller.initialize();
      final detik = controller.value.duration.inMilliseconds / 1000;
      if (detik <= 0 || detik > 60.5) {
        _tampilkanPesan('Durasi video harus antara 1 dan 60 detik.');
        return false;
      }
      return true;
    } catch (_) {
      _tampilkanPesan('Video tidak dapat dibaca. Pilih video lain.');
      return false;
    } finally {
      await controller.dispose();
    }
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;
    final bukti = _bukti;
    if (bukti == null) {
      _tampilkanPesan('Foto atau video bukti wajib dilampirkan.');
      return;
    }

    setState(() {
      _mengirim = true;
      _progres = 0;
    });
    try {
      final menuHariIni = ref.read(
        menuHariIniProvider(widget.pilihan.idSekolah),
      );
      final idMenu = menuHariIni.whenOrNull(data: (menu) => menu.id);
      final hasil = await ref
          .read(aduanRepositoryProvider)
          .kirim(
            idUnitSppg: widget.pilihan.idUnitSppg,
            idSekolah: widget.pilihan.idSekolah,
            idMenuHarian: idMenu,
            kategori: _kategoriTerpilih!,
            isiAduan: _isiController.text.trim(),
            nilaiKepuasan: _kepuasan,
            pathBerkas: bukti.path,
            namaBerkas: bukti.name,
            onSendProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() => _progres = sent / total);
            },
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            LucideIcons.circleCheck,
            color: AppColors.primary,
            size: 38,
          ),
          title: const Text('Aduan berhasil dikirim'),
          content: Text(
            'Nomor aduan #${hasil.id}. Laporan masuk ke admin SPPG tanpa identitas orang tua atau anak.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
      _resetForm();
    } catch (error) {
      _tampilkanPesan(pesanDio(error));
    } finally {
      if (mounted) {
        setState(() {
          _mengirim = false;
          _progres = 0;
        });
      }
    }
  }

  void _resetForm() {
    _isiController.clear();
    setState(() {
      _kategoriTerpilih = null;
      _kepuasan = 3;
      _bukti = null;
      _ukuranBukti = 0;
      _buktiVideo = false;
    });
    _formKey.currentState?.reset();
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }
}

enum _AksiBukti { fotoKamera, videoKamera, fotoGaleri, videoGaleri }

class _IdentitasSekolah extends StatelessWidget {
  const _IdentitasSekolah({required this.pilihan});

  final PilihanTersimpan pilihan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.school, color: AppColors.primary, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pilihan.namaSekolah,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.onSoft),
                ),
                const SizedBox(height: 2),
                Text(
                  pilihan.namaUnitSppg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.onSoftMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BagianForm extends StatelessWidget {
  const _BagianForm({
    required this.nomor,
    required this.judul,
    required this.child,
    this.wajib = false,
  });

  final int nomor;
  final String judul;
  final Widget child;
  final bool wajib;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$nomor',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  judul,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (wajib)
                Text(
                  'Wajib',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KepuasanField extends StatelessWidget {
  const _KepuasanField({
    required this.nilai,
    required this.aktif,
    required this.onChanged,
  });

  final int nilai;
  final bool aktif;
  final ValueChanged<double> onChanged;

  static const _teks = {
    1: 'Sangat tidak puas',
    2: 'Tidak puas',
    3: 'Cukup',
    4: 'Puas',
    5: 'Sangat puas',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(5, (index) {
            final skor = index + 1;
            final dipilih = skor == nilai;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 4 ? 0 : 7),
                child: InkWell(
                  onTap: aktif ? () => onChanged(skor.toDouble()) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dipilih
                          ? AppColors.orangeSoft
                          : AppColors.surfaceMuted,
                      border: Border.all(
                        color: dipilih ? AppColors.orange : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$skor',
                      style: TextStyle(
                        color: dipilih
                            ? const Color(0xFF9B590C)
                            : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 9),
        Text(
          _teks[nilai]!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.orange,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BuktiField extends StatelessWidget {
  const _BuktiField({
    required this.file,
    required this.ukuran,
    required this.video,
    required this.aktif,
    required this.onPilih,
    required this.onHapus,
  });

  final XFile? file;
  final int ukuran;
  final bool video;
  final bool aktif;
  final VoidCallback onPilih;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.camera, color: AppColors.primary, size: 30),
            const SizedBox(height: 9),
            const Text(
              'Lampirkan kondisi makanan yang dilaporkan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: aktif ? onPilih : null,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Tambah bukti'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 68,
              height: 68,
              child: video
                  ? const ColoredBox(
                      color: Color(0xFF192322),
                      child: Icon(
                        LucideIcons.video,
                        color: Colors.white,
                        size: 27,
                      ),
                    )
                  : Image.file(
                      File(file!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.canvas,
                        child: Icon(LucideIcons.imageOff),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${video ? 'Video' : 'Foto'} · ${_formatUkuran(ukuran)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: aktif ? onHapus : null,
            tooltip: 'Hapus bukti',
            icon: const Icon(LucideIcons.trash2, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}

class _CatatanAnonim extends StatelessWidget {
  const _CatatanAnonim();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.shieldCheck, color: AppColors.blue, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Aduan dikirim tanpa NIK, KK, nama anak, nama orang tua, atau akun pengguna.',
              style: const TextStyle(
                color: AppColors.onSoftMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _ekstensi(String nama) {
  final index = nama.lastIndexOf('.');
  return index < 0 ? '' : nama.substring(index + 1).toLowerCase();
}

String _formatUkuran(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}
