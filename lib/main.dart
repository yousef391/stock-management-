import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'presenation/screens/login_screen.dart';
import 'presenation/viewmodels/auth_viewmodel.dart';
import 'presenation/viewmodels/product_viewmodel.dart';
import 'presenation/viewmodels/stock_viewmodel.dart';
import 'presenation/screens/dashboard_screen.dart';
import 'presenation/screens/product_list_screen.dart';
import 'presenation/screens/stock_screen.dart';
import 'presenation/widgets/app_side_panel.dart';
import 'data/repo/product_repository.dart';
import 'data/repo/stock_repository.dart';
import 'data/repo/company_repository.dart';
import 'presenation/viewmodels/company_viewmodel.dart';
import 'presenation/screens/company_info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await supabase.Supabase.initialize(
    url: 'https://lhlnydqnojiuvftczppa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxobG55ZHFub2ppdXZmdGN6cHBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3ODUxMTYsImV4cCI6MjA2NjM2MTExNn0.YEtOjf5yEIrcpuCK4P52rRvkNp0h3EzE7I1UgB5vIUw',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProductViewModel(ProductRepository())),
        ChangeNotifierProvider(create: (_) => StockViewModel(StockRepository())),
        ChangeNotifierProvider(create: (_) => CompanyViewModel(CompanyRepository())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stock Management',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthViewModel>(context);
    if (auth.user == null) {
      return const LoginScreen();
    } else {
      return const MainNavigationScreen();
    }
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  NavigationItem _currentItem = NavigationItem.dashboard;

  Widget _getCurrentScreen() {
    switch (_currentItem) {
      case NavigationItem.dashboard:
        return const DashboardScreen();
      case NavigationItem.products:
        return const ProductListScreen();
      case NavigationItem.stock:
        return const StockScreen();
      case NavigationItem.company:
        return const CompanyInfoScreen();
    }
  }

  String _getCurrentTitle() {
    switch (_currentItem) {
      case NavigationItem.dashboard:
        return 'Dashboard';
      case NavigationItem.products:
        return 'Products';
      case NavigationItem.stock:
        return 'Stock Operations';
      case NavigationItem.company:
        return 'Company Info';
    }
  }

  void _onNavigationChanged(NavigationItem item) {
    setState(() {
      _currentItem = item;
    });
  }

  Future<void> _onLogout() async {
    await Provider.of<AuthViewModel>(context, listen: false).signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // Desktop/tablet: show side panel
          return Scaffold(
            appBar: AppBar(
              title: Text(_getCurrentTitle()),
              backgroundColor: Colors.white,
              elevation: 1,
            ),
            body: Row(
              children: [
                Container(
                  width: 280,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: AppSidePanel(
                    currentItem: _currentItem,
                    onNavigationChanged: _onNavigationChanged,
                    onLogout: _onLogout,
                  ),
                ),
                Expanded(child: _getCurrentScreen()),
              ],
            ),
          );
        } else {
          // Mobile: use Drawer
          return Scaffold(
            appBar: AppBar(
              title: Text(_getCurrentTitle()),
              backgroundColor: Colors.white,
              elevation: 1,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: Drawer(
              child: AppSidePanel(
                currentItem: _currentItem,
                onNavigationChanged: _onNavigationChanged,
                onLogout: _onLogout,
              ),
            ),
            body: _getCurrentScreen(),
          );
        }
      },
    );
  }
}
