import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/core/providers/app_providers.dart';
import 'package:safeseated_app/features/auth/data/mock_auth_repository.dart';
import 'package:safeseated_app/features/auth/domain/models/user.dart';
import 'package:safeseated_app/features/auth/domain/models/user_role.dart';
import 'package:safeseated_app/features/auth/domain/models/verification_status.dart';
import 'package:safeseated_app/features/profile/presentation/screens/passenger_profile_screen.dart';
import 'package:safeseated_app/features/profile/presentation/screens/verification_status_screen.dart';

class _ProfileAuthRepository extends MockAuthRepository {
  _ProfileAuthRepository(this.user);

  final User user;

  @override
  Future<User?> getCurrentUser() async => user;
}

void main() {
  const statuses = [
    (VerificationStatus.pending, 'Pending Review'),
    (VerificationStatus.approved, 'Verified'),
    (VerificationStatus.rejected, 'Rejected'),
  ];

  for (final (status, label) in statuses) {
    testWidgets('shows the logged-in passenger status: $label', (tester) async {
      await tester.pumpWidget(_profileApp(status));
      await tester.pumpAndSettle();

      expect(find.text(label), findsOneWidget);
      expect(find.text('✓ Verified Passenger'), findsNothing);
    });
  }

  testWidgets('Verification status opens the document status screen', (
    tester,
  ) async {
    await tester.pumpWidget(_profileApp(VerificationStatus.pending));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verification status'));
    await tester.pumpAndSettle();

    expect(find.byType(VerificationStatusScreen), findsOneWidget);
  });
}

Widget _profileApp(VerificationStatus status) {
  final user = User(
    id: 'passenger-1',
    name: 'Test Passenger',
    email: 'passenger@example.com',
    phone: '03001234567',
    password: '',
    role: UserRole.passenger,
    status: status,
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_ProfileAuthRepository(user)),
      myDocumentsProvider.overrideWith((ref) async => []),
    ],
    child: const MaterialApp(home: PassengerProfileScreen()),
  );
}
