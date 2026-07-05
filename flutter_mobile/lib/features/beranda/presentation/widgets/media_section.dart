import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/menu_harian.dart';

class MediaSection extends StatefulWidget {
  const MediaSection({super.key, required this.media});

  final List<MediaMenu> media;

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection> {
  int _halaman = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.images,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Dokumentasi dapur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(LucideIcons.imageOff, color: AppColors.muted, size: 28),
                SizedBox(height: 9),
                Text(
                  'Dokumentasi belum diunggah untuk hari ini.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                LucideIcons.images,
                color: AppColors.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dokumentasi dapur',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Proses persiapan menu hari ini',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${_halaman + 1}/${widget.media.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: PageView.builder(
                itemCount: widget.media.length,
                onPageChanged: (value) => setState(() => _halaman = value),
                itemBuilder: (context, index) {
                  final media = widget.media[index];
                  return media.video
                      ? _VideoDokumentasi(key: ValueKey(media.id), media: media)
                      : _FotoDokumentasi(media: media);
                },
              ),
            ),
          ),
        ),
        if (widget.media.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.media.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _halaman ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _halaman
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FotoDokumentasi extends StatelessWidget {
  const _FotoDokumentasi({required this.media});

  final MediaMenu media;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          alignment: Alignment.center,
          child: Image.network(
            media.url,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (_, _, _) =>
                const _MediaGagal(pesan: 'Foto belum dapat dimuat.'),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton.filledTonal(
            onPressed: () => _bukaFotoPenuh(context, media.url),
            tooltip: 'Lihat layar penuh',
            icon: const Icon(LucideIcons.maximize2, size: 18),
          ),
        ),
      ],
    );
  }
}

Future<void> _bukaFotoPenuh(BuildContext context, String url) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Dokumentasi foto'),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const _MediaGagal(pesan: 'Foto belum dapat dimuat.'),
            ),
          ),
        ),
      ),
    ),
  );
}

class _VideoDokumentasi extends StatefulWidget {
  const _VideoDokumentasi({super.key, required this.media});

  final MediaMenu media;

  @override
  State<_VideoDokumentasi> createState() => _VideoDokumentasiState();
}

class _VideoDokumentasiState extends State<_VideoDokumentasi> {
  late final VideoPlayerController _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url));
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          _controller.setLooping(false);
          setState(() {});
        })
        .catchError((Object error) {
          if (!mounted) return;
          setState(() => _error = error);
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
      return const ColoredBox(
        color: Color(0xFF192322),
        child: _MediaGagal(pesan: 'Video belum dapat diputar.'),
      );
    }
    if (!_controller.value.isInitialized) {
      return const ColoredBox(
        color: Color(0xFF192322),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          Center(
            child: IconButton.filled(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              tooltip: _controller.value.isPlaying ? 'Jeda' : 'Putar video',
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => _LayarPenuhVideo(
                    controller: _controller,
                    judul: widget.media.namaBerkas,
                  ),
                ),
              ),
              tooltip: 'Putar layar penuh',
              icon: const Icon(LucideIcons.maximize2, size: 18),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
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
}

class _LayarPenuhVideo extends StatefulWidget {
  const _LayarPenuhVideo({required this.controller, required this.judul});

  final VideoPlayerController controller;
  final String judul;

  @override
  State<_LayarPenuhVideo> createState() => _LayarPenuhVideoState();
}

class _LayarPenuhVideoState extends State<_LayarPenuhVideo> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_perbarui);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_perbarui);
    super.dispose();
  }

  void _perbarui() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.judul, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            Center(
              child: IconButton.filled(
                onPressed: () {
                  widget.controller.value.isPlaying
                      ? widget.controller.pause()
                      : widget.controller.play();
                },
                tooltip: widget.controller.value.isPlaying ? 'Jeda' : 'Putar',
                icon: Icon(
                  widget.controller.value.isPlaying
                      ? LucideIcons.pause
                      : LucideIcons.play,
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: VideoProgressIndicator(
                widget.controller,
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
      ),
    );
  }
}

class _MediaGagal extends StatelessWidget {
  const _MediaGagal({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.fileWarning,
              color: Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
