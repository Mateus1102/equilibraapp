import 'dart:async';
import 'package:flutter/material.dart';

import '../../../dados/modelos/anotacao_diaria.dart';
import '../../../dados/servicos/armazenamento_anotacoes.dart';

class PaginaAnotacoes extends StatefulWidget {
  const PaginaAnotacoes({super.key});

  @override
  State<PaginaAnotacoes> createState() => _PaginaAnotacoesState();
}

class _PaginaAnotacoesState extends State<PaginaAnotacoes> {
  final TextEditingController controladorTexto = TextEditingController();
  final TextEditingController controladorBusca = TextEditingController();

  final ArmazenamentoAnotacoes armazenamento = ArmazenamentoAnotacoes();

  Timer? temporizadorAtualizacaoPrazo;

  List<AnotacaoDiaria> anotacoes = [];

  String filtroSelecionado = 'Hoje';

  final Color azulPrincipal = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();

    carregarAnotacoes();

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
    controladorTexto.dispose();
    controladorBusca.dispose();
    super.dispose();
  }

  Future<void> carregarAnotacoes() async {
    final dados = await armazenamento.carregar();

    if (!mounted) return;

    setState(() {
      anotacoes = dados;
    });
  }

  Future<void> salvarAnotacao() async {
    final texto = controladorTexto.text.trim();

    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma anotação antes de salvar.'),
        ),
      );
      return;
    }

    final agora = DateTime.now();

    final novaAnotacao = AnotacaoDiaria(
      texto: texto,
      dataHora: agora,
      dataCriacao: agora,
    );

    setState(() {
      anotacoes.insert(0, novaAnotacao);
      controladorTexto.clear();
    });

    await armazenamento.salvar(anotacoes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anotação salva com sucesso.'),
      ),
    );
  }

  Future<void> editarAnotacao(int indice) async {
    final atual = anotacoes[indice];

    if (!podeEditarOuExcluirAnotacao(atual)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final controladorEdicao = TextEditingController(
      text: atual.texto,
    );

    final texto = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar anotação'),
          content: TextField(
            controller: controladorEdicao,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Anotação',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controladorEdicao.text.trim(),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controladorEdicao.dispose();

    if (texto == null || texto.isEmpty) return;

    setState(() {
      anotacoes[indice] = atual.copiarCom(texto: texto);
    });

    await armazenamento.salvar(anotacoes);
  }

  Future<void> excluirAnotacao(int indice) async {
    final anotacao = anotacoes[indice];

    if (!podeEditarOuExcluirAnotacao(anotacao)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir anotação'),
          content: const Text(
            'Tem certeza que deseja excluir esta anotação?',
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
      anotacoes.removeAt(indice);
    });

    await armazenamento.salvar(anotacoes);
  }

  bool podeEditarOuExcluirAnotacao(AnotacaoDiaria anotacao) {
    final diferenca = DateTime.now().difference(anotacao.dataCriacao);
    return diferenca.inHours < 24;
  }

  void mostrarAvisoPrazoExpirado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Esta anotação só pode ser editada ou excluída em até 24 horas após o cadastro.',
        ),
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

  List<AnotacaoDiaria> obterAnotacoesFiltradas() {
    final agora = DateTime.now();

    if (filtroSelecionado == 'Hoje') {
      return anotacoes.where((item) {
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

    return anotacoes.where((item) {
      return !item.dataHora.isBefore(limite);
    }).toList();
  }

  List<AnotacaoDiaria> obterAnotacoesComBusca() {
    final lista = obterAnotacoesFiltradas();

    final busca = controladorBusca.text.trim().toLowerCase();

    return lista.where((item) {
      if (busca.isEmpty) return true;

      return item.texto.toLowerCase().contains(busca);
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

  Widget construirListaAnotacoes() {
    final lista = obterAnotacoesComBusca();

    if (lista.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text('Nenhuma anotação encontrada.'),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, indice) {
        final anotacao = lista[indice];
        final indiceOriginal = anotacoes.indexOf(anotacao);
        final podeAlterar = podeEditarOuExcluirAnotacao(anotacao);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: cardModerno(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatarDataHora(anotacao.dataHora),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: azulPrincipal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  anotacao.texto,
                  style: const TextStyle(fontSize: 15),
                ),
                if (podeAlterar) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => editarAnotacao(indiceOriginal),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: azulPrincipal,
                        ),
                      ),
                      IconButton(
                        onPressed: () => excluirAnotacao(indiceOriginal),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: azulPrincipal,
        title: const Text(
          'Anotações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              cardModerno(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Registrar anotação diária',
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: azulPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use este espaço para sintomas, alimentação, atividades ou observações importantes.',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: controladorTexto,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Anotação',
                        hintText:
                            'Ex.: Hoje senti tontura após o almoço.',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 90),
                          child: Icon(Icons.edit_note_outlined),
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: salvarAnotacao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulPrincipal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Salvar anotação',
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
              const SizedBox(height: 20),
              cardModerno(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Histórico',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: azulPrincipal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controladorBusca,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Buscar anotação',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: controladorBusca.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    controladorBusca.clear();
                                  });
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: filtroSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Período',
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
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
                          value: '15 dias',
                          child: Text('Últimos 15 dias'),
                        ),
                        DropdownMenuItem(
                          value: '30 dias',
                          child: Text('Últimos 30 dias'),
                        ),
                        DropdownMenuItem(
                          value: '60 dias',
                          child: Text('Últimos 60 dias'),
                        ),
                        DropdownMenuItem(
                          value: '90 dias',
                          child: Text('Últimos 90 dias'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;

                        setState(() {
                          filtroSelecionado = valor;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              construirListaAnotacoes(),
            ],
          ),
        ),
      ),
    );
  }
}