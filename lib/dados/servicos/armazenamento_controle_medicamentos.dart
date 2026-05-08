import 'dart:convert';
import 'dart:io';

import '../modelos/controle_medicamento_diario.dart';
import 'armazenamento_usuario_atual.dart';

class ArmazenamentoControleMedicamentos {
  final ArmazenamentoUsuarioAtual armazenamentoUsuarioAtual =
      ArmazenamentoUsuarioAtual();

  Future<File> _obterArquivo() async {
    return armazenamentoUsuarioAtual.obterArquivoUsuarioAtual(
      'controle_medicamentos.json',
    );
  }

  Future<void> salvar(
    List<ControleMedicamentoDiario> controles,
  ) async {
    final arquivo = await _obterArquivo();

    final listaMapas = controles.map((controle) {
      return controle.paraMapa();
    }).toList();

    await arquivo.writeAsString(
      jsonEncode(listaMapas),
    );
  }

  Future<List<ControleMedicamentoDiario>> carregar() async {
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

      return lista.map((item) {
        return ControleMedicamentoDiario.deMapa(item);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}