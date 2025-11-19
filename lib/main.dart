import 'package:diabetes_app2/screens/alerts/alerts_form_screen.dart';
import 'package:diabetes_app2/screens/alerts/alerts_list_screen.dart';
import 'package:diabetes_app2/screens/graficos/exportacao_screen.dart';
//import 'package:diabetes_app2/screens/graficos/grafico_screen.dart';
import 'package:diabetes_app2/screens/graficos/graficos_screen.dart';
import 'package:diabetes_app2/screens/perfil/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notifications_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationsService().init();

  runApp(const DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Diabetes APP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF7EC3FF),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF7EC3FF),
            foregroundColor: Colors.black,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        home: const _Gate(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/perfil': (context) => const ProfileScreen(),
          '/alertas': (context) => const AlertsListScreen(),
          '/login': (context)=> const LoginScreen(),
          '/alertas/novo': (context) => const AlertsFormScreen(),
          '/graficos': (context) => const GraficosScreen(),
          '/exportacao': (context) => const ExportacaoScreen(),
        },
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.of(context).authStateChanges,
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.hasData ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
