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
  late TextEditingController controladorHora;
  late TextEditingController controladorMinuto;
  late DateTime dataHoraSelecionada;
  final FocusNode focoHora = FocusNode();
  final FocusNode focoMinuto = FocusNode();

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

    controladorHora = TextEditingController(
      text: widget.registro.dataHora.hour
          .toString()
          .padLeft(2, '0'),
    );

    controladorMinuto = TextEditingController(
      text: widget.registro.dataHora.minute
          .toString()
          .padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    controladorGlicemia.dispose();
    controladorObservacao.dispose();
    controladorHora.dispose();
    controladorMinuto.dispose();
    focoHora.dispose();
    focoMinuto.dispose();
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

    final hora = int.tryParse(controladorHora.text) ?? 0;
    final minuto = int.tryParse(controladorMinuto.text) ?? 0;

    final novaDataHora = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
      hora,
      minuto,
    );

    if (novaDataHora.isAfter(agora)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não é permitido informar uma data e hora futura.',
          ),
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

    final hora = int.tryParse(controladorHora.text) ?? -1;
    final minuto = int.tryParse(controladorMinuto.text) ?? -1;

    if (hora < 0 || hora > 23) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma hora válida entre 0 e 23.'),
        ),
      );
      return;
    }

    if (minuto < 0 || minuto > 59) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um minuto válido entre 0 e 59.'),
        ),
      );
      return;
    }

    final dataHoraFinal = DateTime(
      dataHoraSelecionada.year,
      dataHoraSelecionada.month,
      dataHoraSelecionada.day,
      hora,
      minuto,
    );

    if (dataHoraFinal.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não é permitido informar uma data e hora futura.',
          ),
        ),
      );
      return;
    }

    final registroAtualizado = widget.registro.copiarCom(
      glicemia: glicemia,
      dataHora: dataHoraFinal,
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
                    child: TextField(
                      controller: controladorHora,
                      focusNode: focoHora,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      onChanged: (valor) {
                        if (valor.length == 2) {
                            FocusScope.of(context).requestFocus(focoMinuto);
                          }
                        },
                      decoration: const InputDecoration(
                        labelText: 'Hora',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controladorMinuto,
                      focusNode: focoMinuto,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      onChanged: (valor) {
                        if (valor.length == 2) {
                          FocusScope.of(context).unfocus();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Minuto',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
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
