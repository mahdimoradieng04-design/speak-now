import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name, _url, _token;
  List<Map<String, String>> _voices = [];

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _name = TextEditingController(text: s.name);
    _url = TextEditingController(text: s.backendUrl);
    _token = TextEditingController();
    ref.read(ttsProvider).englishVoices().then((v) {
      if (mounted) setState(() => _voices = v);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف همه‌ی داده‌ها؟'),
        content: const Text('تمام جلسه‌ها، پیشرفت، ویرایش درس‌ها، برنامه و تنظیمات از این دستگاه پاک می‌شود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(storeProvider).clearAll();
    await ref.read(secureStorageProvider).delete(key: 'api_token');
    ref.invalidate(settingsProvider);
    ref.invalidate(lessonsProvider);
    ref.invalidate(sessionsProvider);
    ref.invalidate(planProvider);
    if (mounted) {
      _name.clear();
      _url.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('داده‌ها حذف شد.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final voiceValue = _voices.any((v) => v['name'] == s.voiceName) ? s.voiceName : null;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'نام', border: OutlineInputBorder()),
          onChanged: (v) => notifier.update(ref.read(settingsProvider).copyWith(name: v.trim())),
        ),
        const SizedBox(height: 16),
        const Text('صدای ممتحن', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          isExpanded: true,
          value: voiceValue,
          hint: Text(_voices.isEmpty ? 'صدای انگلیسی پیدا نشد (پیش‌فرض دستگاه)' : 'انتخاب صدا'),
          items: [
            for (final v in _voices)
              DropdownMenuItem(value: v['name'], child: Text('${v['name']} (${v['locale']})')),
          ],
          onChanged: (name) {
            final v = _voices.firstWhere((e) => e['name'] == name);
            notifier.update(ref.read(settingsProvider).copyWith(voiceName: v['name'], voiceLocale: v['locale']));
          },
        ),
        Text('سرعت صحبت: ${s.speechRate.toStringAsFixed(2)}'),
        Slider(
          min: 0.2,
          max: 0.8,
          divisions: 12,
          value: s.speechRate.clamp(0.2, 0.8),
          onChanged: (v) => notifier.update(ref.read(settingsProvider).copyWith(speechRate: v)),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.volume_up),
          label: const Text('آزمایش صدا'),
          onPressed: () async {
            final tts = ref.read(ttsProvider);
            final cur = ref.read(settingsProvider);
            await tts.configure(cur.voiceName, cur.voiceLocale, cur.speechRate);
            await tts.speak('Hello! Tell me about your day.');
          },
        ),
        const Divider(height: 32),
        const Text('اتصال به هوش مصنوعی (اختیاری)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('بدون آدرس سرور، برنامه در حالت دمو و آفلاین کار می‌کند. کلید ارائه‌دهنده‌ی هوش مصنوعی هرگز در برنامه '
            'قرار نمی‌گیرد؛ فقط روی سرور شما نگهداری می‌شود.'),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _url,
            decoration: const InputDecoration(labelText: 'Backend URL (https://...)', border: OutlineInputBorder()),
            onChanged: (v) => notifier.update(ref.read(settingsProvider).copyWith(backendUrl: v.trim())),
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _token,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Access token (stored securely)', border: OutlineInputBorder()),
            onSubmitted: (v) => ref.read(secureStorageProvider).write(key: 'api_token', value: v.trim()),
          ),
        ),
        SwitchListTile(
          title: const Text('اجازه می‌دهم متن پاسخ‌هایم به سرور ارسال شود'),
          subtitle: const Text('فقط متن تشخیص‌داده‌شده ارسال می‌شود؛ صدا هرگز ارسال یا ذخیره نمی‌شود.'),
          value: s.backendConsent,
          onChanged: (v) => notifier.update(ref.read(settingsProvider).copyWith(backendConsent: v)),
        ),
        const Divider(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: _deleteAll,
          icon: const Icon(Icons.delete_forever),
          label: const Text('حذف همه‌ی داده‌های یادگیری'),
        ),
      ]),
    );
  }
}
