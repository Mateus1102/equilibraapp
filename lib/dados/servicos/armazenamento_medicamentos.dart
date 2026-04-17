import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../modelos/medicamentos.dart';

class ArmazenamentoMedicamentos {
  Future<File> _obterArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/medicamentos.json');
  }

  Future<void> salvar(List<Medicamento> medicamentos) async {
    final arquivo = await _obterArquivo();

    final listaMapas =
        medicamentos.map((medicamento) => medicamento.paraMapa()).toList();

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
      final lista = jsonDecode(jsonString) as List;

      return lista.map((item) => Medicamento.deMapa(item)).toList();
    } catch (e) {
      return [];
    }
  }
}