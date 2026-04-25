import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'utils/api_client.dart';
import 'utils/app_theme.dart';
import 'viewmodels/coin_viewmodel.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Init Dio client
  ApiClient.instance.init();

  // Register GetX controller globally
  Get.put(CoinViewModel());

  runApp(const CryptoApp());
}

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CryptoTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      home: const HomeScreen(),
    );
  }
}