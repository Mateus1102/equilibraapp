import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/medicamentos.dart';
import '../servicos/armazenamento_usuario.dart';
import 'api_config.dart';

class ServicoApiMedicamentos {
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

  Future<List<Medicamento>> carregar() async {
    final usuarioId = await obterUsuarioIdAtual();

    if (usuarioId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final resposta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/medicamentos/$usuarioId'),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao carregar medicamentos.');
    }

    final dados = jsonDecode(resposta.body);
    final lista = dados['medicamentos'] as List;

    return lista.map((item) {
      return Medicamento(
        id: item['id'].toString(),
        nome: item['nome'] ?? '',
        tipo: item['tipo'] ?? 'Comprimido',
        refeicao: item['refeicao'] ?? 'Café da manhã',
        momento: item['momento'] ?? 'Após a refeição',
        observacao: item['observacao'] ?? '',
        dataCriacao: DateTime.parse(item['dataCriacao']),
      );
    }).toList();
  }

  Future<String?> salvarMedicamento(
    Medicamento medicamento,
  ) async {
    try {
      final usuarioId = await obterUsuarioIdAtual();

      if (usuarioId == null) return null;

      final resposta = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medicamentos'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuarioId': usuarioId,
          'nome': medicamento.nome,
          'tipo': medicamento.tipo,
          'refeicao': medicamento.refeicao,
          'momento': medicamento.momento,
          'observacao': medicamento.observacao,
          'dataCriacao': formatarDataMysql(
            medicamento.dataCriacao,
          ),
        }),
      );

      if (resposta.statusCode != 201) {
        return null;
      }

      final dados = jsonDecode(resposta.body);

      return dados['id'].toString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> atualizarMedicamento(
    Medicamento medicamento,
  ) async {
    try {
      final resposta = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/medicamentos/${medicamento.id}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nome': medicamento.nome,
          'tipo': medicamento.tipo,
          'refeicao': medicamento.refeicao,
          'momento': medicamento.momento,
          'observacao': medicamento.observacao,
        }),
      );

      return resposta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> excluirMedicamento(String id) async {
    try {
      final resposta = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/medicamentos/$id',
        ),
      );

      return resposta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}