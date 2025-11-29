import 'package:mockito/mockito.dart';
import 'package:motorbike_parking_app/services/notification_service.dart';

// Mock NotificationService
class MockNotificationService extends Mock implements NotificationService {
  // Setup initialize success
  void setupInitializeSuccess() {
    when(this.initialize()).thenAnswer((_) async {});
  }

  // Setup initialize failure
  void setupInitializeFailure() {
    when(this.initialize())
        .thenThrow(Exception('Failed to initialize notifications'));
  }

  // Setup showNotification success
  void setupShowNotificationSuccess() {
    when(this.showNotification(any, any)).thenAnswer((_) async {});
  }

  // Setup showNotification failure
  void setupShowNotificationFailure() {
    when(this.showNotification(any, any))
        .thenThrow(Exception('Failed to show notification'));
  }

  // Setup checkProximityAndNotify (no-op for testing)
  void setupCheckProximityAndNotify() {
    when(this.checkProximityAndNotify(any, any)).thenReturn(null);
  }
}
