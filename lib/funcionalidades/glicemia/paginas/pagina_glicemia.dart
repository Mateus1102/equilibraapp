import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../dados/modelos/registro_glicemico.dart';
import '../../../dados/servicos/armazenamento_glicemia.dart';
import 'pagina_edicao_glicemia.dart';

class PaginaGlicemia extends StatefulWidget {
  const PaginaGlicemia({super.key});

  @override
  State<PaginaGlicemia> createState() => _PaginaGlicemiaState();
}

class _PaginaGlicemiaState extends State<PaginaGlicemia> {
  final TextEditingController controladorGlicemia = TextEditingController();
  final TextEditingController controladorObservacao = TextEditingController();
  final TextEditingController controladorBuscaObservacao =
      TextEditingController();

  final TextEditingController controladorHora = TextEditingController();
  final TextEditingController controladorMinuto = TextEditingController();

  final FocusNode focoHora = FocusNode();
  final FocusNode focoMinuto = FocusNode();

  final ArmazenamentoGlicemia armazenamento = ArmazenamentoGlicemia();

  final List<RegistroGlicemico> registros = [];

  Timer? temporizadorAtualizacaoPrazo;

  DateTime dataHoraSelecionada = DateTime.now();

  String filtroSelecionado = 'Hoje';
  String ordenacaoSelecionada = 'Mais recentes';

  final Color azulPrincipal = const Color(0xFF1565C0);
  final Color fundoTela = const Color(0xFFF6F9FF);

  @override
  void initState() {
    super.initState();

    final agora = DateTime.now();

    dataHoraSelecionada = agora;
    controladorHora.text = agora.hour.toString().padLeft(2, '0');
    controladorMinuto.text = agora.minute.toString().padLeft(2, '0');

    carregarRegistros();

    temporizadorAtualizacaoPrazo = Timer.periodic(
      const Duration(seconds: 20),
      (_) {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    temporizadorAtualizacaoPrazo?.cancel();

    controladorGlicemia.dispose();
    controladorObservacao.dispose();
    controladorBuscaObservacao.dispose();
    controladorHora.dispose();
    controladorMinuto.dispose();

    focoHora.dispose();
    focoMinuto.dispose();

    super.dispose();
  }

  Future<void> carregarRegistros() async {
    final dados = await armazenamento.carregar();

    if (!mounted) return;

    setState(() {
      registros
        ..clear()
        ..addAll(dados);
      limparRegistrosAntigos();
    });

    await armazenamento.salvar(registros);
  }

  void limparRegistrosAntigos() {
    final limite = DateTime.now().subtract(
      const Duration(days: 90),
    );

    registros.removeWhere(
      (item) => item.dataHora.isBefore(limite),
    );
  }

  Future<void> selecionarDataHora() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate:
          dataHoraSelecionada.isAfter(agora) ? agora : dataHoraSelecionada,
      firstDate: DateTime(2020),
      lastDate: agora,
    );

    if (data == null) return;

    final hora = int.tryParse(controladorHora.text) ?? 0;
    final minuto = int.tryParse(controladorMinuto.text) ?? 0;

    final novaData = DateTime(
      data.year,
      data.month,
      data.day,
      hora,
      minuto,
    );

    if (novaData.isAfter(agora)) {
      mostrarMensagem('Não é permitido informar data futura.');
      return;
    }

    setState(() {
      dataHoraSelecionada = novaData;
    });
  }

  void mostrarMensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> salvarRegistro() async {
    final texto = controladorGlicemia.text.trim();
    final observacao = controladorObservacao.text.trim();

    if (texto.isEmpty) {
      mostrarMensagem('Informe o valor da glicemia.');
      return;
    }

    final glicemia = int.tryParse(texto);

    if (glicemia == null) {
      mostrarMensagem('Digite um valor válido.');
      return;
    }

    final hora = int.tryParse(controladorHora.text) ?? -1;
    final minuto = int.tryParse(controladorMinuto.text) ?? -1;

    if (hora < 0 || hora > 23) {
      mostrarMensagem('Hora inválida.');
      return;
    }

    if (minuto < 0 || minuto > 59) {
      mostrarMensagem('Minuto inválido.');
      return;
    }

    final dataFinal = DateTime(
      dataHoraSelecionada.year,
      dataHoraSelecionada.month,
      dataHoraSelecionada.day,
      hora,
      minuto,
    );

    if (dataFinal.isAfter(DateTime.now())) {
      mostrarMensagem('A data e hora não podem ser futuras.');
      return;
    }

    final novo = RegistroGlicemico(
      glicemia: glicemia,
      observacao: observacao,
      dataHora: dataFinal,
      dataCriacao: DateTime.now(),
    );

    setState(() {
      registros.insert(0, novo);

      controladorGlicemia.clear();
      controladorObservacao.clear();

      final agora = DateTime.now();

      dataHoraSelecionada = agora;
      controladorHora.text = agora.hour.toString().padLeft(2, '0');
      controladorMinuto.text = agora.minute.toString().padLeft(2, '0');

      limparRegistrosAntigos();
    });

    await armazenamento.salvar(registros);

    mostrarMensagem('Registro salvo com sucesso.');
  }

  Future<void> editarRegistro(int indice) async {
    final atualizado =
        await Navigator.of(context).push<RegistroGlicemico>(
      MaterialPageRoute(
        builder: (_) => PaginaEdicaoGlicemia(
          registro: registros[indice],
        ),
      ),
    );

    if (atualizado == null) return;

    setState(() {
      registros[indice] = atualizado;
    });

    await armazenamento.salvar(registros);

    mostrarMensagem('Registro atualizado.');
  }

  Future<void> confirmarExclusaoRegistro(int indice) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir registro'),
          content: const Text(
            'Tem certeza que deseja excluir este registro?',
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
      registros.removeAt(indice);
    });

    await armazenamento.salvar(registros);

    mostrarMensagem('Registro excluído.');
  }

  List<RegistroGlicemico> obterRegistrosFiltrados() {
    final agora = DateTime.now();

    if (filtroSelecionado == 'Hoje') {
      return registros.where((item) {
        return item.dataHora.year == agora.year &&
            item.dataHora.month == agora.month &&
            item.dataHora.day == agora.day;
      }).toList();
    }

    int dias = 7;

    if (filtroSelecionado == '15 dias') dias = 15;
    if (filtroSelecionado == '30 dias') dias = 30;
    if (filtroSelecionado == '60 dias') dias = 60;
    if (filtroSelecionado == '90 dias') dias = 90;

    final limite = agora.subtract(Duration(days: dias));

    return registros.where((item) {
      return !item.dataHora.isBefore(limite) &&
          !item.dataHora.isAfter(agora);
    }).toList();
  }

  List<RegistroGlicemico> obterRegistrosFiltradosEOrdenados() {
    final lista = obterRegistrosFiltrados();

    final busca =
        controladorBuscaObservacao.text.trim().toLowerCase();

    final filtrados = lista.where((item) {
      if (busca.isEmpty) return true;

      return item.observacao
          .toLowerCase()
          .contains(busca);
    }).toList();

    switch (ordenacaoSelecionada) {
      case 'Mais antigos':
        filtrados.sort(
          (a, b) => a.dataHora.compareTo(b.dataHora),
        );
        break;

      case 'Maior glicemia':
        filtrados.sort(
          (a, b) => b.glicemia.compareTo(a.glicemia),
        );
        break;

      case 'Menor glicemia':
        filtrados.sort(
          (a, b) => a.glicemia.compareTo(b.glicemia),
        );
        break;

      default:
        filtrados.sort(
          (a, b) => b.dataHora.compareTo(a.dataHora),
        );
    }

    return filtrados;
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  Widget cardModerno({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget campoDecorado({
    required Widget child,
  }) {
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

  Widget construirGrafico() {
    final lista = obterRegistrosFiltrados();

    if (lista.length < 2) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'São necessários pelo menos 2 registros.',
          ),
        ),
      );
    }

    lista.sort((a, b) => a.dataHora.compareTo(b.dataHora));

    final spots = <FlSpot>[];

    for (int i = 0; i < lista.length; i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          lista[i].glicemia.toDouble(),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final indice = value.toInt();

                  if (indice < 0 || indice >= lista.length) {
                    return const SizedBox.shrink();
                  }

                  final total = lista.length;

                  int espacamento = 1;

                  if (total > 20) {
                    espacamento = 5;
                  } else if (total > 10) {
                    espacamento = 3;
                  } else if (total > 5) {
                    espacamento = 2;
                  }

                  if (indice % espacamento != 0 && indice != total - 1) {
                    return const SizedBox.shrink();
                  }

                  final data = lista[indice].dataHora;

                  final texto =
                      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      texto,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  if (value % 20 != 0) {
                    return const SizedBox.shrink();
                  }

                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              barWidth: 4,
              color: azulPrincipal,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: azulPrincipal.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirLista() {
    final lista = obterRegistrosFiltradosEOrdenados();

    if (lista.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text('Nenhum registro encontrado.'),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, indice) {
        final item = lista[indice];
        final indiceOriginal = registros.indexOf(item);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: cardModerno(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.glicemia} mg/dL',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: azulPrincipal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatarData(item.dataHora),
                ),
                if (item.observacao.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(item.observacao),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () =>
                          editarRegistro(indiceOriginal),
                      icon: Icon(
                        Icons.edit,
                        color: azulPrincipal,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          confirmarExclusaoRegistro(
                        indiceOriginal,
                      ),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget abaRegistrar(ThemeData tema) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: cardModerno(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registrar glicemia',
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: azulPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione sua medição para manter o acompanhamento atualizado.',
              style: tema.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            campoDecorado(
              child: TextField(
                controller: controladorGlicemia,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Glicemia (mg/dL)',
                  prefixIcon: Icon(Icons.monitor_heart),
                ),
              ),
            ),
            const SizedBox(height: 16),
            campoDecorado(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: selecionarDataHora,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data da medição',
                    prefixIcon:
                        Icon(Icons.calendar_month),
                  ),
                  child: Text(
                    '${dataHoraSelecionada.day.toString().padLeft(2, '0')}/'
                    '${dataHoraSelecionada.month.toString().padLeft(2, '0')}/'
                    '${dataHoraSelecionada.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: campoDecorado(
                    child: TextField(
                      controller: controladorHora,
                      focusNode: focoHora,
                      keyboardType:
                          TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                          2,
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor.length == 2) {
                          FocusScope.of(context)
                              .requestFocus(
                            focoMinuto,
                          );
                        }
                      },
                      decoration:
                          const InputDecoration(
                        labelText: 'Hora',
                        prefixIcon:
                            Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: campoDecorado(
                    child: TextField(
                      controller:
                          controladorMinuto,
                      focusNode: focoMinuto,
                      keyboardType:
                          TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                          2,
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor.length == 2) {
                          FocusScope.of(context)
                              .unfocus();
                        }
                      },
                      decoration:
                          const InputDecoration(
                        labelText: 'Minuto',
                        prefixIcon:
                            Icon(Icons.schedule),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            campoDecorado(
              child: TextField(
                controller:
                    controladorObservacao,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  prefixIcon: Padding(
                    padding:
                        EdgeInsets.only(bottom: 52),
                    child: Icon(Icons.edit_note),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: salvarRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulPrincipal,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Salvar registro',
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

  Widget abaHistorico() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          cardModerno(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: filtroSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Período',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Hoje',
                      child: Text('Hoje'),
                    ),
                    DropdownMenuItem(
                      value: '7 dias',
                      child: Text('7 dias'),
                    ),
                    DropdownMenuItem(
                      value: '15 dias',
                      child: Text('15 dias'),
                    ),
                    DropdownMenuItem(
                      value: '30 dias',
                      child: Text('30 dias'),
                    ),
                    DropdownMenuItem(
                      value: '60 dias',
                      child: Text('60 dias'),
                    ),
                    DropdownMenuItem(
                      value: '90 dias',
                      child: Text('90 dias'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      filtroSelecionado = valor;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: ordenacaoSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Ordenação',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Mais recentes',
                      child: Text('Mais recentes'),
                    ),
                    DropdownMenuItem(
                      value: 'Mais antigos',
                      child: Text('Mais antigos'),
                    ),
                    DropdownMenuItem(
                      value: 'Maior glicemia',
                      child: Text('Maior glicemia'),
                    ),
                    DropdownMenuItem(
                      value: 'Menor glicemia',
                      child: Text('Menor glicemia'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      ordenacaoSelecionada =
                          valor;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller:
                      controladorBuscaObservacao,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText:
                        'Buscar observação',
                    prefixIcon:
                        const Icon(Icons.search),
                    suffixIcon:
                        controladorBuscaObservacao
                                .text
                                .isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  controladorBuscaObservacao
                                      .clear();

                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.clear,
                                ),
                              )
                            : null,
                  ),
                ),
                const SizedBox(height: 20),
                construirGrafico(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          construirLista(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: fundoTela,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: azulPrincipal,
          title: const Text(
            'Glicemia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Registrar'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            abaRegistrar(tema),
            abaHistorico(),
          ],
        ),
      ),
    );
  }
}