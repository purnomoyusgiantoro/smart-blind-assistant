# Smart Blind Assistant

Flutter mobile app for visually impaired users with BLE, camera, AI analysis, and TTS. All UI strings are in Bahasa Indonesia.

## Essential Commands

```bash
flutter pub get              # Install dependencies
flutter analyze              # Static analysis (uses flutter_lints)
flutter test               # Run widget tests
flutter run                # Run on connected device (requires physical device for BLE/camera/TTS)
```

## Architecture

- **Entry point**: `lib/main.dart` → `lib/app.dart`
- **State management**: `provider` package
- **Providers**: `BleProvider`, `AssistantProvider`, `SettingsProvider`
- **Services**: `BleService`, `CameraService`, `TtsService`, `ApiService`, `BackgroundService`

## Key Constraints

- Requires physical Android/iOS device (BLE, camera, TTS not available on emulator)
- `.env` loaded via `flutter_dotenv` (contains `OPENROUTER_API_KEY`)
- Portrait orientation locked on mobile
- Background service skipped on desktop platforms