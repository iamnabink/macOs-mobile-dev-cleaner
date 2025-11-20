import 'package:flutter/cupertino.dart';
import 'package:flutter_cleaner/pages/cleaner_home_page.dart';
import 'package:flutter_cleaner/constants.dart';

class APKBuildCleanerApp extends StatelessWidget {
  const APKBuildCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: const CleanerHomePage(),
    );
  }
}
