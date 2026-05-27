import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/anotacao_diaria.dart';
import '../servicos/armazenamento_usuario.dart';
import 'api_config.dart';

class ServicoApiAnotacoes {
  final ArmazenamentoUsuario armazenamentoUsuario = ArmazenamentoUsuario();

  Future<int?> obterUsuarioIdAtual() async {
    final usuario = await armazenamentoUsuario.obterUsuarioLogado();

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

  String formatarDataMysql(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    final segundo = data.second.toString().padLeft(2, '0');

    return '$ano-$mes-$dia $hora:$minuto:$segundo';
  }

  Future<List<AnotacaoDiaria>> carregar() async {
    final usuarioId = await obterUsuarioIdAtual();

    if (usuarioId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final resposta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/anotacoes/$usuarioId'),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao carregar anotações.');
    }

    final dados = jsonDecode(resposta.body);
    final anotacoes = dados['anotacoes'] as List;

    return anotacoes.map((item) {
      return AnotacaoDiaria(
        texto: item['texto'] ?? '',
        dataHora: DateTime.parse(item['dataHora']),
        dataCriacao: DateTime.parse(item['dataCriacao']),
      );
    }).toList();
  }

  Future<bool> salvarAnotacao(AnotacaoDiaria anotacao) async {
    try {
      final usuarioId = await obterUsuarioIdAtual();

      if (usuarioId == null) return false;

      final resposta = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/anotacoes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuarioId': usuarioId,
          'texto': anotacao.texto,
          'dataHora': formatarDataMysql(anotacao.dataHora),
          'dataCriacao': formatarDataMysql(anotacao.dataCriacao),
        }),
      );

      return resposta.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}