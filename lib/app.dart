import 'package:flutter/material.dart';
import 'funcionalidades/inicio/paginas/pagina_inicial.dart';

class AppEquilibra extends StatelessWidget {
  const AppEquilibra({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equilibra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PaginaInicial(),
    );
  }
}