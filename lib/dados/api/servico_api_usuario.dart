import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/usuario.dart';
import 'api_config.dart';

class ServicoApiUsuario {
  Future<Usuario?> login({
    required String nomeUsuario,
    required String pin,
  }) async {
    final resposta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nomeUsuario': nomeUsuario,
        'pin': pin,
      }),
    );

    if (resposta.statusCode != 200) {
      return null;
    }

    final dados = jsonDecode(resposta.body);
    final usuario = dados['usuario'];

    return Usuario(
      nome: usuario['nome'],
      nomeUsuario: usuario['nomeUsuario'] ?? '',
      cpf: usuario['cpf'],
      emailRecuperacao: usuario['emailRecuperacao'],
      pin: pin,
      dataNascimento: DateTime.parse(usuario['dataNascimento']),
      tipoDiabetes: usuario['tipoDiabetes'],
      dataCriacao: usuario['dataCriacao'] != null
          ? DateTime.parse(usuario['dataCriacao'])
          : DateTime.now(),
    );
  }

  Future<String?> cadastrarUsuario(Usuario usuario) async {
    final resposta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/cadastro'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nome': usuario.nome,
        'nomeUsuario': usuario.nomeUsuario,
        'cpf': usuario.cpf,
        'emailRecuperacao': usuario.emailRecuperacao,
        'pin': usuario.pin,
        'dataNascimento': usuario.dataNascimento.toIso8601String(),
        'tipoDiabetes': usuario.tipoDiabetes,
      }),
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 201) {
      return null;
    }

    return dados['mensagem'] ?? 'Erro ao cadastrar usuário.';
  }

  Future<String?> recuperarPin({
    required String nomeUsuario,
    required String emailRecuperacao,
    required String novoPin,
  }) async {
    final resposta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/recuperar-pin'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nomeUsuario': nomeUsuario,
        'emailRecuperacao': emailRecuperacao,
        'novoPin': novoPin,
      }),
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return null;
    }

    return dados['mensagem'] ?? 'Erro ao recuperar PIN.';
  }

  Future<String?> atualizarPerfil({
  required String cpf,
  required String nome,
  required String emailRecuperacao,
  required String tipoDiabetes,
  required DateTime dataNascimento,
}) async {
  final resposta = await http.put(
    Uri.parse(
      '${ApiConfig.baseUrl}/usuarios/perfil/$cpf',
    ),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nome': nome,
      'emailRecuperacao': emailRecuperacao,
      'tipoDiabetes': tipoDiabetes,
      'dataNascimento': dataNascimento.toIso8601String(),
    }),
  );

  final dados = jsonDecode(resposta.body);

  if (resposta.statusCode == 200) {
    return null;
  }

  return dados['mensagem'] ?? 'Erro ao atualizar perfil.';
}

  Future<String?> alterarPin({
  required String cpf,
  required String pinAtual,
  required String novoPin,
}) async {
  try {
    final resposta = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/usuarios/alterar-pin/$cpf',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pinAtual': pinAtual,
        'novoPin': novoPin,
      }),
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return null;
    }

    return dados['mensagem'];
  } catch (_) {
    return 'Não foi possível alterar o PIN.';
  }
}
}