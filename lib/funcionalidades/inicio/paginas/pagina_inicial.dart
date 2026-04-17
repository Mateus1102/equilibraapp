import 'package:flutter/material.dart';
import '../../../dados/modelos/registro_glicemico.dart';
import '../../../dados/servicos/armazenamento_glicemia.dart';
import '../../../dados/servicos/resumo_glicemico.dart';
import '../../glicemia/paginas/pagina_glicemia.dart';
import '../../medicamentos/paginas/pagina_medicamentos.dart';
import '../../anotacoes/paginas/pagina_anotacoes.dart';
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
    PaginaMedicamentos(),
    PaginaAnotacoes(),
    PaginaPerfil(),
  ];

  void alterarPagina(int novoIndice) {
    setState(() {
      indiceAtual = novoIndice;
    });

    if (novoIndice == 0) {
      PaginaResumoStateContainer.recarregar?.call();
    }
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
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medicamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Anotações',
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

class PaginaResumoStateContainer {
  static VoidCallback? recarregar;
}

Widget construirCardIndicador({
  required String titulo,
  required String valor,
  required String destaque,
  required Color corDestaque,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: corDestaque.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  destaque,
                  style: TextStyle(
                    color: corDestaque,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
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
    PaginaResumoStateContainer.recarregar = carregarDados;
    carregarDados();
  }

  @override
  void dispose() {
    PaginaResumoStateContainer.recarregar = null;
    super.dispose();
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

    final statusAtual = resumo.obterClassificacaoUltimoRegistro();
    final corAtual = resumo.obterCorStatus(statusAtual);

    final statusMedia = resumo.obterClassificacaoMedia();
    final corMedia = resumo.obterCorStatus(statusMedia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            title: const Text('Total de registros'),
            subtitle: Text('${resumo.totalRegistros}'),
          ),
        ),
        construirCardIndicador(
          titulo: 'Último registro',
          valor:
              '${resumo.ultimoRegistro!.glicemia} mg/dL\n${formatarDataHora(resumo.ultimoRegistro!.dataHora)}',
          destaque: statusAtual,
          corDestaque: corAtual,
        ),
        construirCardIndicador(
          titulo: 'Média glicêmica (últimos 30 dias)',
          valor: resumo.mediaGlicemia == 0
              ? 'Sem registros no último mês'
              : '${resumo.mediaGlicemia.toStringAsFixed(1)} mg/dL',
          destaque: statusMedia,
          corDestaque: corMedia,
        ),
        construirCardIndicador(
          titulo: 'Maior valor',
          valor: resumo.maiorGlicemia != null
              ? '${resumo.maiorGlicemia} mg/dL'
              : 'Sem registros no último mês',
          destaque: 'Últimos 30 dias',
          corDestaque: Colors.blueGrey,
        ),
        construirCardIndicador(
          titulo: 'Menor valor',
          valor: resumo.menorGlicemia != null
              ? '${resumo.menorGlicemia} mg/dL'
              : 'Sem registros no último mês',
          destaque: 'Últimos 30 dias',
          corDestaque: Colors.blueGrey,
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