import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:clisync/firebase_options.dart';
import 'package:clisync/screens/auth/login_screen.dart';
import 'package:clisync/screens/home/home_screen.dart';
import 'package:clisync/screens/relatorios/pendencias/pendencias_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configura tratamento de erro global para evitar telas em branco
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Em produção, você pode querer enviar isso para um serviço de crash reporting
  };
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ClisyncApp());
}

class ClisyncApp extends StatelessWidget {
  const ClisyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clisync',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      // Configura ErrorWidget customizado para evitar telas em branco
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child ?? const SizedBox(),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
      routes: {
        '/pendencias': (context) => const PendenciasScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const HomeScreen(key: ValueKey('home_screen'));
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}


