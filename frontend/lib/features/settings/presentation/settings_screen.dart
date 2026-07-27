import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/finance/exchange_rate.dart';
import '../../backup/presentation/backup_restore_section.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _rateController = TextEditingController();
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الإعدادات' : 'Settings'),
      ),
      body: SafeArea(
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LocalError(
            message: error.toString(),
            retryLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
            onRetry: () => ref.read(settingsProvider.notifier).retry(),
          ),
          data: (value) {
            if (_rateController.text.isEmpty) {
              _rateController.text =
                  formatScaledExchangeRate(value.defaultSarToYerRateScaled);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SettingsCard(
                  title: isArabic ? 'العملة' : 'Currency',
                  icon: Icons.currency_exchange,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isArabic
                            ? 'سعر الصرف الافتراضي: ريال يمني لكل 1 ريال سعودي'
                            : 'Default exchange rate: YER per 1 SAR',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: isArabic ? 'YER لكل SAR' : 'YER per SAR',
                          helperText: isArabic
                              ? 'يُستخدم للمعاملات الجديدة فقط'
                              : 'Used only for new transactions',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveRate,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(isArabic ? 'حفظ' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: isArabic ? 'اللغة' : 'Language',
                  icon: Icons.language,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'ar', label: Text('العربية')),
                    ],
                    selected: {value.localeCode},
                    onSelectionChanged: (selection) =>
                        _setLocale(selection.single),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: isArabic ? 'الأمان المحلي' : 'Local security',
                  icon: Icons.phonelink_lock_outlined,
                  child: Text(
                    isArabic
                        ? 'يحفظ التطبيق البيانات محلياً لمستخدم جهاز واحد. الوصول الفعلي إلى الجهاز يعني إمكانية الوصول إلى بيانات التطبيق وفق حماية نظام التشغيل. لا يوجد PIN أو بصمة أو تشفير لقاعدة البيانات.'
                        : 'The app stores data locally for one device user. Physical device access implies access to app data subject to operating-system protections. No PIN, biometrics, or database encryption is implemented.',
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message == (isArabic ? 'تم الحفظ' : 'Saved')
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const BackupRestoreSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveRate() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    final error = await ref
        .read(settingsProvider.notifier)
        .updateRate(_rateController.text);
    if (!mounted) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _saving = false;
      _message = error ?? (isArabic ? 'تم الحفظ' : 'Saved');
    });
  }

  Future<void> _setLocale(String localeCode) async {
    final error =
        await ref.read(settingsProvider.notifier).updateLocale(localeCode);
    if (error == null) {
      await ref.read(localeProvider.notifier).setLocale(localeCode);
    }
    if (mounted && error != null) setState(() => _message = error);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LocalError extends StatelessWidget {
  const _LocalError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
