/// Application configuration. Replace with env loading as needed.
class AppConfig {
  const AppConfig({required this.baseUrl});
  final String baseUrl;
}

const appConfig = AppConfig(baseUrl: "http://localhost:8000/api/v1");