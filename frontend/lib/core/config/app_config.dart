/// Application configuration. Replace with env loading as needed.
class AppConfig {
  const AppConfig({required this.baseUrl});
  final String baseUrl;
}

/// On Android emulators, `10.0.2.2` is the alias for the host machine's
/// `localhost`. Use it so the app can reach the FastAPI backend running on
/// your PC. On a physical device you'd use the PC's LAN IP instead.
const appConfig = AppConfig(baseUrl: "http://10.0.2.2:8000/api/v1");
