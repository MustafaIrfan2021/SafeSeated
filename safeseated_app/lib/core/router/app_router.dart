import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../providers/app_providers.dart';
import '../../features/auth/domain/models/user.dart';
import '../../features/auth/domain/models/verification_status.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/passenger_registration_screen.dart';
import '../../features/auth/presentation/screens/driver_registration_screen.dart';
import '../../features/auth/presentation/screens/pending_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/passenger/presentation/screens/passenger_shell_screen.dart';
import '../../features/driver/presentation/screens/driver_shell_screen.dart';
import '../../features/driver/presentation/screens/driver_rides_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';

String? appRouterRedirect(User? user, String location) {
  final isAuthFlow =
      location == AppRoutes.onboarding ||
      location == AppRoutes.welcome ||
      location == AppRoutes.roleSelect ||
      location == AppRoutes.passengerRegister ||
      location == AppRoutes.driverRegister ||
      location == AppRoutes.login;

  if (user == null) {
    return isAuthFlow ? null : AppRoutes.welcome;
  }

  if (location.startsWith('/passenger') && !user.isPassenger) {
    return AppRoutes.welcome;
  }

  if (location.startsWith('/driver') && !user.isDriver) {
    return AppRoutes.welcome;
  }

  if (user.isAdmin &&
      location != AppRoutes.login &&
      location != AppRoutes.welcome) {
    return AppRoutes.welcome;
  }

  if (user.status == VerificationStatus.pending &&
      ((user.isPassenger && location == AppRoutes.passengerRegister) ||
          (user.isDriver && location == AppRoutes.driverRegister))) {
    return null;
  }

  if (user.isPassenger && isAuthFlow) {
    return AppRoutes.passengerHome;
  }
  if (user.isDriver && isAuthFlow) return AppRoutes.driverHome;

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;
  router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    redirect: (context, state) => appRouterRedirect(
      ref.read(authStateProvider).asData?.value,
      state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerRegister,
        builder: (context, state) => const PassengerRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverRegister,
        builder: (context, state) => const DriverRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerHome,
        builder: (context, state) => const PassengerShellScreen(initialTab: 0),
      ),
      GoRoute(
        path: AppRoutes.passengerBookings,
        builder: (context, state) => const PassengerShellScreen(initialTab: 1),
      ),
      GoRoute(
        path: AppRoutes.passengerSafety,
        builder: (context, state) => const PassengerShellScreen(initialTab: 2),
      ),
      GoRoute(
        path: AppRoutes.passengerProfile,
        builder: (context, state) => const PassengerShellScreen(initialTab: 3),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverShell,
        builder: (context, state) => const DriverShellScreen(initialTab: 0),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        builder: (context, state) => const DriverShellScreen(initialTab: 0),
      ),
      GoRoute(
        path: AppRoutes.driverTrips,
        builder: (context, state) => const DriverShellScreen(initialTab: 1),
      ),
      GoRoute(
        path: AppRoutes.driverRides,
        builder: (context, state) => const DriverShellScreen(initialTab: 2),
      ),
      GoRoute(
        path: AppRoutes.driverWallet,
        builder: (context, state) => const DriverShellScreen(initialTab: 3),
      ),
      GoRoute(
        path: AppRoutes.driverProfile,
        builder: (context, state) => const DriverShellScreen(initialTab: 4),
      ),
      GoRoute(
        path: AppRoutes.driverPostRide,
        builder: (context, state) => const DriverRideEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverPayFee,
        builder: (context, state) => const DriverShellScreen(initialTab: 3),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
  ref.listen(authStateProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
