/// Bật bằng: `flutter run --dart-define=MOCK_UI=true`
/// Hoặc build: `--dart-define=MOCK_UI=true`
const bool kUiDemoMode = bool.fromEnvironment('MOCK_UI', defaultValue: false);
