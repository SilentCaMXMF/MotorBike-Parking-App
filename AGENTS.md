# AGENTS.md - Coding Guidelines for Motorbike Parking App

## Build/Lint/Test Commands
- **Build APK**: `flutter build apk --release`
- **Build iOS**: `flutter build ios --release`
- **Run Debug**: `flutter run --debug`
- **Lint**: `flutter analyze`
- **Format**: `flutter format .`
- **Test All**: `flutter test`
- **Test Single**: `flutter test test/specific_test.dart`

## Code Style Guidelines
- **Imports**: Use relative imports for lib/, `package:` for external deps
- **Naming**: camelCase for vars/methods, PascalCase for classes, UPPER_CASE for constants
- **Types**: Always specify types explicitly (no `var` for non-obvious types)
- **Async**: Use `async`/`await`, handle `Future` properly, avoid `.then()`
- **Error Handling**: Use try-catch with specific exceptions, show user-friendly SnackBars
- **State Management**: Use `setState()` for UI updates, consider Provider for complex state
- **Structure**: lib/models/ for data classes, lib/services/ for business logic, lib/screens/ for UI, lib/widgets/ for reusable components
- **Formatting**: Run `flutter format` before commits, follow Dart style guide
- **Documentation**: Add comments for complex logic, use /// for public APIs
- **Testing**: Write unit tests for services, widget tests for UI components