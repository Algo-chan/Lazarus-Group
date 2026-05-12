class ApiConstants {
  static const String baseUrl = 'http://127.0.0.1:3000/api';

  static const String login = '$baseUrl/auth/login';
  static const String signup = '$baseUrl/auth/signup';
  static const String me = '$baseUrl/auth/me';
  static const String updateProfile = '$baseUrl/auth/profile';

  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminAnalytics = '$baseUrl/admin/analytics';
  static const String adminPendingProviders = '$baseUrl/admin/providers/pending';

  static const String services = '$baseUrl/services';
  static const String categories = '$baseUrl/services/categories/list';

  static const String bookings = '$baseUrl/bookings';
  static const String myBookings = '$baseUrl/bookings/my';

  static const String reviews = '$baseUrl/reviews';
}
