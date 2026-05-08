import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api_service.dart';
import 'services/offline_service.dart';
import 'screens/root_screen.dart';
import 'screens/role_selection_screen.dart';
import 'utils/logger.dart';
import 'widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du Logger Global
  FlutterError.onError = (FlutterErrorDetails details) {
    logError('Flutter Framework Error', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logError('Asynchronous Error', error, stack);
    return true;
  };

  // Initialiser les services
  await ApiService().initialize();
  await OfflineService().initialize();

  runApp(
    const ProviderScope(
      child: ErrorBoundary(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NaissanceChain',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF10B981),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF3B82F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xFF1E3A8A)),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1E3A8A),
          unselectedItemColor: Color(0xFF9CA3AF),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[200],
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: GoogleFonts.poppins(),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(),
          displayMedium: GoogleFonts.poppins(),
          displaySmall: GoogleFonts.poppins(),
          headlineLarge: GoogleFonts.poppins(),
          headlineMedium: GoogleFonts.poppins(),
          headlineSmall: GoogleFonts.poppins(),
          titleLarge: GoogleFonts.poppins(),
          titleMedium: GoogleFonts.poppins(),
          titleSmall: GoogleFonts.poppins(),
          bodyLarge: GoogleFonts.poppins(),
          bodyMedium: GoogleFonts.poppins(),
          bodySmall: GoogleFonts.poppins(),
          labelLarge: GoogleFonts.poppins(),
          labelMedium: GoogleFonts.poppins(),
          labelSmall: GoogleFonts.poppins(),
        ),
      ),
      home: const RootScreen(),
    );
  }
}