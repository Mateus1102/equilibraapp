import 'dart:convert';
import 'dart:io';

import 'armazenamento_usuario_atual.dart';

class ArmazenamentoHorariosRefeicoes {
  final ArmazenamentoUsuarioAtual armazenamentoUsuarioAtual =
      ArmazenamentoUsuarioAtual();

  Future<File> _obterArquivo() async {
    return armazenamentoUsuarioAtual.obterArquivoUsuarioAtual(
      'horarios_refeicoes.json',
    );
  }

  Future<void> salvar(
    Map<String, String> horarios,
  ) async {
    final arquivo = await _obterArquivo();

    await arquivo.writeAsString(
      jsonEncode(horarios),
    );
  }

  Future<Map<String, String>> carregar() async {
    try {
      final arquivo = await _obterArquivo();

      if (!await arquivo.exists()) {
        return {
          'cafe': '07:00',
          'almoco': '12:00',
          'jantar': '19:00',
        };
      }

      final jsonString = await arquivo.readAsString();

      if (jsonString.trim().isEmpty) {
        return {
          'cafe': '07:00',
          'almoco': '12:00',
          'jantar': '19:00',
        };
      }

      final dados =
          jsonDecode(jsonString) as Map<String, dynamic>;

      return {
        'cafe': dados['cafe'] ?? '07:00',
        'almoco': dados['almoco'] ?? '12:00',
        'jantar': dados['jantar'] ?? '19:00',
      };
    } catch (e) {
      return {
        'cafe': '07:00',
        'almoco': '12:00',
        'jantar': '19:00',
      };
    }
  }
}