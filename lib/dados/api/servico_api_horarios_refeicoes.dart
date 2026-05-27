import 'dart:convert';

import 'package:http/http.dart' as http;

import '../servicos/armazenamento_usuario.dart';
import 'api_config.dart';

class ServicoApiHorariosRefeicoes {
  final ArmazenamentoUsuario armazenamentoUsuario =
      ArmazenamentoUsuario();

  Future<int?> obterUsuarioIdAtual() async {
    final usuario =
        await armazenamentoUsuario.obterUsuarioLogado();

    if (usuario == null) return null;

    final resposta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cpf': usuario.cpf,
        'pin': usuario.pin,
      }),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao obter usuário na API.');
    }

    final dados = jsonDecode(resposta.body);

    return dados['usuario']['id'];
  }

  Future<Map<String, String>?> carregar() async {
    final usuarioId = await obterUsuarioIdAtual();

    if (usuarioId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final resposta = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/horarios-refeicoes/$usuarioId',
      ),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao carregar horários.');
    }

    final dados = jsonDecode(resposta.body);
    final horarios = dados['horarios'];

    return {
      'cafe': horarios['cafe'] ?? '07:00',
      'almoco': horarios['almoco'] ?? '12:00',
      'jantar': horarios['jantar'] ?? '19:00',
    };
  }

  Future<bool> salvar(
    Map<String, String> horarios,
  ) async {
    try {
      final usuarioId =
          await obterUsuarioIdAtual();

      if (usuarioId == null) return false;

      final resposta = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/horarios-refeicoes/$usuarioId',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cafe': horarios['cafe'],
          'almoco': horarios['almoco'],
          'jantar': horarios['jantar'],
        }),
      );

      return resposta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}