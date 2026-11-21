enum UserRole {
  passenger('p', 'Passenger'),
  driver('d', 'Driver'),
  admin('a', 'Admin');

  final String code;
  final String label;

  const UserRole(this.code, this.label);

  static UserRole fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'p':
      case 'passenger':
        return UserRole.passenger;
      case 'd':
      case 'driver':
        return UserRole.driver;
      case 'a':
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.passenger;
    }
  }
}
