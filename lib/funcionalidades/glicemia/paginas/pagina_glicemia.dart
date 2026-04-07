import 'package:flutter/material.dart';
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

  DateTime dataHoraSelecionada = DateTime.now();
  final List<RegistroGlicemico> registros = [];
  final armazenamento = ArmazenamentoGlicemia();

  @override
  void initState() {
    super.initState();
    carregarRegistros();
  }

  @override
  void dispose() {
    controladorGlicemia.dispose();
    controladorObservacao.dispose();
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
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataHoraSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (dataSelecionada == null) return;
    if (!mounted) return;

    final horaSelecionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dataHoraSelecionada),
    );

    if (horaSelecionada == null) return;

    setState(() {
      dataHoraSelecionada = DateTime(
        dataSelecionada.year,
        dataSelecionada.month,
        dataSelecionada.day,
        horaSelecionada.hour,
        horaSelecionada.minute,
      );
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

    final novoRegistro = RegistroGlicemico(
      glicemia: glicemia,
      dataHora: dataHoraSelecionada,
      observacao: observacao,
    );

    setState(() {
      registros.insert(0, novoRegistro);
      controladorGlicemia.clear();
      controladorObservacao.clear();
      dataHoraSelecionada = DateTime.now();
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

  Future<void> editarRegistro(int indice) async {
    final registroAtual = registros[indice];

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

  Widget construirListaRegistros() {
    if (registros.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text('Nenhum registro salvo até o momento.'),
      );
    }

    return ListView.builder(
      itemCount: registros.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, indice) {
        final registro = registros[indice];

        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: ListTile(
            title: Text('${registro.glicemia} mg/dL'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatarDataHora(registro.dataHora)),
                if (registro.observacao.isNotEmpty)
                  Text('Observação: ${registro.observacao}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => editarRegistro(indice),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () => excluirRegistro(indice),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Excluir',
                ),
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
        title: const Text('Registro de Glicemia'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                'Registre sua glicemia e acompanhe seu histórico.',
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
                    labelText: 'Data e hora',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(formatarDataHora(dataHoraSelecionada)),
                ),
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
              const SizedBox(height: 28),
              Text(
                'Histórico',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              construirListaRegistros(),
            ],
          ),
        ),
      ),
    );
  }
}