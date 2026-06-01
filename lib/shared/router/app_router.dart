import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_service_app/providers/auth_provider.dart';
import 'package:local_service_app/core/enums/user_role.dart';
import 'package:local_service_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:local_service_app/features/auth/presentation/screens/login_screen.dart';
import 'package:local_service_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:local_service_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:local_service_app/home_screen.dart';
import 'package:local_service_app/service_detail_screen.dart';
import 'package:local_service_app/profile_screen.dart';
import 'package:local_service_app/features/search/presentation/search_results_screen.dart';
import 'package:local_service_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:local_service_app/features/settings/presentation/settings_screen.dart';
import 'package:local_service_app/features/provider/presentation/public_provider_profile.dart';
import 'package:local_service_app/features/bookings/presentation/screens/booking_screen.dart';
import 'package:local_service_app/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:local_service_app/features/customer/presentation/screens/booking_success_screen.dart';
import 'package:local_service_app/features/customer/presentation/screens/booking_detail_screen.dart';
import 'package:local_service_app/features/customer/presentation/screens/write_review_screen.dart';
import 'package:local_service_app/features/customer/presentation/screens/saved_services_screen.dart';
import 'package:local_service_app/features/customer/presentation/screens/customer_profile_screen.dart';
import 'package:local_service_app/features/customer/presentation/screens/customer_dashboard.dart';
import 'package:local_service_app/features/provider/presentation/screens/provider_dashboard.dart';
import 'package:local_service_app/features/provider/presentation/screens/create_service_screen.dart';
import 'package:local_service_app/features/provider/presentation/screens/edit_service_screen.dart';
import 'package:local_service_app/features/provider/presentation/screens/my_services_screen.dart';
import 'package:local_service_app/features/provider/presentation/screens/incoming_bookings_screen.dart';
import 'package:local_service_app/features/provider/presentation/screens/provider_booking_detail_screen.dart';
import 'package:local_service_app/features/provider/presentation/screens/my_reviews_screen.dart';
import 'package:local_service_app/features/provider/presentation/screens/earnings_screen.dart';
import 'package:local_service_app/features/provider/presentation/screens/provider_profile_screen.dart';
import 'package:local_service_app/features/admin/presentation/screens/admin_dashboard.dart';
import 'package:local_service_app/features/admin/presentation/screens/reports_screen.dart';
import 'package:local_service_app/features/admin/presentation/screens/platform_settings_screen.dart';
import 'package:local_service_app/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:local_service_app/features/chat/presentation/screens/chat_screen.dart';

final _authProvider = AuthProvider();

class AppRouter {
  static AuthProvider get authProvider => _authProvider;

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _authProvider,
    redirect: (context, state) {
      final isLoading = _authProvider.isLoading;
      final isAuthenticated = _authProvider.isAuthenticated;
      final isGuest = _authProvider.isGuest;
      final role = _authProvider.role;
      final location = state.matchedLocation;

      if (isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final publicPaths = [
        '/splash',
        '/login',
        '/signup',
        '/forgot-password',
        '/home',
        '/search',
      ];

      final isPublic =
          publicPaths.contains(location) ||
          location.startsWith('/service/') ||
          location.startsWith('/provider/');

      if (!isAuthenticated && !isGuest) {
        if (isPublic) return null;
        return '/login';
      }

      if (isGuest) {
        final guestPaths = ['/home', '/search'];
        final isGuestAllowed =
            guestPaths.contains(location) ||
            location.startsWith('/service/') ||
            location.startsWith('/provider/');
        if (isGuestAllowed) return null;
        return '/login';
      }

      if (location == '/' || location == '/login' || location == '/signup') {
        return '/home';
      }

      if (location == '/forgot-password' && isAuthenticated) {
        return '/home';
      }

      return null;
    },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchResultsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/service/:id',
          builder: (context, state) => ServiceDetailScreen(
            serviceId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/provider/:id',
          builder: (context, state) => PublicProviderProfile(
            providerId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/customer',
          builder: (context, state) => const CustomerDashboard(),
        ),
        GoRoute(
          path: '/customer/book/:id',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return BookingScreen(
              serviceId: state.pathParameters['id']!,
              serviceName: extra['serviceName'] as String? ?? '',
              providerId: extra['providerId'] as String? ?? '',
              providerName: extra['providerName'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: '/customer/bookings',
          builder: (context, state) => const MyBookingsScreen(),
        ),
        GoRoute(
          path: '/customer/bookings/:id',
          builder: (context, state) => BookingDetailScreen(
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/customer/booking-success/:id',
          builder: (context, state) => BookingSuccessScreen(
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/customer/review/:serviceId/:bookingId',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return WriteReviewScreen(
              serviceId: state.pathParameters['serviceId']!,
              serviceName: extra['serviceName'] as String? ?? '',
              providerId: extra['providerId'] as String? ?? '',
              bookingId: state.pathParameters['bookingId'],
            );
          },
        ),
        GoRoute(
          path: '/customer/saved',
          builder: (context, state) => const SavedServicesScreen(),
        ),
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const CustomerProfileScreen(),
        ),
        GoRoute(
          path: '/customer/chats',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/customer/chat/:chatId',
          builder: (context, state) => ChatScreen(
            chatId: state.pathParameters['chatId']!,
            title: (state.extra as String?) ?? '',
          ),
        ),
        GoRoute(
          path: '/provider/dashboard',
          builder: (context, state) => const ProviderDashboard(),
        ),
        GoRoute(
          path: '/provider/services',
          builder: (context, state) => const MyServicesScreen(),
        ),
        GoRoute(
          path: '/provider/services/create',
          builder: (context, state) => const CreateServiceScreen(),
        ),
        GoRoute(
          path: '/provider/services/:id/edit',
          builder: (context, state) => EditServiceScreen(
            serviceId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/provider/bookings',
          builder: (context, state) => const IncomingBookingsScreen(),
        ),
        GoRoute(
          path: '/provider/bookings/:id',
          builder: (context, state) => ProviderBookingDetailScreen(
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/provider/reviews',
          builder: (context, state) => const MyReviewsScreen(),
        ),
        GoRoute(
          path: '/provider/earnings',
          builder: (context, state) => const EarningsScreen(),
        ),
        GoRoute(
          path: '/provider/profile',
          builder: (context, state) => const ProviderProfileScreen(),
        ),
        GoRoute(
          path: '/provider/chats',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/provider/chat/:chatId',
          builder: (context, state) => ChatScreen(
            chatId: state.pathParameters['chatId']!,
            title: (state.extra as String?) ?? '',
          ),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const PlatformSettingsScreen(),
        ),
      ],
    );
  }

