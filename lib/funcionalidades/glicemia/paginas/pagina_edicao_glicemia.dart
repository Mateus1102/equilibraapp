import 'package:flutter/material.dart';
import '../../../dados/modelos/registro_glicemico.dart';

class PaginaEdicaoGlicemia extends StatefulWidget {
  final RegistroGlicemico registro;

  const PaginaEdicaoGlicemia({
    super.key,
    required this.registro,
  });

  @override
  State<PaginaEdicaoGlicemia> createState() => _PaginaEdicaoGlicemiaState();
}

class _PaginaEdicaoGlicemiaState extends State<PaginaEdicaoGlicemia> {
  late TextEditingController controladorGlicemia;
  late TextEditingController controladorObservacao;
  late DateTime dataHoraSelecionada;

  @override
  void initState() {
    super.initState();
    controladorGlicemia = TextEditingController(
      text: widget.registro.glicemia.toString(),
    );
    controladorObservacao = TextEditingController(
      text: widget.registro.observacao,
    );
    dataHoraSelecionada = widget.registro.dataHora;
  }

  @override
  void dispose() {
    controladorGlicemia.dispose();
    controladorObservacao.dispose();
    super.dispose();
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

  String formatarDataHora(DateTime dataHora) {
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = dataHora.month.toString().padLeft(2, '0');
    final ano = dataHora.year.toString();
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  void salvarEdicao() {
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

    final registroAtualizado = widget.registro.copiarCom(
      glicemia: glicemia,
      dataHora: dataHoraSelecionada,
      observacao: observacao,
    );

    Navigator.of(context).pop(registroAtualizado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar registro'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controladorGlicemia,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Glicemia (mg/dL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: selecionarDataHora,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data e hora',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatarDataHora(dataHoraSelecionada)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controladorObservacao,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarEdicao,
                child: const Text('Salvar alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}