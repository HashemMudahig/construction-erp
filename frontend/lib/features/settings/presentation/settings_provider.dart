import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_settings_repository.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository_interface.dart';

final settingsRepositoryProvider = Provider<SettingsRepositoryInterface>(
  (ref) => ref.watch(localSettingsRepositoryProvider),
);

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettingsEntity>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettingsEntity> {
  @override
  Future<AppSettingsEntity> build() {
    return ref.watch(settingsRepositoryProvider).loadSettings();
  }

  Future<String?> updateRate(String rate) async {
    try {
      final updated = await ref
          .read(settingsRepositoryProvider)
          .updateDefaultSarToYerRate(rate);
      state = AsyncValue.data(updated);
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateLocale(String localeCode) async {
    try {
      final updated =
          await ref.read(settingsRepositoryProvider).updateLocale(localeCode);
      state = AsyncValue.data(updated);
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  void retry() => ref.invalidateSelf();
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.watch(settingsRepositoryProvider));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier([this._repository]) : super(const Locale('en')) {
    if (_repository != null) _load();
  }

  final SettingsRepositoryInterface? _repository;

  Future<void> _load() async {
    try {
      final settings = await _repository!.loadSettings();
      if (mounted) state = Locale(settings.localeCode);
    } catch (_) {
      // English is the safe startup fallback when local settings are unavailable.
    }
  }

  Future<void> setLocale(String localeCode) async {
    final repository = _repository;
    if (repository == null) {
      state = Locale(localeCode);
      return;
    }
    final settings = await repository.updateLocale(localeCode);
    if (mounted) state = Locale(settings.localeCode);
  }

  Future<void> toggleLocale() =>
      setLocale(state.languageCode == 'en' ? 'ar' : 'en');
}
