import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/checkout_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/payment_details_screen.dart';
import 'screens/product_detail_screen.dart';
import 'widgets/app_background.dart';
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF060E1D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.publicAnonKey,
  );
  runApp(const LoopKosApp());
}

class LoopKosApp extends StatelessWidget {
  const LoopKosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'LoopKos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        home: const _AuthGate(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0));
            case '/bundle':
              return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 1));
            case '/product':
              final id = settings.arguments?.toString() ?? '';
              return MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: id));
            case '/checkout':
              return MaterialPageRoute(builder: (_) => const CheckoutScreen());
            case '/payment':
              final id = settings.arguments?.toString() ?? '';
              return MaterialPageRoute(builder: (_) => PaymentDetailsScreen(transactionId: id));
            case '/sell':
              return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 2));
            case '/transactions':
              return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 3));
            case '/profile':
              return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 4));
            case '/my-listings':
              return MaterialPageRoute(builder: (_) => const MyListingsScreen());
            default:
              return MaterialPageRoute(builder: (_) => const _AuthGate());
          }
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.cardGlass,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderGlass),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 36,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Memuat LoopKos...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (auth.user == null) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}
