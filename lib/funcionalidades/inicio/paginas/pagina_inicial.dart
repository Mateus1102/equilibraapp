import 'package:flutter/material.dart';
import '../../../dados/modelos/registro_glicemico.dart';
import '../../../dados/servicos/armazenamento_glicemia.dart';
import '../../../dados/servicos/resumo_glicemico.dart';
import '../../glicemia/paginas/pagina_glicemia.dart';
import '../../perfil/paginas/pagina_perfil.dart';

class PaginaInicial extends StatefulWidget {
  const PaginaInicial({super.key});

  @override
  State<PaginaInicial> createState() => _PaginaInicialState();
}

class _PaginaInicialState extends State<PaginaInicial> {
  int indiceAtual = 0;

  final List<Widget> paginas = const [
    PaginaResumo(),
    PaginaGlicemia(),
    PaginaPerfil(),
  ];

  void alterarPagina(int novoIndice) {
    setState(() {
      indiceAtual = novoIndice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: paginas[indiceAtual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceAtual,
        onDestinationSelected: alterarPagina,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Glicemia',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class PaginaResumo extends StatefulWidget {
  const PaginaResumo({super.key});

  @override
  State<PaginaResumo> createState() => _PaginaResumoState();
}

class _PaginaResumoState extends State<PaginaResumo> {
  final armazenamento = ArmazenamentoGlicemia();

  bool carregando = true;
  List<RegistroGlicemico> registros = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final dados = await armazenamento.carregar();

    if (!mounted) return;

    setState(() {
      registros = dados;
      carregando = false;
    });
  }

  String formatarDataHora(DateTime dataHora) {
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = dataHora.month.toString().padLeft(2, '0');
    final ano = dataHora.year.toString();
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  Widget construirConteudo() {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final resumo = ResumoGlicemico.aPartirDeLista(registros);

    if (resumo.totalRegistros == 0) {
      return const Text(
        'Nenhum registro glicêmico encontrado. Vá até a aba Glicemia para adicionar seu primeiro registro.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            title: const Text('Total de registros'),
            subtitle: Text('${resumo.totalRegistros}'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Último registro'),
            subtitle: Text(
              '${resumo.ultimoRegistro!.glicemia} mg/dL\n${formatarDataHora(resumo.ultimoRegistro!.dataHora)}',
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Média glicêmica'),
            subtitle: Text('${resumo.mediaGlicemia.toStringAsFixed(1)} mg/dL'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Maior valor'),
            subtitle: Text('${resumo.maiorGlicemia} mg/dL'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Menor valor'),
            subtitle: Text('${resumo.menorGlicemia} mg/dL'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Resumo glicêmico',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            construirConteudo(),
          ],
        ),
      ),
    );
  }
}