import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ArmazenamentoHorariosRefeicoes {
  Future<File> _obterArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/horarios_refeicoes.json');
  }

  Future<void> salvar(Map<String, String> horarios) async {
    final arquivo = await _obterArquivo();
    await arquivo.writeAsString(jsonEncode(horarios));
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
      final dados = jsonDecode(jsonString) as Map<String, dynamic>;

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