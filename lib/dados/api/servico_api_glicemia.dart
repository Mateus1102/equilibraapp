import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/registro_glicemico.dart';
import '../servicos/armazenamento_usuario.dart';
import 'api_config.dart';

class ServicoApiGlicemia {
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

  Future<List<RegistroGlicemico>> carregar() async {
    final usuarioId = await obterUsuarioIdAtual();

    if (usuarioId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final resposta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/glicemias/$usuarioId'),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao carregar glicemias.');
    }

    final dados = jsonDecode(resposta.body);
    final registros = dados['registros'] as List;

    return registros.map((item) {
      return RegistroGlicemico(
        glicemia: item['glicemia'],
        observacao: item['observacao'] ?? '',
        dataHora: DateTime.parse(item['dataHora']),
        dataCriacao: DateTime.parse(item['dataCriacao']),
      );
    }).toList();
  }

  Future<bool> salvarRegistro(RegistroGlicemico registro) async {
    try {
      final usuarioId = await obterUsuarioIdAtual();

      if (usuarioId == null) return false;

      final resposta = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/glicemias'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuarioId': usuarioId,
          'glicemia': registro.glicemia,
          'observacao': registro.observacao,
          'dataHora': formatarDataMysql(registro.dataHora),
          'dataCriacao': formatarDataMysql(registro.dataCriacao),
        }),
      );

      return resposta.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}