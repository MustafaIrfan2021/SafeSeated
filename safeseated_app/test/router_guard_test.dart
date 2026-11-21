import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/core/constants/app_routes.dart';
import 'package:safeseated_app/core/providers/app_providers.dart';
import 'package:safeseated_app/core/router/app_router.dart';
import 'package:safeseated_app/features/auth/domain/models/user.dart';
import 'package:safeseated_app/features/auth/domain/models/user_role.dart';
import 'package:safeseated_app/features/auth/domain/models/verification_status.dart';
import 'package:safeseated_app/features/auth/data/mock_auth_repository.dart';

void main() {
  const driver = User(
    id: 'driver-1',
    name: 'Sana Malik',
    email: 'sana@example.com',
    phone: '03334445566',
    password: 'demo',
    role: UserRole.driver,
    status: VerificationStatus.approved,
  );
  const passenger = User(
    id: 'passenger-1',
    name: 'Ayesha Khan',
    email: 'ayesha@example.com',
    phone: '03125550142',
    password: 'demo',
    role: UserRole.passenger,
    status: VerificationStatus.approved,
  );
  const pendingPassenger = User(
    id: 'passenger-2',
    name: 'New Passenger',
    email: 'new@example.com',
    phone: '03125550142',
    password: 'demo',
    role: UserRole.passenger,
    status: VerificationStatus.pending,
  );
  const pendingDriver = User(
    id: 'driver-2',
    name: 'New Driver',
    email: 'new-driver@example.com',
    phone: '03125550142',
    password: 'demo',
    role: UserRole.driver,
    status: VerificationStatus.pending,
  );

  test('redirects non-passenger roles away from passenger routes', () {
    expect(
      appRouterRedirect(driver, AppRoutes.passengerHome),
      AppRoutes.welcome,
    );
  });

  test('protects verification routes from signed-out users', () {
    expect(
      appRouterRedirect(null, AppRoutes.pendingApproval),
      AppRoutes.welcome,
    );
  });

  test('allows a pending passenger to log in', () {
    expect(
      appRouterRedirect(pendingPassenger, AppRoutes.passengerRegister),
      isNull,
    );
    expect(
      appRouterRedirect(pendingPassenger, AppRoutes.passengerHome),
      isNull,
    );
    expect(
      appRouterRedirect(pendingPassenger, AppRoutes.pendingApproval),
      isNull,
    );
  });

  test('allows a pending driver to log in', () {
    expect(appRouterRedirect(pendingDriver, AppRoutes.driverRegister), isNull);
    expect(appRouterRedirect(pendingDriver, AppRoutes.driverHome), isNull);
    expect(appRouterRedirect(pendingDriver, AppRoutes.pendingApproval), isNull);
    expect(
      appRouterRedirect(pendingDriver, AppRoutes.login),
      AppRoutes.driverHome,
    );
  });

  test('sends an approved passenger away from authentication screens', () {
    expect(
      appRouterRedirect(passenger, AppRoutes.login),
      AppRoutes.passengerHome,
    );
  });

  test(
    'keeps the router instance stable when authentication changes',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      await container
          .read(authStateProvider.notifier)
          .login(
            email: 'ayesha@smiu.edu.pk',
            password: '1234',
            role: UserRole.passenger,
          );

      expect(identical(container.read(routerProvider), router), isTrue);
    },
  );
}
