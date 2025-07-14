import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/presentation/app.dart';
import 'src/data/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy News',
      theme: ThemeData(
        primaryColor: tossBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: tossBlue,
          primary: tossBlue,
          secondary: tossBlueDark,
          background: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: tossBlue,
          elevation: 0,
          iconTheme: IconThemeData(color: tossBlue),
          titleTextStyle: TextStyle(
            color: tossBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'NotoSans',
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
            fontFamily: 'NotoSans',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'NotoSans',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontFamily: 'NotoSans',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: tossBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: tossBlue,
            side: BorderSide(color: tossBlue, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tossBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tossBlue, width: 2),
          ),
        ),
        useMaterial3: false,
      ),
      home: const App(),
    );
  }
}
