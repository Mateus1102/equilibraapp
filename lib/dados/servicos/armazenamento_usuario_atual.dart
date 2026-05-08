import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'armazenamento_usuario.dart';

class ArmazenamentoUsuarioAtual {
  final ArmazenamentoUsuario armazenamentoUsuario = ArmazenamentoUsuario();

  Future<String?> obterCpfUsuarioAtual() async {
    return armazenamentoUsuario.obterCpfSessao();
  }

  Future<Directory> obterDiretorioUsuarioAtual() async {
    final cpf = await obterCpfUsuarioAtual();

    if (cpf == null || cpf.isEmpty) {
      throw Exception('Nenhum usuário logado encontrado.');
    }

    final diretorioBase = await getApplicationDocumentsDirectory();

    final diretorioUsuario = Directory(
      '${diretorioBase.path}/usuarios_dados/$cpf',
    );

    if (!await diretorioUsuario.exists()) {
      await diretorioUsuario.create(recursive: true);
    }

    return diretorioUsuario;
  }

  Future<File> obterArquivoUsuarioAtual(String nomeArquivo) async {
    final diretorioUsuario = await obterDiretorioUsuarioAtual();

    return File('${diretorioUsuario.path}/$nomeArquivo');
  }
}