import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../modelos/usuario.dart';

class ArmazenamentoUsuario {
  Future<File> _obterArquivoUsuarios() async {
    final diretorio = await getApplicationDocumentsDirectory();

    return File('${diretorio.path}/usuarios.json');
  }

  Future<File> _obterArquivoSessao() async {
    final diretorio = await getApplicationDocumentsDirectory();

    return File('${diretorio.path}/sessao_usuario.json');
  }

  Future<List<Usuario>> carregarUsuarios() async {
    try {
      final arquivo = await _obterArquivoUsuarios();

      if (!await arquivo.exists()) {
        return [];
      }

      final jsonString = await arquivo.readAsString();

      if (jsonString.trim().isEmpty) {
        return [];
      }

      final lista = jsonDecode(jsonString) as List;

      return lista
          .map((item) => Usuario.deMapa(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> salvarUsuarios(List<Usuario> usuarios) async {
    final arquivo = await _obterArquivoUsuarios();

    final listaMapas = usuarios
        .map((usuario) => usuario.paraMapa())
        .toList();

    await arquivo.writeAsString(
      jsonEncode(listaMapas),
    );
  }

  Future<bool> cpfJaCadastrado(String cpf) async {
    final usuarios = await carregarUsuarios();

    return usuarios.any(
      (usuario) => usuario.cpf == cpf,
    );
  }

  Future<void> cadastrarUsuario(Usuario usuario) async {
    final usuarios = await carregarUsuarios();

    usuarios.add(usuario);

    await salvarUsuarios(usuarios);
  }

  Future<Usuario?> autenticar({
    required String cpf,
    required String pin,
  }) async {
    final usuarios = await carregarUsuarios();

    try {
      return usuarios.firstWhere(
        (usuario) =>
            usuario.cpf == cpf &&
            usuario.pin == pin,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> salvarSessao(String cpf) async {
    final arquivo = await _obterArquivoSessao();

    await arquivo.writeAsString(
      jsonEncode({
        'cpf': cpf,
      }),
    );
  }

  Future<String?> obterCpfSessao() async {
    try {
      final arquivo = await _obterArquivoSessao();

      if (!await arquivo.exists()) {
        return null;
      }

      final jsonString = await arquivo.readAsString();

      if (jsonString.trim().isEmpty) {
        return null;
      }

      final mapa = jsonDecode(jsonString);

      return mapa['cpf'];
    } catch (e) {
      return null;
    }
  }

  Future<Usuario?> obterUsuarioLogado() async {
    final cpfSessao = await obterCpfSessao();

    if (cpfSessao == null) {
      return null;
    }

    final usuarios = await carregarUsuarios();

    try {
      return usuarios.firstWhere(
        (usuario) => usuario.cpf == cpfSessao,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final arquivo = await _obterArquivoSessao();

    if (await arquivo.exists()) {
      await arquivo.delete();
    }
  }

  Future<void> atualizarUsuario(Usuario usuarioAtualizado) async {
    final usuarios = await carregarUsuarios();

    final indice = usuarios.indexWhere(
      (usuario) => usuario.cpf == usuarioAtualizado.cpf,
    );

    if (indice == -1) return;

    usuarios[indice] = usuarioAtualizado;

    await salvarUsuarios(usuarios);
  }

  Future<void> excluirUsuario(String cpf) async {
    final usuarios = await carregarUsuarios();

    usuarios.removeWhere(
      (usuario) => usuario.cpf == cpf,
    );

    await salvarUsuarios(usuarios);

    final cpfSessao = await obterCpfSessao();

    if (cpfSessao == cpf) {
      await logout();
    }
  }
}