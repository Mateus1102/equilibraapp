import 'dart:convert';
import 'dart:io';

import '../modelos/anotacao_diaria.dart';
import 'armazenamento_usuario_atual.dart';

class ArmazenamentoAnotacoes {
  final ArmazenamentoUsuarioAtual armazenamentoUsuarioAtual =
      ArmazenamentoUsuarioAtual();

  Future<File> _obterArquivo() async {
    return armazenamentoUsuarioAtual.obterArquivoUsuarioAtual(
      'anotacoes.json',
    );
  }

  Future<void> salvar(List<AnotacaoDiaria> anotacoes) async {
    final arquivo = await _obterArquivo();

    final listaMapas =
        anotacoes.map((anotacao) => anotacao.paraMapa()).toList();

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

      if (jsonString.trim().isEmpty) {
        return [];
      }

      final lista = jsonDecode(jsonString) as List;

      return lista
          .map((item) => AnotacaoDiaria.deMapa(item))
          .toList();
    } catch (e) {
      return [];
    }
  }
}