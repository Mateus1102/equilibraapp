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
  final ArmazenamentoAnotacoes armazenamento = ArmazenamentoAnotacoes();
  Timer? temporizadorAtualizacaoPrazo;

  List<AnotacaoDiaria> anotacoes = [];
  String filtroSelecionado = 'Todos';
  final TextEditingController controladorBusca = TextEditingController();

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
    final anotacaoAtual = anotacoes[indice];

    if (!podeEditarOuExcluirAnotacao(anotacaoAtual)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final controladorEdicao = TextEditingController(
      text: anotacaoAtual.texto,
    );

    final textoAtualizado = await showDialog<String>(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(controladorEdicao.text.trim());
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controladorEdicao.dispose();

    if (textoAtualizado == null || textoAtualizado.isEmpty) return;

    setState(() {
      anotacoes[indice] = anotacaoAtual.copiarCom(
        texto: textoAtualizado,
      );
    });

    await armazenamento.salvar(anotacoes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anotação atualizada com sucesso.'),
      ),
    );
  }

  Future<void> excluirAnotacao(int indice) async {
    final anotacao = anotacoes[indice];

    if (!podeEditarOuExcluirAnotacao(anotacao)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir anotação'),
          content: const Text('Tem certeza que deseja excluir esta anotação?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
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

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anotação excluída com sucesso.'),
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

  List<AnotacaoDiaria> obterAnotacoesFiltradas() {
    final agora = DateTime.now();

    if (filtroSelecionado == 'Todos') {
      return anotacoes;
    }

    if (filtroSelecionado == 'Hoje') {
      return anotacoes.where((anotacao) {
        return anotacao.dataHora.year == agora.year &&
            anotacao.dataHora.month == agora.month &&
            anotacao.dataHora.day == agora.day;
      }).toList();
    }

    if (filtroSelecionado == '7 dias') {
      final dataLimite = agora.subtract(const Duration(days: 7));

      return anotacoes.where((anotacao) {
        return !anotacao.dataHora.isBefore(dataLimite) &&
            !anotacao.dataHora.isAfter(agora);
      }).toList();
    }

    if (filtroSelecionado == '30 dias') {
      final dataLimite = agora.subtract(const Duration(days: 30));

      return anotacoes.where((anotacao) {
        return !anotacao.dataHora.isBefore(dataLimite) &&
            !anotacao.dataHora.isAfter(agora);
      }).toList();
    }

    return anotacoes;
  }

  List<AnotacaoDiaria> obterAnotacoesFiltradasComBusca() {
    final anotacoesFiltradas = obterAnotacoesFiltradas();
    final textoBusca = controladorBusca.text.trim().toLowerCase();

    return anotacoesFiltradas.where((anotacao) {
      if (textoBusca.isEmpty) return true;

      return anotacao.texto.toLowerCase().contains(textoBusca);
    }).toList();
  }

  Widget construirListaAnotacoes() {
    final anotacoesFiltradas = obterAnotacoesFiltradasComBusca();

    if (anotacoesFiltradas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text('Nenhuma anotação encontrada para os filtros selecionados.'),
      );
    }

    return ListView.builder(
      itemCount: anotacoesFiltradas.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, indice) {
        final anotacao = anotacoesFiltradas[indice];
        final indiceOriginal = anotacoes.indexOf(anotacao);
        final podeAlterar = podeEditarOuExcluirAnotacao(anotacao);

        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatarDataHora(anotacao.dataHora),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(anotacao.texto),
                if (podeAlterar) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => editarAnotacao(indiceOriginal),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => excluirAnotacao(indiceOriginal),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anotações'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrar anotação diária',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use este espaço para sintomas, alimentação, atividades ou observações importantes.',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controladorTexto,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Anotação',
                  hintText: 'Ex.: Hoje senti tontura após o almoço.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarAnotacao,
                child: const Text('Salvar anotação'),
              ),
              const SizedBox(height: 24),
              Text(
                'Histórico de anotações',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use os filtros para localizar anotações com mais facilidade.',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controladorBusca,
                decoration: InputDecoration(
                  labelText: 'Buscar por palavra',
                  hintText: 'Ex.: tontura, almoço, caminhada',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controladorBusca.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              controladorBusca.clear();
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 12),
              construirListaAnotacoes(),
            ],
          ),
        ),
      ),
    );
  }
}