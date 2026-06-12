import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dados/servicos/armazenamento_usuario.dart';
import 'funcionalidades/autenticacao/paginas/pagina_login.dart';
import 'funcionalidades/inicio/paginas/pagina_inicial.dart';

class AppEquilibra extends StatelessWidget {
  const AppEquilibra({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
      
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppEquilibra.navigatorKey,
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      home: const VerificadorSessao(),
    );
  }
}

class VerificadorSessao extends StatefulWidget {
  const VerificadorSessao({super.key});

  @override
  State<VerificadorSessao> createState() => _VerificadorSessaoState();
}

class _VerificadorSessaoState extends State<VerificadorSessao> {
  final ArmazenamentoUsuario armazenamentoUsuario = ArmazenamentoUsuario();

  @override
  void initState() {
    super.initState();
    verificarSessao();
  }

  Future<void> verificarSessao() async {
    final usuarioLogado = await armazenamentoUsuario.obterUsuarioLogado();

    if (!mounted) return;

    if (usuarioLogado != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PaginaInicial(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PaginaLogin(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F9FF),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}