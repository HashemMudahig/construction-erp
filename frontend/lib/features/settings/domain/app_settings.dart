import '../../../core/database/database_constants.dart';

class AppSettingsEntity {
  const AppSettingsEntity({
    required this.defaultSarToYerRateScaled,
    required this.localeCode,
  });

  static const defaults = AppSettingsEntity(
    defaultSarToYerRateScaled: kDefaultSarToYerRateScaled,
    localeCode: kDefaultLocaleCode,
  );

  final int defaultSarToYerRateScaled;
  final String localeCode;

  AppSettingsEntity copyWith({
    int? defaultSarToYerRateScaled,
    String? localeCode,
  }) {
    return AppSettingsEntity(
      defaultSarToYerRateScaled:
          defaultSarToYerRateScaled ?? this.defaultSarToYerRateScaled,
      localeCode: localeCode ?? this.localeCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettingsEntity &&
      other.defaultSarToYerRateScaled == defaultSarToYerRateScaled &&
      other.localeCode == localeCode;

  @override
  int get hashCode => Object.hash(defaultSarToYerRateScaled, localeCode);
}

class SettingsValidationException implements Exception {
  const SettingsValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}
