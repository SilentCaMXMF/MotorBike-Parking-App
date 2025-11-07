# 01: Add Error Handling to AuthService

## Objective
Enhance error handling in `lib/services/auth_service.dart` to properly catch and handle Firebase Authentication exceptions.

## Tasks
- Wrap all Firebase Auth method calls in try-catch blocks
- Catch `FirebaseAuthException` and rethrow with user-friendly messages
- Handle specific error codes (e.g., invalid-email, weak-password, user-not-found)
- Ensure methods return consistent error types

## Files to Modify
- `lib/services/auth_service.dart`

## Implementation Notes
- Use `FirebaseAuthException` for specific auth errors
- Keep error messages concise and user-friendly
- Do not change method signatures; handle errors internally or rethrow as needed

## Estimated Time: 15 minutes