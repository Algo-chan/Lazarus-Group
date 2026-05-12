enum UserRole {
  admin,
  provider,
  customer;

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.provider:
        return 'provider';
      case UserRole.customer:
        return 'customer';
    }
  }

  static UserRole fromString(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'provider':
        return UserRole.provider;
      case 'customer':
        return UserRole.customer;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isProvider => this == UserRole.provider;
  bool get isCustomer => this == UserRole.customer;
}
