import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final darkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final wide = MediaQuery.sizeOf(context).width >= 880;

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            Expanded(
              flex: 4,
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(48),
                color: AppColors.sidebar,
                child: const _BrandPanel(),
              ),
            ),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 64 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!wide) ...[
                          const _CompactBrand(),
                          const SizedBox(height: 40),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Masuk ke dashboard',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              tooltip: darkMode
                                  ? 'Gunakan mode terang'
                                  : 'Gunakan mode gelap',
                              onPressed: () =>
                                  ref.read(themeModeProvider.notifier).toggle(),
                              icon: Icon(
                                darkMode ? LucideIcons.sun : LucideIcons.moon,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gunakan akun pengelola Nuara yang sudah terdaftar.',
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Email',
                            prefixIcon: Icon(LucideIcons.mail, size: 19),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'Masukkan email yang valid';
                            }
                            return null;
                          },
                          onChanged: (_) => ref
                              .read(authControllerProvider.notifier)
                              .clearError(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Password',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          textAlignVertical: TextAlignVertical.center,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Password',
                            prefixIcon: const Icon(LucideIcons.lock, size: 19),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: 19,
                              ),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) < 8
                              ? 'Password minimal 8 karakter'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                          onChanged: (_) => ref
                              .read(authControllerProvider.notifier)
                              .clearError(),
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.redSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.red.withAlpha(70),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.circleAlert,
                                  size: 18,
                                  color: AppColors.red,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF8F2525),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: auth.isLoading ? null : _submit,
                          icon: auth.isLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.logIn, size: 19),
                          label: Text(
                            auth.isLoading ? 'Memeriksa akun...' : 'Masuk',
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Nuara • Nutrisi Anak Nusantara',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      const Center(child: _LogoMark(size: 128)),
      const SizedBox(height: 28),
      const Text(
        'NUARA',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Nutrisi Anak Nusantara',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB9D9D3), fontSize: 18),
      ),
      const SizedBox(height: 24),
      Center(child: Container(width: 56, height: 4, color: AppColors.orange)),
      const SizedBox(height: 24),
      const Text(
        'Transparansi pangan, dari dapur hingga sekolah.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 21, height: 1.45),
      ),
      const Spacer(),
      const Text(
        'Dashboard operasional SPPG',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF86AEA7), fontSize: 13),
      ),
    ],
  );
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _LogoMark(dark: true),
      SizedBox(width: 12),
      Text(
        'NUARA',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({this.dark = false, this.size = 42});

  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.08),
    decoration: BoxDecoration(
      color: dark ? AppColors.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(size >= 80 ? 16 : 8),
    ),
    child: Image.asset('assets/branding/nuara-mark.png'),
  );
}
