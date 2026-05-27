import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../dados/servicos/armazenamento_usuario.dart';
import '../../inicio/paginas/pagina_inicial.dart';
import 'pagina_cadastro_usuario.dart';
import 'pagina_recuperar_pin.dart';
import '../../../dados/api/servico_api_usuario.dart';

class PaginaLogin extends StatefulWidget {
  const PaginaLogin({super.key});

  @override
  State<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin> {
  final TextEditingController controladorCpf = TextEditingController();
  final TextEditingController controladorPin = TextEditingController();

  final ArmazenamentoUsuario armazenamentoUsuario = ArmazenamentoUsuario();
  final ServicoApiUsuario servicoApiUsuario = ServicoApiUsuario();

  final Color azulPrincipal = const Color(0xFF1565C0);
  final Color fundoTela = const Color(0xFFF6F9FF);

  @override
  void dispose() {
    controladorCpf.dispose();
    controladorPin.dispose();
    super.dispose();
  }

  String limparCpf(String cpf) {
    return cpf.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  Future<void> entrar() async {
    final cpf = limparCpf(controladorCpf.text);
    final pin = controladorPin.text.trim();

    if (cpf.length != 11) {
      mostrarMensagem('Informe um CPF válido.');
      return;
    }

    if (pin.length != 6) {
      mostrarMensagem('Informe o PIN com 6 dígitos.');
      return;
    }

    final usuario = await servicoApiUsuario.login(
      cpf: cpf,
      pin: pin,
    );

    if (!mounted) return;

    if (usuario == null) {
      mostrarMensagem('CPF ou PIN inválido.');
      return;
    }

    final usuariosLocais =
        await armazenamentoUsuario.carregarUsuarios();

    final indiceUsuarioLocal = usuariosLocais.indexWhere(
      (usuarioLocal) => usuarioLocal.cpf == usuario.cpf,
    );

    if (indiceUsuarioLocal == -1) {
      usuariosLocais.add(usuario);
    } else {
      usuariosLocais[indiceUsuarioLocal] = usuario;
    }

    await armazenamentoUsuario.salvarUsuarios(
      usuariosLocais,
    );

    await armazenamentoUsuario.salvarSessao(
      usuario.cpf,
    );

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const PaginaInicial(),
      ),
      (route) => false,
    );
  }

  Widget cardModerno({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget campoDecorado({required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: fundoTela,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: azulPrincipal,
        centerTitle: true,
        title: const Text(
          'Entrar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            cardModerno(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: azulPrincipal,
                    size: 52,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Acesse sua conta',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: azulPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre com seu CPF e PIN de 6 dígitos para continuar seu acompanhamento.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 26),
                  campoDecorado(
                    child: TextField(
                      controller: controladorCpf,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        hintText: 'Somente números',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  campoDecorado(
                    child: TextField(
                      controller: controladorPin,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        hintText: '6 dígitos',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: entrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulPrincipal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaginaCadastroUsuario(),
                        ),
                      );
                    },
                    child: Text(
                      'Criar nova conta',
                      style: TextStyle(
                        color: azulPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaginaRecuperarPin(),
                        ),
                      );
                    },
                    child: Text(
                      'Esqueci meu PIN',
                      style: TextStyle(
                        color: azulPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
