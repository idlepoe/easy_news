import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/constants/app_theme.dart';
import 'page/news_list_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Easy News',
        theme: AppTheme.lightTheme,
        home: const NewsListPage(),
      ),
    );
  }
}
