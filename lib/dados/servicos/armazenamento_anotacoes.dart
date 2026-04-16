import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../modelos/anotacao_diaria.dart';

class ArmazenamentoAnotacoes {
  Future<File> _obterArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/anotacoes.json');
  }

  Future<void> salvar(List<AnotacaoDiaria> anotacoes) async {
    final arquivo = await _obterArquivo();

    final listaMapas = anotacoes.map((anotacao) => anotacao.paraMapa()).toList();
    final jsonString = jsonEncode(listaMapas);

    await arquivo.writeAsString(jsonString);
  }

  Future<List<AnotacaoDiaria>> carregar() async {
    try {
      final arquivo = await _obterArquivo();

      if (!await arquivo.exists()) {
        return [];
      }

      final jsonString = await arquivo.readAsString();
      final lista = jsonDecode(jsonString) as List;

      return lista.map((item) => AnotacaoDiaria.deMapa(item)).toList();
    } catch (e) {
      return [];
    }
  }
}