import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../dados/servicos/armazenamento_usuario.dart';
import '../../../dados/api/servico_api_usuario.dart';

class PaginaRecuperarPin extends StatefulWidget {
  const PaginaRecuperarPin({super.key});

  @override
  State<PaginaRecuperarPin> createState() => _PaginaRecuperarPinState();
}

class _PaginaRecuperarPinState extends State<PaginaRecuperarPin> {
  final TextEditingController controladorNomeUsuario = TextEditingController();
  final TextEditingController controladorEmail = TextEditingController();
  final TextEditingController controladorNovoPin = TextEditingController();

  final ArmazenamentoUsuario armazenamentoUsuario = ArmazenamentoUsuario();
  final ServicoApiUsuario servicoApiUsuario = ServicoApiUsuario();

  final Color azulPrincipal = const Color(0xFF1565C0);
  final Color fundoTela = const Color(0xFFF6F9FF);

  @override
  void dispose() {
    controladorNomeUsuario.dispose();
    controladorEmail.dispose();
    controladorNovoPin.dispose();
    super.dispose();
  }

  Future<void> mostrarMensagem(String mensagem) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Aviso'),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> redefinirPin() async {
    FocusScope.of(context).unfocus();

    final nomeUsuario =
        controladorNomeUsuario.text.trim().toLowerCase();
    final email = controladorEmail.text.trim().toLowerCase();
    final novoPin = controladorNovoPin.text.trim();

    if (nomeUsuario.isEmpty) {
      await mostrarMensagem('Informe seu nome de usuário.');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      await mostrarMensagem('Informe o e-mail de recuperação cadastrado.');
      return;
    }

    if (novoPin.length != 6) {
      await mostrarMensagem('O novo PIN deve conter exatamente 6 dígitos.');
      return;
    }

    final erro = await servicoApiUsuario.recuperarPin(
      nomeUsuario: nomeUsuario,
      emailRecuperacao: email,
      novoPin: novoPin,
    );

    if (erro != null) {
      await mostrarMensagem(erro);
      return;
    }

    final usuarios = await armazenamentoUsuario.carregarUsuarios();

    for (int i = 0; i < usuarios.length; i++) {
      if (usuarios[i].nomeUsuario == nomeUsuario) {
        usuarios[i] = usuarios[i].copiarCom(
          pin: novoPin,
        );
        break;
      }
    }

    await armazenamentoUsuario.salvarUsuarios(usuarios);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('PIN redefinido'),
          content: const Text(
            'Seu PIN foi alterado com sucesso. Use o novo PIN para entrar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context).pop();
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: fundoTela,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: azulPrincipal,
          centerTitle: true,
          title: const Text(
            'Recuperar PIN',
            style: TextStyle(
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
                      Icons.lock_reset_outlined,
                      color: azulPrincipal,
                      size: 52,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Esqueceu seu PIN?',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: azulPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Informe seu nome de usuário, e-mail de recuperação e defina um novo PIN de 6 dígitos.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 26),
                    campoDecorado(
                      child: TextField(
                        controller: controladorNomeUsuario,
                        textCapitalization: TextCapitalization.none,
                        decoration: const InputDecoration(
                          labelText: 'Nome de usuário',
                          hintText: 'Ex.: maria123',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    campoDecorado(
                      child: TextField(
                        controller: controladorEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail de recuperação',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    campoDecorado(
                      child: TextField(
                        controller: controladorNovoPin,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Novo PIN',
                          hintText: '6 dígitos',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: redefinirPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulPrincipal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Redefinir PIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}