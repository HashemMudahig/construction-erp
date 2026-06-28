# Frontend History

This file records notable updates made to the Construction ERP frontend.

## 2026-06-28

### Skeleton Stabilization

- Added `AGENTS.md` with Flutter/Riverpod/GoRouter/Dio conventions.
- Added `pubspec.yaml` with pinned dependencies: flutter, flutter_riverpod, go_router, dio, intl.
- Added feature-first `lib/` skeleton:
  - `lib/main.dart` entry point with `ProviderScope`.
  - `lib/core/`: config, constants, theme, network (Dio), router.
  - `lib/features/`: auth, clients, projects, payments, expenses, dashboard, reports, settings.
  - Each feature has `data/`, `domain/`, `presentation/` subfolders with `.gitkeep` placeholders.
- Added `.gitignore` for Flutter/Dart.

### Verification

- Pending `flutter pub get` and `flutter analyze` once Flutter SDK is installed on this machine.