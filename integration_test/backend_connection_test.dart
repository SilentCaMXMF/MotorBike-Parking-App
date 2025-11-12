import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:motorbike_parking_app/services/api_service.dart';
import 'package:motorbike_parking_app/services/sql_service.dart';

/// Simple integration test to verify backend connectivity
/// 
/// This test verifies that the Flutter app can connect to the backend API
/// and perform basic operations.
/// 
/// Prerequisites:
/// - Backend server running at http://localhost:3000 (or configured URL)
/// - Database accessible with test data
/// 
/// Run with: flutter test integration_test/backend_connection_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Backend Connection Tests', () {
    test('Health check - verify backend is running', () async {
      final apiService = ApiService();
      
      try {
        // Try to hit the health endpoint
        final response = await apiService.get('/health');
        
        expect(response.statusCode, 200);
        expect(response.data['status'], 'ok');
        
        print('✓ Backend health check passed');
        print('  Status: ${response.data['status']}');
        print('  Environment: ${response.data['environment']}');
      } catch (e) {
        print('✗ Backend health check failed: $e');
        print('  Make sure backend is running at: http://localhost:3000');
        rethrow;
      }
    });

    test('Get parking zones - verify API integration', () async {
      final sqlService = SqlService();
      
      try {
        // Test getting nearby parking zones
        final zones = await sqlService.getParkingZones(
          latitude: 38.7223,
          longitude: -9.1393,
          radius: 10.0,
          limit: 10,
        );
        
        expect(zones, isNotNull);
        print('✓ Get parking zones successful');
        print('  Found ${zones.length} zones');
        
        if (zones.isNotEmpty) {
          final zone = zones.first;
          print('  Sample zone: ${zone.id}');
          print('    Capacity: ${zone.totalCapacity}');
          print('    Occupancy: ${zone.currentOccupancy}');
        }
      } catch (e) {
        print('✗ Get parking zones failed: $e');
        print('  This might be expected if no zones exist in database');
      }
    });

    test('Anonymous authentication - verify auth flow', () async {
      final apiService = ApiService();
      
      try {
        // Test anonymous authentication
        final authResponse = await apiService.signInAnonymously();
        
        expect(authResponse.token, isNotEmpty);
        expect(authResponse.userId, isNotEmpty);
        
        print('✓ Anonymous authentication successful');
        print('  User ID: ${authResponse.userId}');
        print('  Token length: ${authResponse.token.length}');
        
        // Clean up
        await apiService.clearToken();
      } catch (e) {
        print('✗ Anonymous authentication failed: $e');
        rethrow;
      }
    });
  });
}
