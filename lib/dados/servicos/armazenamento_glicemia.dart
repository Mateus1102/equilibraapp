import 'dart:convert';
import 'dart:io';

import '../modelos/registro_glicemico.dart';
import 'armazenamento_usuario_atual.dart';

class ArmazenamentoGlicemia {
  final ArmazenamentoUsuarioAtual armazenamentoUsuarioAtual =
      ArmazenamentoUsuarioAtual();

  Future<File> _obterArquivo() async {
    return armazenamentoUsuarioAtual.obterArquivoUsuarioAtual(
      'glicemias.json',
    );
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

      if (jsonString.trim().isEmpty) {
        return [];
      }

      final lista = jsonDecode(jsonString) as List;

      return lista.map((e) => RegistroGlicemico.deMapa(e)).toList();
    } catch (e) {
      return [];
    }
  }
}