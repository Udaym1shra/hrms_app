import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/employee_dashboard.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final apiService = ApiService(storageService);
  final authService = AuthService(apiService, storageService);
  
  runApp(MyApp(
    storageService: storageService,
    apiService: apiService,
    authService: authService,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final AuthService authService;
  
  const MyApp({
    Key? key, 
    required this.storageService,
    required this.apiService,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => EmployeeProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'HRMS Mobile',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (authProvider.isAuthenticated) {
          return const EmployeeDashboard();
        }
        
        return const LoginScreen();
      },
    );
  }
}
