import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../modelos/registro_glicemico.dart';

class ArmazenamentoGlicemia {
  Future<File> _obterArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/glicemias.json');
  }

  Future<void> salvar(List<RegistroGlicemico> registros) async {
    final arquivo = await _obterArquivo();

    final listaMapas = registros.map((e) => e.paraMapa()).toList();
    final jsonString = jsonEncode(listaMapas);

    await arquivo.writeAsString(jsonString);
  }

  Future<List<RegistroGlicemico>> carregar() async {
    try {
      final arquivo = await _obterArquivo();

      if (!await arquivo.exists()) {
        return [];
      }

      final jsonString = await arquivo.readAsString();
      final lista = jsonDecode(jsonString) as List;

      return lista
          .map((e) => RegistroGlicemico.deMapa(e))
          .toList();
    } catch (e) {
      return [];
    }
  }
}