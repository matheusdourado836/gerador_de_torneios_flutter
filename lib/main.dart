import 'dart:ui';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/pages/history/history_page.dart';
import 'package:volleyball_tournament_app/pages/home_page.dart';
import 'package:volleyball_tournament_app/pages/players/players_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:volleyball_tournament_app/pages/responsive/responsive_layout.dart';
import 'package:volleyball_tournament_app/pages/tournament/matches_mobile_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/matches_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/tournament_mobile_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/tournament_page.dart';
import 'package:volleyball_tournament_app/routes/go_router.dart';
import 'package:volleyball_tournament_app/teste_mobile.dart';
import 'controller/data_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
      MultiProvider(providers: [
        ChangeNotifierProvider(create: (context) => DataController()),
      ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
      routerDelegate: AppRouter.router.routerDelegate,
      title: 'UTAC Torneios APP',
      scrollBehavior: MyCustomScrollBehavior(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(42, 35, 42, 1),
          primary: const Color.fromRGBO(42, 35, 42, 1),
          secondary: const Color.fromRGBO(173, 80, 144, 1),
          tertiary: Colors.white
        ),
        useMaterial3: true,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color.fromRGBO(42, 35, 42, 1)
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(42, 35, 42, 1),
            foregroundColor: Colors.white,
            fixedSize: const Size(250, 50)
          )
        )
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}