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

  final Color azulPrincipal = const Color(0xFF1565C0);

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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: azulPrincipal.withOpacity(0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: azulPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              );
            }

            return const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: azulPrincipal);
            }

            return const IconThemeData(color: Colors.black54);
          }),
        ),
        child: NavigationBar(
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
      ),
    );
  }
}

class PaginaResumoStateContainer {
  static VoidCallback? recarregar;
}

class PaginaResumo extends StatefulWidget {
  const PaginaResumo({super.key});

  @override
  State<PaginaResumo> createState() => _PaginaResumoState();
}

class _PaginaResumoState extends State<PaginaResumo> {
  final ArmazenamentoGlicemia armazenamento = ArmazenamentoGlicemia();

  final Color azulPrincipal = const Color(0xFF1565C0);
  final Color fundoTela = const Color(0xFFF6F9FF);

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

  Widget cardModerno({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget construirTopoResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: azulPrincipal,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: azulPrincipal.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Bem-vindo ao Equilibra',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Acompanhe seus registros e mantenha sua rotina de saúde organizada.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget construirSelo({
    required String texto,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget construirCardIndicador({
    required IconData icone,
    required String titulo,
    required String valor,
    required String destaque,
    required Color corDestaque,
  }) {
    return cardModerno(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: azulPrincipal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icone,
              color: azulPrincipal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          construirSelo(
            texto: destaque,
            cor: corDestaque,
          ),
        ],
      ),
    );
  }

  Widget construirEstadoVazio() {
    return cardModerno(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            color: azulPrincipal,
            size: 34,
          ),
          const SizedBox(height: 14),
          const Text(
            'Nenhum registro glicêmico encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vá até a aba Glicemia para adicionar seu primeiro registro e liberar seu resumo de acompanhamento.',
            style: TextStyle(
              color: Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget construirConteudo() {
    if (carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final resumo = ResumoGlicemico.aPartirDeLista(registros);

    if (resumo.totalRegistros == 0) {
      return construirEstadoVazio();
    }

    final statusAtual = resumo.obterClassificacaoUltimoRegistro();
    final corAtual = resumo.obterCorStatus(statusAtual);

    final statusMedia = resumo.obterClassificacaoMedia();
    final corMedia = resumo.obterCorStatus(statusMedia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cardModerno(
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: azulPrincipal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: azulPrincipal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total de registros',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resumo.totalRegistros}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        construirCardIndicador(
          icone: Icons.monitor_heart_outlined,
          titulo: 'Último registro',
          valor:
              '${resumo.ultimoRegistro!.glicemia} mg/dL\n${formatarDataHora(resumo.ultimoRegistro!.dataHora)}',
          destaque: statusAtual,
          corDestaque: corAtual,
        ),
        construirCardIndicador(
          icone: Icons.analytics_outlined,
          titulo: 'Média glicêmica (últimos 30 dias)',
          valor: resumo.mediaGlicemia == 0
              ? 'Sem registros no último mês'
              : '${resumo.mediaGlicemia.toStringAsFixed(1)} mg/dL',
          destaque: statusMedia,
          corDestaque: corMedia,
        ),
        construirCardIndicador(
          icone: Icons.trending_up_outlined,
          titulo: 'Maior valor',
          valor: resumo.maiorGlicemia != null
              ? '${resumo.maiorGlicemia} mg/dL'
              : 'Sem registros no último mês',
          destaque: '30 dias',
          corDestaque: Colors.blueGrey,
        ),
        construirCardIndicador(
          icone: Icons.trending_down_outlined,
          titulo: 'Menor valor',
          valor: resumo.menorGlicemia != null
              ? '${resumo.menorGlicemia} mg/dL'
              : 'Sem registros no último mês',
          destaque: '30 dias',
          corDestaque: Colors.blueGrey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoTela,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: azulPrincipal,
        centerTitle: true,
        title: const Text(
          'Início',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            construirTopoResumo(),
            const Text(
              'Resumo glicêmico',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            construirConteudo(),
          ],
        ),
      ),
    );
  }
}