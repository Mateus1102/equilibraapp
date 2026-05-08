import 'dart:convert';
import 'dart:io';

import '../modelos/medicamentos.dart';
import 'armazenamento_usuario_atual.dart';

class ArmazenamentoMedicamentos {
  final ArmazenamentoUsuarioAtual armazenamentoUsuarioAtual =
      ArmazenamentoUsuarioAtual();

  Future<File> _obterArquivo() async {
    return armazenamentoUsuarioAtual.obterArquivoUsuarioAtual(
      'medicamentos.json',
    );
  }

  Future<void> salvar(List<Medicamento> medicamentos) async {
    final arquivo = await _obterArquivo();

    final listaMapas = medicamentos
        .map((medicamento) => medicamento.paraMapa())
        .toList();

    final jsonString = jsonEncode(listaMapas);

    await arquivo.writeAsString(jsonString);
  }

  Future<List<Medicamento>> carregar() async {
    try {
      final arquivo = await _obterArquivo();

      if (!await arquivo.exists()) {
        return [];
      }

      final jsonString = await arquivo.readAsString();

      if (jsonString.trim().isEmpty) {
        return [];
      }

      final lista = jsonDecode(jsonString) as List;

      return lista
          .map((item) => Medicamento.deMapa(item))
          .toList();
    } catch (e) {
      return [];
    }
  }
}