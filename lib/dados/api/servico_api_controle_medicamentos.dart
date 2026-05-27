import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/controle_medicamento_diario.dart';
import '../servicos/armazenamento_usuario.dart';
import 'api_config.dart';

class ServicoApiControleMedicamentos {
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

  String formatarDataMysql(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    final segundo = data.second.toString().padLeft(2, '0');

    return '$ano-$mes-$dia $hora:$minuto:$segundo';
  }

  Future<List<ControleMedicamentoDiario>> carregar() async {
    final usuarioId = await obterUsuarioIdAtual();

    if (usuarioId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final resposta = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/controle-medicamentos/$usuarioId',
      ),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao carregar controles.');
    }

    final dados = jsonDecode(resposta.body);
    final controles = dados['controles'] as List;

    return controles.map((item) {
      return ControleMedicamentoDiario(
        medicamentoId: item['medicamentoId'].toString(),
        dataControle:
            item['dataControle']
                .toString()
                .substring(0, 10),
        tomado:
            item['tomado'] == true ||
            item['tomado'] == 1,
        dataConfirmacao:
            item['dataConfirmacao'] != null
                ? DateTime.parse(
                    item['dataConfirmacao'],
                  )
                : null,
      );
    }).toList();
  }

  Future<bool> marcar({
    required String medicamentoId,
    required String dataControle,
    required bool tomado,
    DateTime? dataConfirmacao,
  }) async {
    try {
      final usuarioId =
          await obterUsuarioIdAtual();

      if (usuarioId == null) return false;

      final resposta = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/controle-medicamentos/marcar',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuarioId': usuarioId,
          'medicamentoId': medicamentoId,
          'dataControle': dataControle,
          'tomado': tomado,
          'dataConfirmacao':
              dataConfirmacao != null
                  ? formatarDataMysql(
                      dataConfirmacao,
                    )
                  : null,
        }),
      );

      return resposta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}