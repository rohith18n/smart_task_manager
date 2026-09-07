import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile_entity.dart';

void main() {
  group('UserProfileEntity Tests', () {
    final now = DateTime(2025, 1, 1, 12, 0, 0);

    final profile = UserProfileEntity(
      userId: 'test_user_123',
      name: 'John Doe',
      email: 'john@example.com',
      createdAt: now,
      themeMode: 'dark',
    );

    test('toMap converts entity to Map with all required Firestore fields', () {
      final map = profile.toMap();

      expect(map['userId'], 'test_user_123');
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['createdAt'], now.toIso8601String());
      expect(map['themeMode'], 'dark');
    });

    test('fromMap restores entity from Firestore Map correctly', () {
      final map = {
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'createdAt': now.toIso8601String(),
        'themeMode': 'light',
      };

      final restored = UserProfileEntity.fromMap(map, 'user_456');

      expect(restored.userId, 'user_456');
      expect(restored.name, 'Jane Smith');
      expect(restored.email, 'jane@example.com');
      expect(restored.createdAt, now);
      expect(restored.themeMode, 'light');
    });

    test('copyWith updates fields correctly', () {
      final updated = profile.copyWith(
        name: 'John Updated',
        themeMode: 'system',
      );

      expect(updated.name, 'John Updated');
      expect(updated.themeMode, 'system');
      expect(updated.email, profile.email);
      expect(updated.userId, profile.userId);
    });
  });
}
