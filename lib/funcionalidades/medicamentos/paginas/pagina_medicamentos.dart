import 'dart:async';
import 'package:flutter/material.dart';
import '../../../dados/modelos/medicamentos.dart';
import '../../../dados/servicos/armazenamento_medicamentos.dart';

class PaginaMedicamentos extends StatefulWidget {
  const PaginaMedicamentos({super.key});

  @override
  State<PaginaMedicamentos> createState() => _PaginaMedicamentosState();
}

class _PaginaMedicamentosState extends State<PaginaMedicamentos> {
  final TextEditingController controladorNome = TextEditingController();
  final TextEditingController controladorDosagem = TextEditingController();
  final TextEditingController controladorObservacao = TextEditingController();
  final TextEditingController controladorBusca = TextEditingController();

  final ArmazenamentoMedicamentos armazenamento =
      ArmazenamentoMedicamentos();

  Timer? temporizadorAtualizacaoPrazo;

  List<Medicamento> medicamentos = [];
  String filtroSelecionado = 'Todos';

  @override
  void initState() {
    super.initState();
    carregarMedicamentos();

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
    controladorDosagem.dispose();
    controladorObservacao.dispose();
    controladorBusca.dispose();
    super.dispose();
  }

  Future<void> carregarMedicamentos() async {
    final dados = await armazenamento.carregar();

    if (!mounted) return;

    setState(() {
      medicamentos = dados;
    });
  }

  Future<void> salvarMedicamento() async {
    final nome = controladorNome.text.trim();
    final dosagem = controladorDosagem.text.trim();
    final observacao = controladorObservacao.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do medicamento.'),
        ),
      );
      return;
    }

    if (dosagem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a dosagem do medicamento.'),
        ),
      );
      return;
    }

    final agora = DateTime.now();

    final novoMedicamento = Medicamento(
      nome: nome,
      dosagem: dosagem,
      observacao: observacao,
      dataHora: agora,
      dataCriacao: agora,
    );

    setState(() {
      medicamentos.insert(0, novoMedicamento);
      controladorNome.clear();
      controladorDosagem.clear();
      controladorObservacao.clear();
    });

    await armazenamento.salvar(medicamentos);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicamento salvo com sucesso.'),
      ),
    );
  }

  bool podeEditarOuExcluirMedicamento(Medicamento medicamento) {
    final diferenca = DateTime.now().difference(medicamento.dataCriacao);
    return diferenca.inHours < 24;
  }

  void mostrarAvisoPrazoExpirado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Este medicamento só pode ser editado ou excluído em até 24 horas após o cadastro.',
        ),
      ),
    );
  }

  Future<void> editarMedicamento(int indice) async {
    final medicamentoAtual = medicamentos[indice];

    if (!podeEditarOuExcluirMedicamento(medicamentoAtual)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final controladorNomeEdicao = TextEditingController(
      text: medicamentoAtual.nome,
    );
    final controladorDosagemEdicao = TextEditingController(
      text: medicamentoAtual.dosagem,
    );
    final controladorObservacaoEdicao = TextEditingController(
      text: medicamentoAtual.observacao,
    );

    final medicamentoAtualizado = await showDialog<Medicamento>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar medicamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controladorNomeEdicao,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controladorDosagemEdicao,
                  decoration: const InputDecoration(
                    labelText: 'Dosagem',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controladorObservacaoEdicao,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = controladorNomeEdicao.text.trim();
                final dosagem = controladorDosagemEdicao.text.trim();
                final observacao = controladorObservacaoEdicao.text.trim();

                if (nome.isEmpty || dosagem.isEmpty) return;

                Navigator.of(context).pop(
                  medicamentoAtual.copiarCom(
                    nome: nome,
                    dosagem: dosagem,
                    observacao: observacao,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controladorNomeEdicao.dispose();
    controladorDosagemEdicao.dispose();
    controladorObservacaoEdicao.dispose();

    if (medicamentoAtualizado == null) return;

    setState(() {
      medicamentos[indice] = medicamentoAtualizado;
    });

    await armazenamento.salvar(medicamentos);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicamento atualizado com sucesso.'),
      ),
    );
  }

  Future<void> excluirMedicamento(int indice) async {
    final medicamento = medicamentos[indice];

    if (!podeEditarOuExcluirMedicamento(medicamento)) {
      mostrarAvisoPrazoExpirado();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir medicamento'),
          content: const Text(
            'Tem certeza que deseja excluir este medicamento?',
          ),
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
      medicamentos.removeAt(indice);
    });

    await armazenamento.salvar(medicamentos);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicamento excluído com sucesso.'),
      ),
    );
  }

  List<Medicamento> obterMedicamentosFiltrados() {
    final agora = DateTime.now();

    if (filtroSelecionado == 'Todos') {
      return medicamentos;
    }

    if (filtroSelecionado == 'Hoje') {
      return medicamentos.where((medicamento) {
        return medicamento.dataHora.year == agora.year &&
            medicamento.dataHora.month == agora.month &&
            medicamento.dataHora.day == agora.day;
      }).toList();
    }

    if (filtroSelecionado == '7 dias') {
      final dataLimite = agora.subtract(const Duration(days: 7));

      return medicamentos.where((medicamento) {
        return !medicamento.dataHora.isBefore(dataLimite) &&
            !medicamento.dataHora.isAfter(agora);
      }).toList();
    }

    if (filtroSelecionado == '30 dias') {
      final dataLimite = agora.subtract(const Duration(days: 30));

      return medicamentos.where((medicamento) {
        return !medicamento.dataHora.isBefore(dataLimite) &&
            !medicamento.dataHora.isAfter(agora);
      }).toList();
    }

    return medicamentos;
  }

  List<Medicamento> obterMedicamentosFiltradosComBusca() {
    final medicamentosFiltrados = obterMedicamentosFiltrados();
    final textoBusca = controladorBusca.text.trim().toLowerCase();

    return medicamentosFiltrados.where((medicamento) {
      if (textoBusca.isEmpty) return true;

      return medicamento.nome.toLowerCase().contains(textoBusca) ||
          medicamento.observacao.toLowerCase().contains(textoBusca);
    }).toList();
  }

  String formatarDataHora(DateTime dataHora) {
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = dataHora.month.toString().padLeft(2, '0');
    final ano = dataHora.year.toString();
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  Widget construirListaMedicamentos() {
    final medicamentosFiltrados = obterMedicamentosFiltradosComBusca();

    if (medicamentosFiltrados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text('Nenhum medicamento encontrado para os filtros selecionados.'),
      );
    }

    return ListView.builder(
      itemCount: medicamentosFiltrados.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, indice) {
        final medicamento = medicamentosFiltrados[indice];
        final indiceOriginal = medicamentos.indexOf(medicamento);
        final podeAlterar = podeEditarOuExcluirMedicamento(medicamento);

        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicamento.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Dosagem: ${medicamento.dosagem}'),
                const SizedBox(height: 4),
                Text(formatarDataHora(medicamento.dataHora)),
                if (medicamento.observacao.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Observação: ${medicamento.observacao}'),
                ],
                if (podeAlterar) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => editarMedicamento(indiceOriginal),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => excluirMedicamento(indiceOriginal),
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
        title: const Text('Medicamentos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cadastrar medicamento',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registre seus medicamentos para manter seu acompanhamento organizado.',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controladorNome,
                decoration: InputDecoration(
                  labelText: 'Nome do medicamento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controladorDosagem,
                decoration: InputDecoration(
                  labelText: 'Dosagem',
                  hintText: 'Ex.: 500 mg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controladorObservacao,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observação',
                  hintText: 'Ex.: tomar após o almoço',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarMedicamento,
                child: const Text('Salvar medicamento'),
              ),
              const SizedBox(height: 24),
              Text(
                'Histórico de medicamentos',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controladorBusca,
                decoration: InputDecoration(
                  labelText: 'Buscar por nome ou observação',
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
              construirListaMedicamentos(),
            ],
          ),
        ),
      ),
    );
  }
}