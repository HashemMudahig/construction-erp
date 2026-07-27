import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/features/settings/domain/app_settings.dart';
import 'package:construction_erp/features/settings/domain/settings_repository_interface.dart';
import 'package:construction_erp/features/settings/presentation/settings_provider.dart';
import 'package:construction_erp/features/settings/presentation/settings_screen.dart';

class _FakeSettingsRepository implements SettingsRepositoryInterface {
  _FakeSettingsRepository({
    AppSettingsEntity? initial,
    this.loadFuture,
  }) : value = initial ?? AppSettingsEntity.defaults;

  AppSettingsEntity value;
  final Future<AppSettingsEntity>? loadFuture;

  @override
  Future<AppSettingsEntity> loadSettings() async => loadFuture ?? value;

  @override
  Future<AppSettingsEntity> updateDefaultSarToYerRate(String rate) async {
    if (rate == '0') {
      throw const SettingsValidationException('Rate must be positive.');
    }
    value = value.copyWith(defaultSarToYerRateScaled: 420000000);
    return value;
  }

  @override
  Future<AppSettingsEntity> updateLocale(String localeCode) async {
    value = value.copyWith(localeCode: localeCode);
    return value;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  required SettingsRepositoryInterface repository,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        localeProvider.overrideWith((ref) {
          final notifier = LocaleNotifier();
          notifier.state = locale;
          return notifier;
        }),
      ],
      child: MaterialApp(
        locale: locale,
        home: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: const SettingsScreen(),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  const sizes = [
    Size(320, 640),
    Size(390, 844),
    Size(600, 900),
    Size(800, 1280),
    Size(1440, 900),
  ];

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final size in sizes) {
      testWidgets(
        '${locale.languageCode} ${size.width.toInt()}x${size.height.toInt()} has no overflow',
        (tester) async {
          await _pump(
            tester,
            size: size,
            locale: locale,
            repository: _FakeSettingsRepository(),
          );
          expect(tester.takeException(), isNull);
          expect(find.textContaining('410.000000'), findsOneWidget);
          expect(
            find.textContaining('Local security'),
            findsOneWidget,
          );
          expect(find.textContaining('JWT'), findsNothing);
        },
      );
    }
  }

  testWidgets('loading state renders locally', (tester) async {
    final completer = Completer<AppSettingsEntity>();
    await _pump(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      repository: _FakeSettingsRepository(loadFuture: completer.future),
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('local error state has retry and no network wording',
      (tester) async {
    final completer = Completer<AppSettingsEntity>();
    await _pump(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      repository: _FakeSettingsRepository(loadFuture: completer.future),
      settle: false,
    );
    completer.completeError(StateError('Local settings failed'));
    await tester.pump();
    expect(find.textContaining('Local settings failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('HTTP'), findsNothing);
  });

  testWidgets('valid rate saves and invalid rate displays validation',
      (tester) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
      repository: _FakeSettingsRepository(),
    );
    await tester.enterText(find.byType(TextField), '420');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('positive'), findsOneWidget);
  });
}
