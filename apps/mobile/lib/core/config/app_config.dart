import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({required this.useMockData, required this.apiBaseUrl});

  final bool useMockData;
  final String apiBaseUrl;

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      useMockData: bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true),
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000/api/v1',
      ),
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
