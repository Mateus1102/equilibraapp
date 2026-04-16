import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'funcionalidades/inicio/paginas/pagina_inicial.dart';

class AppEquilibra extends StatelessWidget {
  const AppEquilibra({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equilibra',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PaginaInicial(),
    );
  }
}