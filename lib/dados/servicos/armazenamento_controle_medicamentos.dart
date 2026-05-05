import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../modelos/controle_medicamento_diario.dart';

class ArmazenamentoControleMedicamentos {
  Future<File> _obterArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/controle_medicamentos.json');
  }

  Future<void> salvar(List<ControleMedicamentoDiario> controles) async {
    final arquivo = await _obterArquivo();

    final listaMapas = controles.map((controle) {
      return controle.paraMapa();
    }).toList();

    await arquivo.writeAsString(jsonEncode(listaMapas));
  }

  Future<List<ControleMedicamentoDiario>> carregar() async {
    try {
      final arquivo = await _obterArquivo();

      if (!await arquivo.exists()) {
        return [];
      }

      final jsonString = await arquivo.readAsString();
      final lista = jsonDecode(jsonString) as List;

      return lista.map((item) {
        return ControleMedicamentoDiario.deMapa(item);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}