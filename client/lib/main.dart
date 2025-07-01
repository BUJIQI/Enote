import 'package:flutter/material.dart';
import 'pages/score_home_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/more_settings_page.dart';
import 'pages/theme_provider.dart';
import 'pages/user_info.dart';
import 'package:provider/provider.dart';



void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// 主入口 App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: '曲谱 App',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.currentTheme,
      home:ScoreHomePage(), 
      routes: {
        '/main': (context) => ScoreHomePage(),
        '/user_info': (context) => const UserInfoPage(token: '', username: ''),
        '/privacy-policy': (context) => const PrivacyPolicyPage(),
        '/more-settings': (context) => const MoreSettingsPage(),
      },
    );
  }
}








