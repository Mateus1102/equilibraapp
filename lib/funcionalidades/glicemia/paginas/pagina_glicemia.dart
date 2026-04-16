import 'package:flutter/material.dart';
import '../../../dados/modelos/registro_glicemico.dart';
import '../../../dados/servicos/armazenamento_glicemia.dart';
import 'pagina_edicao_glicemia.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class PaginaGlicemia extends StatefulWidget {
  const PaginaGlicemia({super.key});

  @override
  State<PaginaGlicemia> createState() => _PaginaGlicemiaState();
}

class _PaginaGlicemiaState extends State<PaginaGlicemia> {
  final TextEditingController controladorGlicemia = TextEditingController();
  final TextEditingController controladorObservacao = TextEditingController();
  final TextEditingController controladorBuscaObservacao = TextEditingController();
  Timer? temporizadorAtualizacaoPrazo;

  DateTime dataHoraSelecionada = DateTime.now();
  final List<RegistroGlicemico> registros = [];
  final armazenamento = ArmazenamentoGlicemia();
  int horaSelecionada = DateTime.now().hour;
  int minutoSelecionado = DateTime.now().minute;

  String filtroSelecionado = 'Todos';
  String ordenacaoSelecionada = 'Mais recentes';

  List<RegistroGlicemico> obterRegistrosFiltrados() {
    final agora = DateTime.now();

    if (filtroSelecionado == 'Todos') {
      return registros;
    }

    if (filtroSelecionado == 'Hoje') {
      return registros.where((registro) {
        return registro.dataHora.year == agora.year &&
            registro.dataHora.month == agora.month &&
            registro.dataHora.day == agora.day;
      }).toList();
    }

    if (filtroSelecionado == '7 dias') {
      final dataLimite = agora.subtract(const Duration(days: 7));

      return registros.where((registro) {
        return !registro.dataHora.isBefore(dataLimite) &&
            !registro.dataHora.isAfter(agora);
      }).toList();
    }

    if (filtroSelecionado == '30 dias') {
      final dataLimite = agora.subtract(const Duration(days: 30));

      return registros.where((registro) {
        return !registro.dataHora.isBefore(dataLimite) &&
            !registro.dataHora.isAfter(agora);
      }).toList();
    }

    return registros;
  }

  List<RegistroGlicemico> obterRegistrosFiltradosEOrdenados() {
    final registrosFiltrados = obterRegistrosFiltrados();

    final textoBusca = controladorBuscaObservacao.text.trim().toLowerCase();

    final registrosComBusca = registrosFiltrados.where((registro) {
      if (textoBusca.isEmpty) return true;

      return registro.observacao.toLowerCase().contains(textoBusca);
    }).toList();

    final registrosOrdenados = [...registrosComBusca];

    if (ordenacaoSelecionada == 'Mais recentes') {
      registrosOrdenados.sort((registro1, registro2) {
        return registro2.dataHora.compareTo(registro1.dataHora);
      });
    } else if (ordenacaoSelecionada == 'Mais antigos') {
      registrosOrdenados.sort((registro1, registro2) {
        return registro1.dataHora.compareTo(registro2.dataHora);
      });
    } else if (ordenacaoSelecionada == 'Maior glicemia') {
      registrosOrdenados.sort((registro1, registro2) {
        return registro2.glicemia.compareTo(registro1.glicemia);
      });
    } else if (ordenacaoSelecionada == 'Menor glicemia') {
      registrosOrdenados.sort((registro1, registro2) {
        return registro1.glicemia.compareTo(registro2.glicemia);
      });
    }

    return registrosOrdenados;
  }

  String obterClassificacaoRegistro(int valorGlicemia) {
      if (valorGlicemia < 70) {
        return 'Baixo';
      } else if (valorGlicemia <= 140) {
        return 'Normal';
      } else if (valorGlicemia <= 180) {
        return 'Atenção';
      } else {
        return 'Alto';
      }
  }

  Color obterCorClassificacaoRegistro(String classificacao) {
    switch (classificacao) {
      case 'Baixo':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Atenção':
        return Colors.orange;
      case 'Alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget construirSeloClassificacao(String classificacao, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        classificacao,
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget construirGraficoRegistros() {
    final registrosFiltrados = obterRegistrosFiltrados();

    if (registrosFiltrados.isEmpty || registrosFiltrados.length < 2) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'São necessários pelo menos 2 registros para exibir o gráfico.',
        ),
      );
    }

    final registrosOrdenados = [...registrosFiltrados];
    registrosOrdenados.sort((registro1, registro2) {
      return registro1.dataHora.compareTo(registro2.dataHora);
    });

    final pontos = <FlSpot>[];

    for (int indice = 0; indice < registrosOrdenados.length; indice++) {
      pontos.add(
        FlSpot(
          indice.toDouble(),
          registrosOrdenados[indice].glicemia.toDouble(),
        ),
      );
    }

    double menorValor = registrosOrdenados.first.glicemia.toDouble();
    double maiorValor = registrosOrdenados.first.glicemia.toDouble();

    for (final registro in registrosOrdenados) {
      final valor = registro.glicemia.toDouble();

      if (valor < menorValor) {
        menorValor = valor;
      }

      if (valor > maiorValor) {
        maiorValor = valor;
      }
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: menorValor - 10,
          maxY: maiorValor + 10,
          gridData: const FlGridData(show: true),
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
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final indice = value.toInt();

                  if (indice < 0 || indice >= registrosOrdenados.length) {
                    return const SizedBox.shrink();
                  }

                  final data = registrosOrdenados[indice].dataHora;
                  final dia = data.day.toString().padLeft(2, '0');
                  final mes = data.month.toString().padLeft(2, '0');

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('$dia/$mes'),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: pontos,
              isCurved: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    carregarRegistros();

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
    controladorGlicemia.dispose();
    controladorObservacao.dispose();
    controladorBuscaObservacao.dispose();
    super.dispose();
  }

  Future<void> carregarRegistros() async {
    final dados = await armazenamento.carregar();

    if (!mounted) return;

    setState(() {
      registros.clear();
      registros.addAll(dados);
    });
  }

  Future<void> selecionarDataHora() async {
    final agora = DateTime.now();

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataHoraSelecionada.isAfter(agora) ? agora : dataHoraSelecionada,
      firstDate: DateTime(2020),
      lastDate: agora,
    );

    if (dataSelecionada == null) return;
    if (!mounted) return;

    final novaDataHora = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
      horaSelecionada,
      minutoSelecionado,
    );

    if (novaDataHora.isAfter(agora)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é permitido informar uma data e hora futura.'),
        ),
      );
      return;
    }

    setState(() {
      dataHoraSelecionada = novaDataHora;
    });
  }

  Future<void> salvarRegistro() async {
    final glicemiaTexto = controladorGlicemia.text.trim();
    final observacao = controladorObservacao.text.trim();

    if (glicemiaTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o valor da glicemia.'),
        ),
      );
      return;
    }

    final glicemia = int.tryParse(glicemiaTexto);

    if (glicemia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um valor numérico válido.'),
        ),
      );
      return;
    }

    if (dataHoraSelecionada.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data e hora não podem estar em datas futuras.'),
        ),
      );
      return;
    }

  final dataHoraFinal = DateTime(
    dataHoraSelecionada.year,
    dataHoraSelecionada.month,
    dataHoraSelecionada.day,
    horaSelecionada,
    minutoSelecionado,
  );

  if (dataHoraFinal.isAfter(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A data e hora não podem estar em datas futuras.'),
      ),
    );
    return;
  }

    final novoRegistro = RegistroGlicemico(
      glicemia: glicemia,
      dataHora: dataHoraFinal,
      observacao: observacao,
      dataCriacao: DateTime.now(),
    );

    setState(() {
      registros.insert(0, novoRegistro);
      controladorGlicemia.clear();
      controladorObservacao.clear();
      dataHoraSelecionada = DateTime.now();
      horaSelecionada = DateTime.now().hour;
      minutoSelecionado = DateTime.now().minute;
    });

    await armazenamento.salvar(registros);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro salvo com sucesso.'),
      ),
    );
  }

  Future<void> excluirRegistro(int indice) async {
    setState(() {
      registros.removeAt(indice);
    });

    await armazenamento.salvar(registros);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro excluído com sucesso.'),
      ),
    );
  }

  Future<void> confirmarExclusaoRegistro(int indice) async {
    final registro = registros[indice];

    if (!podeEditarOuExcluirRegistro(registro)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir registro'),
          content: const Text(
            'Tem certeza que deseja excluir este registro?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await excluirRegistro(indice);
  }

  Future<void> editarRegistro(int indice) async {
    final registroAtual = registros[indice];

    if (!podeEditarOuExcluirRegistro(registroAtual)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final registroAtualizado =
        await Navigator.of(context).push<RegistroGlicemico>(
      MaterialPageRoute(
        builder: (_) => PaginaEdicaoGlicemia(registro: registroAtual),
      ),
    );

    if (registroAtualizado == null) return;

    setState(() {
      registros[indice] = registroAtualizado;
    });

    await armazenamento.salvar(registros);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro atualizado com sucesso.'),
      ),
    );
  }

  String formatarDataHora(DateTime dataHora) {
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = dataHora.month.toString().padLeft(2, '0');
    final ano = dataHora.year.toString();
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  bool podeEditarOuExcluirRegistro(RegistroGlicemico registro) {
    final diferenca = DateTime.now().difference(registro.dataCriacao);
    return diferenca.inHours < 24;
  }

  void mostrarAvisoPrazoExpirado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Este registro só pode ser editado ou excluído em até 24 horas após o cadastro.',
        ),
      ),
    );
  }

  List<int> obterHorasDisponiveis() {
    return List.generate(24, (indice) => indice);
  }

  List<int> obterMinutosDisponiveis() {
    return List.generate(60, (indice) => indice);
  }

  Widget construirListaRegistros() {
    final registrosFiltrados = obterRegistrosFiltradosEOrdenados();

    if (registrosFiltrados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text('Nenhum registro encontrado para o filtro selecionado.'),
      );
    }

    return ListView.builder(
      itemCount: registrosFiltrados.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, indice) {
        final registro = registrosFiltrados[indice];
        final indiceOriginal = registros.indexOf(registro);

        final classificacao = obterClassificacaoRegistro(registro.glicemia);
        final corClassificacao = obterCorClassificacaoRegistro(classificacao);
        final podeAlterar = podeEditarOuExcluirRegistro(registro);

        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${registro.glicemia} mg/dL',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    construirSeloClassificacao(
                      classificacao,
                      corClassificacao,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(formatarDataHora(registro.dataHora)),
                if (registro.observacao.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Observação: ${registro.observacao}'),
                ],
                if (podeAlterar) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => editarRegistro(indiceOriginal),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => confirmarExclusaoRegistro(indiceOriginal),
                        icon: const Icon(Icons.delete),
                        tooltip: 'Excluir',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Glicemia'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Registrar'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informe seu índice glicêmico',
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registre sua glicemia para manter seu acompanhamento em dia.',
                      style: tema.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controladorGlicemia,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Glicemia (mg/dL)',
                        hintText: 'Ex.: 110',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: selecionarDataHora,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data da medição',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '${dataHoraSelecionada.day.toString().padLeft(2, '0')}/'
                          '${dataHoraSelecionada.month.toString().padLeft(2, '0')}/'
                          '${dataHoraSelecionada.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: horaSelecionada,
                            decoration: InputDecoration(
                              labelText: 'Hora',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: obterHorasDisponiveis().map((hora) {
                              return DropdownMenuItem(
                                value: hora,
                                child: Text(hora.toString().padLeft(2, '0')),
                              );
                            }).toList(),
                            onChanged: (valor) {
                              if (valor == null) return;

                              setState(() {
                                horaSelecionada = valor;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: minutoSelecionado,
                            decoration: InputDecoration(
                              labelText: 'Minuto',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: obterMinutosDisponiveis().map((minuto) {
                              return DropdownMenuItem(
                                value: minuto,
                                child: Text(minuto.toString().padLeft(2, '0')),
                              );
                            }).toList(),
                            onChanged: (valor) {
                              if (valor == null) return;

                              setState(() {
                                minutoSelecionado = valor;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controladorObservacao,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observação',
                        hintText: 'Ex.: medição após café da manhã',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: salvarRegistro,
                      child: const Text('Salvar registro'),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Histórico de registros',
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consulte, edite ou exclua medições já registradas.',
                      style: tema.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: filtroSelecionado,
                            decoration: InputDecoration(
                              labelText: 'Filtrar por período',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Hoje',
                                child: Text('Hoje'),
                              ),
                              DropdownMenuItem(
                                value: '7 dias',
                                child: Text('Últimos 7 dias'),
                              ),
                              DropdownMenuItem(
                                value: '30 dias',
                                child: Text('Últimos 30 dias'),
                              ),
                              DropdownMenuItem(
                                value: 'Todos',
                                child: Text('Todos'),
                              ),
                            ],
                            onChanged: (valor) {
                              if (valor == null) return;

                              setState(() {
                                filtroSelecionado = valor;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ordenacaoSelecionada,
                            decoration: InputDecoration(
                              labelText: 'Ordenar por',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                ordenacaoSelecionada = valor;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controladorBuscaObservacao,
                      decoration: InputDecoration(
                        labelText: 'Buscar na observação',
                        hintText: 'Ex.: café, almoço, jejum',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controladorBuscaObservacao.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    controladorBuscaObservacao.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                tooltip: 'Limpar busca',
                              )
                            : null,
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Evolução glicêmica',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    construirGraficoRegistros(),
                    const SizedBox(height: 24),
                    Text(
                      'Lista de registros',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    construirListaRegistros(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}