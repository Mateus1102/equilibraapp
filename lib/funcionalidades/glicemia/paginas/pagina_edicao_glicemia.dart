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
  late int horaSelecionada;
  late int minutoSelecionado;

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
    horaSelecionada = widget.registro.dataHora.hour;
    minutoSelecionado = widget.registro.dataHora.minute;
  }

  @override
  void dispose() {
    controladorGlicemia.dispose();
    controladorObservacao.dispose();
    super.dispose();
  }

  Future<void> selecionarDataHora() async {
    final agora = DateTime.now();

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataHoraSelecionada.isAfter(agora)
          ? agora
          : dataHoraSelecionada,
      firstDate: DateTime(2020),
      lastDate: agora,
    );

    if (dataSelecionada == null) return;

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
      dataHoraSelecionada = dataSelecionada;
    });
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

    final dataHoraFinal = DateTime(
      dataHoraSelecionada.year,
      dataHoraSelecionada.month,
      dataHoraSelecionada.day,
      horaSelecionada,
      minutoSelecionado,
    );

    if (dataHoraFinal.isAfter(DateTime.now())) {
      final registroAtualizado = widget.registro.copiarCom(
        glicemia: glicemia,
        dataHora: dataHoraFinal,
        observacao: observacao,
      );

      Navigator.of(context).pop(registroAtualizado);
    }
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
                    labelText: 'Data da medição',
                    border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Hora',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(24, (i) => i).map((hora) {
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
                      decoration: const InputDecoration(
                        labelText: 'Minuto',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(60, (i) => i).map((minuto) {
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