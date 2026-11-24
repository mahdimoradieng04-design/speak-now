import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final name = ref.read(settingsProvider).name;
      context.go(name.isEmpty ? '/welcome' : '/home');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.record_voice_over, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text('Speak Now Exam Coach',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
        ),
      );
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeState();
}

class _WelcomeState extends ConsumerState<WelcomeScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    final s = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(s.copyWith(name: name));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.record_voice_over, size: 64, color: AppColors.navy),
              const SizedBox(height: 12),
              const Text('به Speak Now Exam Coach خوش آمدید',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 8),
              const Text(
                'آماده‌سازی برای آزمون شفاهی انگلیسی با یک ممتحن انگلیسی‌زبان.\n'
                'ممتحن فقط انگلیسی صحبت می‌کند؛ رابط برنامه فارسی است.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _go(),
                decoration: const InputDecoration(
                  labelText: 'نام شما',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _go, child: const Text('شروع'))),
            ]),
          ),
        ),
      );
}
