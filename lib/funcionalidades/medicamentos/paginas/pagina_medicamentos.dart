import 'dart:async';
import 'package:flutter/material.dart';
import '../../../dados/modelos/medicamentos.dart';
import '../../../dados/modelos/controle_medicamento_diario.dart';
import '../../../dados/servicos/armazenamento_medicamentos.dart';
import '../../../dados/servicos/armazenamento_controle_medicamentos.dart';
import 'pagina_edicao_medicamento.dart';
import '../../../dados/servicos/servico_notificacoes.dart';

class PaginaMedicamentos extends StatefulWidget {
  const PaginaMedicamentos({super.key});

  @override
  State<PaginaMedicamentos> createState() => _PaginaMedicamentosState();
}

class _PaginaMedicamentosState extends State<PaginaMedicamentos> {
  final TextEditingController controladorNome = TextEditingController();
  final TextEditingController controladorObservacao = TextEditingController();
  final TextEditingController controladorBusca = TextEditingController();

  final ArmazenamentoMedicamentos armazenamento = ArmazenamentoMedicamentos();
  final ArmazenamentoControleMedicamentos armazenamentoControle =
      ArmazenamentoControleMedicamentos();

  Timer? temporizadorAtualizacaoPrazo;

  List<Medicamento> medicamentos = [];
  List<ControleMedicamentoDiario> controles = [];

  String tipoSelecionado = 'Comprimido';
  String refeicaoSelecionada = 'Café da manhã';
  String momentoSelecionado = 'Após a refeição';

  final Color azulPrincipal = const Color(0xFF1565C0);
  final Color fundoTela = const Color(0xFFF6F9FF);

  TimeOfDay horarioCafe = const TimeOfDay(hour: 7, minute: 00);
  TimeOfDay horarioAlmoco = const TimeOfDay(hour: 12, minute: 00);
  TimeOfDay horarioJantar = const TimeOfDay(hour: 19, minute: 00);

  @override
  void initState() {
    super.initState();
    carregarDados();

    temporizadorAtualizacaoPrazo = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    temporizadorAtualizacaoPrazo?.cancel();
    controladorNome.dispose();
    controladorObservacao.dispose();
    controladorBusca.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final dadosMedicamentos = await armazenamento.carregar();
    final dadosControles = await armazenamentoControle.carregar();

    if (!mounted) return;

    setState(() {
      medicamentos = dadosMedicamentos;
      controles = dadosControles;
      limparHistoricoAntigo();
    });

    await armazenamentoControle.salvar(controles);
    await reagendarNotificacoesMedicamentos();
  }

  void limparHistoricoAntigo() {
    final limite = DateTime.now().subtract(const Duration(days: 7));

    controles.removeWhere((controle) {
      final data = DateTime.tryParse(controle.dataControle);
      if (data == null) return true;
      return data.isBefore(DateTime(limite.year, limite.month, limite.day));
    });
  }

  String formatarDataControle(DateTime data) {
    final ano = data.year.toString();
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  String obterDataHoje() {
    return formatarDataControle(DateTime.now());
  }

  String formatarDataVisual(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes';
  }

  void mostrarMensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  TimeOfDay obterHorarioRefeicao(String refeicao) {
    if (refeicao == 'Café da manhã') {
      return horarioCafe;
    }

    if (refeicao == 'Almoço') {
      return horarioAlmoco;
    }

    return horarioJantar;
  }

  DateTime calcularHorarioNotificacao(Medicamento medicamento) {
    final agora = DateTime.now();
    final horarioBase = obterHorarioRefeicao(medicamento.refeicao);

    DateTime horario = DateTime(
      agora.year,
      agora.month,
      agora.day,
      horarioBase.hour,
      horarioBase.minute,
    );

    if (medicamento.momento == 'Antes da refeição') {
      horario = horario.subtract(const Duration(minutes: 20));
    } else {
      horario = horario.add(const Duration(minutes: 20));
    }

    if (horario.isBefore(agora)) {
      horario = horario.add(const Duration(days: 1));
    }

    return horario;
  }

  int gerarIdNotificacao(Medicamento medicamento) {
    final somenteNumeros = medicamento.id.replaceAll(RegExp(r'[^0-9]'), '');

    if (somenteNumeros.isEmpty) {
      return medicamento.nome.codeUnits.fold(0, (total, item) => total + item);
    }

    final valor = int.tryParse(somenteNumeros);

    if (valor == null) {
      return medicamento.nome.codeUnits.fold(0, (total, item) => total + item);
    }

    return valor.remainder(2147483647);
  }

  String montarTextoNotificacao(Medicamento medicamento) {
    return '${medicamento.refeicao} é uma grande refeição do dia. '
        'Você já tomou? Lembre-se de tomar ${medicamento.nome} '
        '${medicamento.momento.toLowerCase()}.';
  }

  Future<void> reagendarNotificacoesMedicamentos() async {
    await ServicoNotificacoes.cancelarTodas();

    for (final medicamento in medicamentos) {
      await ServicoNotificacoes.agendarNotificacaoDiaria(
        id: gerarIdNotificacao(medicamento),
        titulo: 'Lembrete de medicamento',
        corpo: montarTextoNotificacao(medicamento),
        horario: calcularHorarioNotificacao(medicamento),
      );
    }
  }

  bool estaTomadoNaData(Medicamento medicamento, String dataControle) {
    return controles.any((controle) {
      return controle.medicamentoId == medicamento.id &&
          controle.dataControle == dataControle &&
          controle.tomado;
    });
  }

  bool estaTomadoHoje(Medicamento medicamento) {
    return estaTomadoNaData(medicamento, obterDataHoje());
  }

  int obterPendenciasHoje() {
    int total = 0;

    for (final medicamento in medicamentos) {
      if (!estaTomadoHoje(medicamento)) {
        total++;
      }
    }

    return total;
  }

  Future<void> alternarTomado(Medicamento medicamento, bool tomado) async {
    final hoje = obterDataHoje();

    setState(() {
      controles.removeWhere((controle) {
        return controle.medicamentoId == medicamento.id &&
            controle.dataControle == hoje;
      });

      if (tomado) {
        controles.add(
          ControleMedicamentoDiario(
            medicamentoId: medicamento.id,
            dataControle: hoje,
            tomado: true,
            dataConfirmacao: DateTime.now(),
          ),
        );
      }

      limparHistoricoAntigo();
    });

    await armazenamentoControle.salvar(controles);
  }

  Future<void> salvarMedicamento() async {
    final nome = controladorNome.text.trim();
    final observacao = controladorObservacao.text.trim();

    if (nome.isEmpty) {
      mostrarMensagem('Informe o nome do medicamento.');
      return;
    }

    final novoMedicamento = Medicamento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      tipo: tipoSelecionado,
      refeicao: refeicaoSelecionada,
      momento: momentoSelecionado,
      observacao: observacao,
      dataCriacao: DateTime.now(),
    );

    setState(() {
      medicamentos.insert(0, novoMedicamento);
      controladorNome.clear();
      controladorObservacao.clear();
      tipoSelecionado = 'Comprimido';
      refeicaoSelecionada = 'Café da manhã';
      momentoSelecionado = 'Após a refeição';
    });

    await armazenamento.salvar(medicamentos);
    await reagendarNotificacoesMedicamentos();

    mostrarMensagem('Medicamento salvo com sucesso.');
  }

  Future<void> editarMedicamento(int indice) async {
    final medicamentoAtual = medicamentos[indice];

    final medicamentoAtualizado =
        await Navigator.of(context).push<Medicamento>(
      MaterialPageRoute(
        builder: (_) => PaginaEdicaoMedicamento(
          medicamento: medicamentoAtual,
        ),
      ),
    );

    if (medicamentoAtualizado == null) return;

    setState(() {
      medicamentos[indice] = medicamentoAtualizado;
    });

    await armazenamento.salvar(medicamentos);
    await reagendarNotificacoesMedicamentos();

    mostrarMensagem('Medicamento atualizado com sucesso.');
  }

  Future<void> excluirMedicamento(int indice) async {
    final medicamento = medicamentos[indice];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir medicamento'),
          content: const Text(
            'Tem certeza que deseja excluir este medicamento?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() {
      medicamentos.removeAt(indice);
      controles.removeWhere(
        (controle) => controle.medicamentoId == medicamento.id,
      );
    });

    await armazenamento.salvar(medicamentos);
    await armazenamentoControle.salvar(controles);
    await reagendarNotificacoesMedicamentos();

    mostrarMensagem('Medicamento excluído com sucesso.');
  }

  List<Medicamento> obterMedicamentosFiltrados() {
    final busca = controladorBusca.text.trim().toLowerCase();

    return medicamentos.where((medicamento) {
      if (busca.isEmpty) return true;

      return medicamento.nome.toLowerCase().contains(busca) ||
          medicamento.tipo.toLowerCase().contains(busca) ||
          medicamento.refeicao.toLowerCase().contains(busca) ||
          medicamento.momento.toLowerCase().contains(busca) ||
          medicamento.observacao.toLowerCase().contains(busca);
    }).toList();
  }

  List<Medicamento> obterMedicamentosPorRefeicao(String refeicao) {
    return obterMedicamentosFiltrados().where((medicamento) {
      return medicamento.refeicao == refeicao;
    }).toList();
  }

  Widget cardModerno({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
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

  Widget campoDecorado({required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget construirCardMedicamento(
    Medicamento medicamento,
    int indiceOriginal, {
    bool mostrarCheck = false,
  }) {
    final tomado = estaTomadoHoje(medicamento);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicamento.nome,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text('Tipo: ${medicamento.tipo}'),
          Text('Refeição: ${medicamento.refeicao}'),
          Text('Momento: ${medicamento.momento}'),
          if (medicamento.observacao.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Observação: ${medicamento.observacao}'),
          ],
          const SizedBox(height: 10),
          if (mostrarCheck)
            Row(
              children: [
                Checkbox(
                  value: tomado,
                  activeColor: azulPrincipal,
                  onChanged: (valor) {
                    alternarTomado(medicamento, valor ?? false);
                  },
                ),
                Text(
                  tomado ? 'Tomado hoje' : 'Pendente hoje',
                  style: TextStyle(
                    color: tomado ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => editarMedicamento(indiceOriginal),
                icon: Icon(
                  Icons.edit_outlined,
                  color: azulPrincipal,
                ),
              ),
              IconButton(
                onPressed: () => excluirMedicamento(indiceOriginal),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget construirGrupoRefeicao(String refeicao, IconData icone) {
    final lista = obterMedicamentosPorRefeicao(refeicao);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: cardModerno(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: azulPrincipal),
                const SizedBox(width: 8),
                Text(
                  refeicao,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: azulPrincipal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lista.isEmpty)
              const Text('Nenhum medicamento cadastrado para esta refeição.'),
            ...lista.map((medicamento) {
              final indiceOriginal = medicamentos.indexOf(medicamento);

              return construirCardMedicamento(
                medicamento,
                indiceOriginal,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget abaCadastrar(ThemeData tema) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: cardModerno(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cadastrar rotina medicamentosa',
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: azulPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre o medicamento conforme a refeição em que ele deve ser utilizado.',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            campoDecorado(
              child: TextField(
                controller: controladorNome,
                decoration: const InputDecoration(
                  labelText: 'Nome do medicamento',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            campoDecorado(
              child: DropdownButtonFormField<String>(
                value: tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Comprimido',
                    child: Text('Comprimido'),
                  ),
                  DropdownMenuItem(
                    value: 'Insulina',
                    child: Text('Insulina'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;

                  setState(() {
                    tipoSelecionado = valor;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            campoDecorado(
              child: DropdownButtonFormField<String>(
                value: refeicaoSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Refeição',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Café da manhã',
                    child: Text('Café da manhã'),
                  ),
                  DropdownMenuItem(
                    value: 'Almoço',
                    child: Text('Almoço'),
                  ),
                  DropdownMenuItem(
                    value: 'Jantar',
                    child: Text('Jantar'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;

                  setState(() {
                    refeicaoSelecionada = valor;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            campoDecorado(
              child: DropdownButtonFormField<String>(
                value: momentoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Momento',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Antes da refeição',
                    child: Text('Antes da refeição'),
                  ),
                  DropdownMenuItem(
                    value: 'Após a refeição',
                    child: Text('Após a refeição'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;

                  setState(() {
                    momentoSelecionado = valor;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            campoDecorado(
              child: TextField(
                controller: controladorObservacao,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 52),
                    child: Icon(Icons.edit_note_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: salvarMedicamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Salvar medicamento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget abaRotina(ThemeData tema) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          cardModerno(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rotina por refeição',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: azulPrincipal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Veja quais medicamentos estão vinculados a cada grande refeição.',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                campoDecorado(
                  child: TextField(
                    controller: controladorBusca,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Buscar medicamento',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: controladorBusca.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                controladorBusca.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          construirGrupoRefeicao(
            'Café da manhã',
            Icons.free_breakfast_outlined,
          ),
          construirGrupoRefeicao(
            'Almoço',
            Icons.lunch_dining_outlined,
          ),
          construirGrupoRefeicao(
            'Jantar',
            Icons.dinner_dining_outlined,
          ),
        ],
      ),
    );
  }

  Widget abaHoje(ThemeData tema) {
    final lista = obterMedicamentosFiltrados();
    final pendencias = obterPendenciasHoje();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          cardModerno(
            child: Row(
              children: [
                Icon(
                  pendencias == 0
                      ? Icons.notifications_none_outlined
                      : Icons.notifications_active_outlined,
                  color: pendencias == 0 ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pendencias == 0
                        ? 'Nenhuma pendência hoje.'
                        : '$pendencias medicamento(s) pendente(s) hoje.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: pendencias == 0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          cardModerno(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Medicamentos de hoje',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: azulPrincipal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Marque os medicamentos que já foram tomados hoje.',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (lista.isEmpty)
            cardModerno(
              child: const Text(
                'Nenhum medicamento cadastrado para acompanhamento.',
              ),
            ),
          ...lista.map((medicamento) {
            final indiceOriginal = medicamentos.indexOf(medicamento);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: cardModerno(
                child: construirCardMedicamento(
                  medicamento,
                  indiceOriginal,
                  mostrarCheck: true,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget abaSemana(ThemeData tema) {
    final hoje = DateTime.now();
    final dias = List.generate(7, (indice) {
      return DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
      ).subtract(Duration(days: indice));
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          cardModerno(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Histórico semanal',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: azulPrincipal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe os medicamentos tomados e pendentes nos últimos 7 dias.',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...dias.map((dia) {
            final dataControle = formatarDataControle(dia);

            int tomados = 0;
            int pendentes = 0;

            for (final medicamento in medicamentos) {
              if (medicamento.dataCriacao.isAfter(
                DateTime(dia.year, dia.month, dia.day, 23, 59, 59),
              )) {
                continue;
              }

              if (estaTomadoNaData(medicamento, dataControle)) {
                tomados++;
              } else {
                pendentes++;
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: cardModerno(
                child: Row(
                  children: [
                    Icon(
                      pendentes == 0 && tomados > 0
                          ? Icons.check_circle_outline
                          : Icons.notifications_active_outlined,
                      color: pendentes == 0 && tomados > 0
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formatarDataVisual(dia),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$tomados tomado(s) • $pendentes pendente(s)',
                      style: TextStyle(
                        color: pendentes == 0 && tomados > 0
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: fundoTela,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: azulPrincipal,
          title: const Text(
            'Medicamentos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            tabs: [
              Tab(text: 'Cadastrar'),
              Tab(text: 'Rotina'),
              Tab(text: 'Hoje'),
              Tab(text: 'Semana'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            abaCadastrar(tema),
            abaRotina(tema),
            abaHoje(tema),
            abaSemana(tema),
          ],
        ),
      ),
    );
  }
}