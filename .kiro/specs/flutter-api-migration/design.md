# Design Document: Flutter API Migration

## Overview

This design document outlines the architecture and implementation approach for migrating the Flutter mobile application from Firebase (Firestore, Firebase Auth, Firebase Storage) to a custom REST API backend. The migration maintains feature parity while enabling cost reduction and data ownership through a local MariaDB database on Raspberry Pi.

The design preserves Firebase code through commenting rather than deletion, allowing the application to scale back to Firebase if the local backend reaches capacity limits.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              UI Layer (Screens/Widgets)                 │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Service Layer (SQL Service)                   │ │
│  │  - getParkingZones()                                    │ │
│  │  - addUserReport()                                      │ │
│  │  - uploadImage()                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         API Client (HTTP Communication)                 │ │
│  │  - Request/Response Interceptors                        │ │
│  │  - JWT Token Management                                 │ │
│  │  - Error Handling                                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                    HTTPS/HTTP
                            │
┌─────────────────────────────────────────────────────────────┐
│              REST API (Node.js + Express)                    │
│                   Running on Raspberry Pi                    │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│              MariaDB Database                                │
│                   Running on Raspberry Pi                    │
└─────────────────────────────────────────────────────────────┘
```

### Migration Strategy

The migration follows a **parallel implementation** approach:

1. **Comment out Firebase code** - Preserve all Firebase implementations
2. **Implement new API-based services** - Create new service classes
3. **Switch service providers** - Update dependency injection to use new services
4. **Maintain rollback capability** - Keep Firebase code ready for re-activation

## Components and Interfaces

### 1. API Client (`lib/services/api_service.dart`)

The API Client is the foundation layer that handles all HTTP communication with the backend.

#### Responsibilities
- HTTP request/response handling
- JWT token storage and retrieval
- Automatic token attachment to requests
- Request/response logging
- Error transformation

#### Interface

```dart
class ApiService {
  final String baseUrl;
  final Dio _dio; // or http.Client
  final FlutterSecureStorage _secureStorage;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Initialize with base URL from environment
  Future<void> initialize(String baseUrl);
  
  // Authentication methods
  Future<AuthResponse> signUp(String email, String password);
  Future<AuthResponse> signIn(String email, String password);
  Future<AuthResponse> signInAnonymously();
  Future<void> signOut();
  
  // Token management
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  
  // Generic HTTP methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParams});
  Future<Response> post(String path, {dynamic body});
  Future<Response> put(String path, {dynamic body});
  Future<Response> delete(String path);
  Future<Response> uploadFile(String path, File file, {Map<String, dynamic>? fields});
}
```

#### Implementation Details

**Package Choice: Dio**
- Dio is preferred over http package for:
  - Built-in interceptor support
  - Better error handling
  - Upload progress tracking
  - Request cancellation
  - Timeout configuration

**Interceptors**

Request Interceptor:
```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    // Add JWT token
    final token = await getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add common headers
    options.headers['Content-Type'] = 'application/json';
    
    // Log request
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    
    return handler.next(options);
  },
));
```

Response Interceptor:
```dart
_dio.interceptors.add(InterceptorsWrapper(
  onResponse: (response, handler) {
    // Log response
    print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
    return handler.next(response);
  },
  onError: (DioError error, handler) async {
    // Handle token expiration
    if (error.response?.statusCode == 401) {
      await clearToken();
      // Navigate to login screen
    }
    
    // Transform error to user-friendly message
    final friendlyError = _transformError(error);
    return handler.reject(friendlyError);
  },
));
```

**Token Storage**

Using `flutter_secure_storage` for secure JWT storage:
```dart
Future<void> saveToken(String token) async {
  await _secureStorage.write(key: 'jwt_token', value: token);
}

Future<String?> getToken() async {
  return await _secureStorage.read(key: 'jwt_token');
}

Future<void> clearToken() async {
  await _secureStorage.delete(key: 'jwt_token');
}
```

### 2. SQL Service (`lib/services/sql_service.dart`)

The SQL Service replaces FirestoreService with API-based implementations while maintaining the same interface.

#### Responsibilities
- Translate service calls to API requests
- Parse API responses into model objects
- Maintain backward compatibility with FirestoreService interface
- Handle service-level error transformation

#### Interface

```dart
class SqlService {
  final ApiService _apiService;
  
  // Singleton pattern
  static final SqlService _instance = SqlService._internal();
  factory SqlService() => _instance;
  SqlService._internal() : _apiService = ApiService();
  
  // Parking zone methods
  Future<List<ParkingZone>> getParkingZones({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    int limit = 50,
  });
  
  Future<ParkingZone?> getParkingZone(String id);
  
  // Report methods
  Future<String> addUserReport(UserReport report);
  Future<List<UserReport>> getRecentReports(String spotId, {int hours = 24});
  
  // Image upload
  Future<String> uploadImage(File file, String reportId, {
    Function(double)? onProgress,
  });
}
```

#### Implementation Details

**Parking Zones**

```dart
Future<List<ParkingZone>> getParkingZones({
  required double latitude,
  required double longitude,
  double radius = 5.0,
  int limit = 50,
}) async {
  try {
    final response = await _apiService.get('/api/parking/nearby', queryParams: {
      'lat': latitude,
      'lng': longitude,
      'radius': radius,
      'limit': limit,
    });
    
    final List<dynamic> data = response.data['data'];
    return data.map((json) => ParkingZone.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to fetch parking zones: $e');
  }
}
```

**User Reports**

```dart
Future<String> addUserReport(UserReport report) async {
  try {
    final response = await _apiService.post('/api/reports', body: {
      'spotId': report.spotId,
      'reportedCount': report.reportedCount,
      'userLatitude': report.userLatitude,
      'userLongitude': report.userLongitude,
    });
    
    return response.data['data']['id'];
  } catch (e) {
    throw Exception('Failed to submit report: $e');
  }
}
```

**Image Upload**

```dart
Future<String> uploadImage(File file, String reportId, {
  Function(double)? onProgress,
}) async {
  try {
    final response = await _apiService.uploadFile(
      '/api/reports/$reportId/images',
      file,
      onProgress: onProgress,
    );
    
    return response.data['data']['imageUrl'];
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}
```

### 3. Environment Configuration (`lib/config/environment.dart`)

Manages environment-specific configuration for different deployment scenarios.

#### Interface

```dart
enum EnvironmentType {
  development,
  staging,
  production,
}

class Environment {
  static EnvironmentType _currentEnvironment = EnvironmentType.development;
  
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case EnvironmentType.development:
        return dotenv.env['DEV_API_BASE_URL'] ?? 'http://localhost:3000';
      case EnvironmentType.staging:
        return dotenv.env['STAGING_API_BASE_URL'] ?? 'http://staging.example.com';
      case EnvironmentType.production:
        return dotenv.env['PROD_API_BASE_URL'] ?? 'http://192.168.1.67:3000';
    }
  }
  
  static int get apiTimeout {
    return int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
  }
  
  static void setEnvironment(EnvironmentType env) {
    _currentEnvironment = env;
  }
}
```

### 4. Polling Service (`lib/services/polling_service.dart`)

Implements periodic data refresh for real-time updates.

#### Responsibilities
- Poll API for parking zone updates
- Manage polling lifecycle (start/stop)
- Handle app lifecycle events (foreground/background)
- Prevent memory leaks

#### Interface

```dart
class PollingService {
  Timer? _timer;
  final SqlService _sqlService;
  final Duration _pollInterval;
  
  PollingService({
    SqlService? sqlService,
    Duration pollInterval = const Duration(seconds: 30),
  }) : _sqlService = sqlService ?? SqlService(),
       _pollInterval = pollInterval;
  
  void startPolling({
    required double latitude,
    required double longitude,
    required Function(List<ParkingZone>) onUpdate,
    required Function(String) onError,
  });
  
  void stopPolling();
  
  bool get isPolling => _timer != null && _timer!.isActive;
}
```

#### Implementation

```dart
void startPolling({
  required double latitude,
  required double longitude,
  required Function(List<ParkingZone>) onUpdate,
  required Function(String) onError,
}) {
  stopPolling(); // Clear any existing timer
  
  _timer = Timer.periodic(_pollInterval, (timer) async {
    try {
      final zones = await _sqlService.getParkingZones(
        latitude: latitude,
        longitude: longitude,
      );
      onUpdate(zones);
    } catch (e) {
      onError(e.toString());
    }
  });
}

void stopPolling() {
  _timer?.cancel();
  _timer = null;
}
```

## Data Models

The existing data models remain unchanged to maintain compatibility:

- `ParkingZone` - Parking zone information
- `UserReport` - User-submitted parking reports
- `User` - User authentication data

The models already have `fromJson` and `toJson` methods that work with both Firebase and API responses.

## Error Handling

### Error Transformation Strategy

Transform API errors into user-friendly messages:

```dart
String _transformError(DioError error) {
  if (error.type == DioErrorType.connectionTimeout) {
    return 'Connection timeout. Please check your internet connection.';
  }
  
  if (error.type == DioErrorType.receiveTimeout) {
    return 'Server is taking too long to respond. Please try again.';
  }
  
  if (error.response != null) {
    final statusCode = error.response!.statusCode;
    final message = error.response!.data['error'] ?? 'Unknown error';
    
    switch (statusCode) {
      case 400:
        return 'Invalid request: $message';
      case 401:
        return 'Authentication required. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return message;
    }
  }
  
  return 'An unexpected error occurred. Please try again.';
}
```

### UI Error Handling

Display errors using SnackBar:

```dart
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}
```

## Testing Strategy

### Unit Tests

Test service layer methods with mocked API responses:

```dart
class MockApiService extends Mock implements ApiService {}

void main() {
  group('SqlService', () {
    late SqlService sqlService;
    late MockApiService mockApiService;
    
    setUp(() {
      mockApiService = MockApiService();
      sqlService = SqlService(apiService: mockApiService);
    });
    
    test('getParkingZones returns list of zones', () async {
      // Arrange
      when(mockApiService.get(any, queryParams: anyNamed('queryParams')))
        .thenAnswer((_) async => Response(
          data: {'data': [/* mock zone data */]},
          statusCode: 200,
        ));
      
      // Act
      final zones = await sqlService.getParkingZones(
        latitude: 38.7223,
        longitude: -9.1393,
      );
      
      // Assert
      expect(zones, isA<List<ParkingZone>>());
      expect(zones.length, greaterThan(0));
    });
  });
}
```

### Widget Tests

Test UI components with mocked services:

```dart
class MockSqlService extends Mock implements SqlService {}

void main() {
  testWidgets('MapScreen displays loading indicator', (tester) async {
    final mockService = MockSqlService();
    
    when(mockService.getParkingZones(
      latitude: anyNamed('latitude'),
      longitude: anyNamed('longitude'),
    )).thenAnswer((_) async => Future.delayed(Duration(seconds: 2), () => []));
    
    await tester.pumpWidget(MaterialApp(
      home: MapScreen(sqlService: mockService),
    ));
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

## UI Component Updates

### MapScreen Updates

**Current Implementation (Firebase):**
```dart
StreamBuilder<List<ParkingZone>>(
  stream: FirestoreService().getParkingZones(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    // Display markers
  },
)
```

**New Implementation (API with Polling):**
```dart
class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final PollingService _pollingService = PollingService();
  List<ParkingZone> _parkingZones = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }
  
  @override
  void dispose() {
    _pollingService.stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollingService.stopPolling();
    }
  }
  
  void _startPolling() {
    _pollingService.startPolling(
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
      onUpdate: (zones) {
        setState(() {
          _parkingZones = zones;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(
              onPressed: _startPolling,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Display map with markers
  }
}
```

### ReportingDialog Updates

**Fix Duplicate Code Bug:**
The current implementation has duplicate report submission code. Consolidate into a single method:

```dart
Future<void> _submitReport() async {
  if (_isSubmitting) return;
  
  setState(() {
    _isSubmitting = true;
    _error = null;
  });
  
  try {
    final report = UserReport(
      spotId: widget.parkingZone.id,
      reportedCount: _selectedCount,
      userLatitude: _currentLocation.latitude,
      userLongitude: _currentLocation.longitude,
      timestamp: DateTime.now(),
    );
    
    final reportId = await SqlService().addUserReport(report);
    
    if (_selectedImage != null) {
      await SqlService().uploadImage(
        _selectedImage!,
        reportId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );
    }
    
    if (mounted) {
      Navigator.of(context).pop();
      _showSuccess(context, 'Report submitted successfully');
    }
  } catch (e) {
    setState(() {
      _error = e.toString();
    });
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}
```

### AuthScreen Updates

Replace Firebase authentication with API authentication:

```dart
Future<void> _signIn() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() {
    _isLoading = true;
    _error = null;
  });
  
  try {
    final response = await ApiService().signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    await ApiService().saveToken(response.token);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MapScreen()),
      );
    }
  } catch (e) {
    setState(() {
      _error = e.toString();
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```

## Firebase Code Preservation

### Commenting Strategy

Use clear comment blocks to mark Firebase code:

```dart
// ============================================================================
// FIREBASE IMPLEMENTATION - COMMENTED OUT FOR API MIGRATION
// Uncomment this section and comment out API implementation to use Firebase
// ============================================================================
/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // ... Firebase implementation
}
*/
// ============================================================================
// END FIREBASE IMPLEMENTATION
// ============================================================================
```

### Files to Comment Out

1. **lib/services/firestore_service.dart** - Comment out entire file
2. **lib/services/auth_service.dart** - Comment out Firebase auth methods
3. **lib/main.dart** - Comment out Firebase initialization
4. **pubspec.yaml** - Comment out Firebase packages
5. **android/build.gradle** - Comment out Firebase plugins
6. **android/app/build.gradle** - Comment out google-services plugin
7. **ios/Podfile** - Comment out Firebase pods

### Rollback Procedure

To rollback to Firebase:

1. Uncomment Firebase packages in pubspec.yaml
2. Run `flutter pub get`
3. Uncomment Firebase initialization in main.dart
4. Uncomment FirestoreService implementation
5. Update service injection to use FirestoreService
6. Uncomment Android/iOS Firebase configuration
7. Run `flutter clean && flutter pub get`
8. Rebuild app

## Dependencies

### New Dependencies to Add

```yaml
dependencies:
  # HTTP client
  dio: ^5.4.0
  
  # Secure storage for JWT
  flutter_secure_storage: ^9.0.0
  
  # Existing dependencies remain
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  flutter_local_notifications: ^16.3.0
  image_picker: ^1.0.0
  flutter_dotenv: ^5.1.0
```

### Firebase Dependencies to Comment Out

```yaml
# Firebase - Commented out for API migration
# firebase_core: ^2.17.0
# firebase_auth: ^4.10.0
# cloud_firestore: ^4.9.3
# firebase_storage: ^11.2.8
```

## Configuration Files

### .env File

```env
# API Configuration
DEV_API_BASE_URL=http://localhost:3000
STAGING_API_BASE_URL=http://staging.example.com
PROD_API_BASE_URL=http://192.168.1.67:3000
API_TIMEOUT=30000

# Environment
ENVIRONMENT=development
```

### .env.example File

```env
# API Configuration
DEV_API_BASE_URL=http://localhost:3000
STAGING_API_BASE_URL=http://staging.example.com
PROD_API_BASE_URL=http://your-raspberry-pi-ip:3000
API_TIMEOUT=30000

# Environment (development, staging, production)
ENVIRONMENT=development
```

## Security Considerations

### Token Security

- Store JWT tokens in `flutter_secure_storage` (encrypted storage)
- Never log tokens in production
- Clear tokens on logout
- Handle token expiration gracefully

### HTTPS in Production

- Use HTTPS for production API calls
- Implement certificate pinning for additional security
- Validate SSL certificates

### Input Validation

- Validate all user inputs before sending to API
- Sanitize data in UI layer
- Trust API validation as source of truth

## Performance Considerations

### Polling Optimization

- Poll only when map is visible
- Stop polling when app is backgrounded
- Use reasonable poll interval (30 seconds)
- Implement exponential backoff on errors

### Image Upload Optimization

- Compress images before upload
- Show upload progress
- Allow cancellation of uploads
- Implement retry logic

### Caching Strategy

- Cache parking zone data locally
- Use cached data while fetching updates
- Implement cache expiration (5 minutes)

## Migration Checklist

### Phase 1: Setup
- [ ] Add new dependencies (dio, flutter_secure_storage)
- [ ] Create environment configuration
- [ ] Create .env and .env.example files

### Phase 2: API Client
- [ ] Implement ApiService class
- [ ] Add request/response interceptors
- [ ] Implement token management
- [ ] Test authentication methods

### Phase 3: Service Layer
- [ ] Implement SqlService class
- [ ] Implement parking zone methods
- [ ] Implement report methods
- [ ] Implement image upload

### Phase 4: UI Updates
- [ ] Update MapScreen with polling
- [ ] Fix ReportingDialog duplicate code
- [ ] Update AuthScreen
- [ ] Add loading/error states

### Phase 5: Firebase Removal
- [ ] Comment out Firebase packages
- [ ] Comment out Firebase configuration
- [ ] Comment out FirestoreService
- [ ] Update main.dart

### Phase 6: Testing
- [ ] Update unit tests
- [ ] Update widget tests
- [ ] Manual testing
- [ ] Performance testing

## Rollback Plan

If critical issues arise:

1. **Immediate Rollback** (< 5 minutes)
   - Uncomment Firebase packages in pubspec.yaml
   - Run `flutter pub get`
   - Uncomment Firebase initialization
   - Rebuild and deploy

2. **Data Consistency**
   - No data migration needed (Firebase data remains intact)
   - API data can be exported if needed

3. **Communication**
   - Notify users of temporary issue
   - Provide ETA for resolution

## Success Metrics

Migration is successful when:

- All authentication flows work with API
- Parking zones display correctly on map
- Reports submit successfully
- Images upload successfully
- Polling updates work smoothly
- No critical bugs for 1 week
- App performance is acceptable (< 2s load time)
- All tests pass
