import 'package:flutter/material.dart';
import '../../../dados/modelos/medicamentos.dart';

class PaginaEdicaoMedicamento extends StatefulWidget {
  final Medicamento medicamento;

  const PaginaEdicaoMedicamento({
    super.key,
    required this.medicamento,
  });

  @override
  State<PaginaEdicaoMedicamento> createState() =>
      _PaginaEdicaoMedicamentoState();
}

class _PaginaEdicaoMedicamentoState extends State<PaginaEdicaoMedicamento> {
  final Color azulPrincipal = const Color(0xFF1565C0);

  late TextEditingController controladorNome;
  late TextEditingController controladorObservacao;

  late String tipoSelecionado;
  late String refeicaoSelecionada;
  late String momentoSelecionado;

  @override
  void initState() {
    super.initState();

    controladorNome = TextEditingController(
      text: widget.medicamento.nome,
    );

    controladorObservacao = TextEditingController(
      text: widget.medicamento.observacao,
    );

    tipoSelecionado = widget.medicamento.tipo;
    refeicaoSelecionada = widget.medicamento.refeicao;
    momentoSelecionado = widget.medicamento.momento;
  }

  @override
  void dispose() {
    controladorNome.dispose();
    controladorObservacao.dispose();
    super.dispose();
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

  void salvarEdicao() {
    final nome = controladorNome.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do medicamento.'),
        ),
      );
      return;
    }

    final medicamentoAtualizado = widget.medicamento.copiarCom(
      nome: nome,
      tipo: tipoSelecionado,
      refeicao: refeicaoSelecionada,
      momento: momentoSelecionado,
      observacao: controladorObservacao.text.trim(),
    );

    Navigator.of(context).pop(medicamentoAtualizado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        backgroundColor: azulPrincipal,
        centerTitle: true,
        title: const Text(
          'Editar medicamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    initialValue: tipoSelecionado,
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
                    initialValue: refeicaoSelecionada,
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
                    initialValue: momentoSelecionado,
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
                    onPressed: salvarEdicao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulPrincipal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Salvar alterações',
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
        ),
      ),
    );
  }
}