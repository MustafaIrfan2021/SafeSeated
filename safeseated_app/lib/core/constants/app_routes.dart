class AppRoutes {
  // Auth & Onboarding
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String roleSelect = '/role-select';
  static const String passengerRegister = '/passenger-register';
  static const String driverRegister = '/driver-register';
  static const String pendingApproval = '/pending-approval';
  static const String login = '/login';

  // Passenger Shell & Tabs
  static const String passengerShell = '/passenger';
  static const String passengerHome = '/passenger/home';
  static const String passengerBookings = '/passenger/bookings';
  static const String passengerSafety = '/passenger/safety';
  static const String passengerProfile = '/passenger/profile';

  // Passenger Sub-routes
  static const String rideDetails = '/passenger/ride-details';
  static const String liveTrip = '/passenger/live-trip';
  static const String tripChat = '/passenger/trip-chat';
  static const String personalInfo = '/passenger/profile/personal-info';
  static const String verificationStatus =
      '/passenger/profile/verification-status';
  static const String passwordSecurity = '/passenger/profile/password-security';
  static const String notifications = '/passenger/notifications';

  // Driver Shell & Tabs
  static const String driverShell = '/driver';
  static const String driverHome = '/driver/home';
  static const String driverTrips = '/driver/trips';
  static const String driverRides = '/driver/rides';
  static const String driverWallet = '/driver/wallet';
  static const String driverProfile = '/driver/profile';
  static const String driverPostRide = '/driver/post-ride';
  static const String driverPayFee = '/driver/pay-fee';
  static const String driverVehicle = '/driver/profile/vehicle';
  static const String driverReviews = '/driver/profile/reviews';
}
