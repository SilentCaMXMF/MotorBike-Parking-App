# 06: Enhance Input Validation in AuthScreen

## Objective
Improve input validation in `lib/screens/auth_screen.dart` for email and password fields.

## Tasks
- Add proper email format validation using regex
- Enhance password strength requirements (uppercase, numbers, etc.)
- Trim whitespace from inputs
- Show specific validation messages for each field
- Disable submit button when validation fails

## Files to Modify
- `lib/screens/auth_screen.dart`

## Implementation Notes
- Use `RegExp` for email validation
- Update SnackBar messages to be more specific
- Consider adding real-time validation feedback

## Estimated Time: 15 minutes