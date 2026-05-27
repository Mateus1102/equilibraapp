import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../dados/modelos/usuario.dart';
import '../../../dados/servicos/armazenamento_usuario.dart';
import '../../inicio/paginas/pagina_inicial.dart';
import '../../../dados/api/servico_api_usuario.dart';

class PaginaCadastroUsuario extends StatefulWidget {
  const PaginaCadastroUsuario({super.key});

  @override
  State<PaginaCadastroUsuario> createState() => _PaginaCadastroUsuarioState();
}

class _PaginaCadastroUsuarioState extends State<PaginaCadastroUsuario> {
  final TextEditingController controladorNome = TextEditingController();
  final TextEditingController controladorCpf = TextEditingController();
  final TextEditingController controladorEmail = TextEditingController();
  final TextEditingController controladorPin = TextEditingController();

  final ArmazenamentoUsuario armazenamentoUsuario = ArmazenamentoUsuario();
  final ServicoApiUsuario servicoApiUsuario = ServicoApiUsuario();

  DateTime dataNascimento = DateTime(2000, 1, 1);

  String tipoDiabetes = 'Tipo 1';
  bool usaInsulina = false;

  final Color azulPrincipal = const Color(0xFF1565C0);
  final Color fundoTela = const Color(0xFFF6F9FF);

  @override
  void dispose() {
    controladorNome.dispose();
    controladorCpf.dispose();
    controladorEmail.dispose();
    controladorPin.dispose();
    super.dispose();
  }

  String limparCpf(String cpf) {
    return cpf.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool validarCpf(String cpf) {
    final numeros = limparCpf(cpf);

    if (numeros.length != 11) return false;

    if (RegExp(r'^(\d)\1*$').hasMatch(numeros)) {
      return false;
    }

    int calcularDigito(String base) {
      int soma = 0;

      for (int i = 0; i < base.length; i++) {
        soma += int.parse(base[i]) * (base.length + 1 - i);
      }

      final resto = soma % 11;

      return resto < 2 ? 0 : 11 - resto;
    }

    final primeiroDigito = calcularDigito(numeros.substring(0, 9));
    final segundoDigito = calcularDigito(numeros.substring(0, 10));

    return primeiroDigito == int.parse(numeros[9]) &&
        segundoDigito == int.parse(numeros[10]);
  }

  bool validarEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  Future<void> selecionarDataNascimento() async {
    final hoje = DateTime.now();

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataNascimento,
      firstDate: DateTime(1900),
      lastDate: hoje,
    );

    if (dataSelecionada == null) return;

    setState(() {
      dataNascimento = dataSelecionada;
    });
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  Future<void> cadastrarUsuario() async {
    final nome = controladorNome.text.trim();
    final cpf = limparCpf(controladorCpf.text);
    final email = controladorEmail.text.trim();
    final pin = controladorPin.text.trim();

    if (nome.isEmpty) {
      mostrarMensagem('Informe seu nome.');
      return;
    }

    if (!validarCpf(cpf)) {
      mostrarMensagem('Informe um CPF válido.');
      return;
    }

    if (!validarEmail(email)) {
      mostrarMensagem('Informe um e-mail válido para recuperação.');
      return;
    }

    if (pin.length != 6) {
      mostrarMensagem('O PIN deve conter exatamente 6 dígitos.');
      return;
    }

    final usuario = Usuario(
      nome: nome,
      cpf: cpf,
      emailRecuperacao: email,
      pin: pin,
      dataNascimento: dataNascimento,
      tipoDiabetes: tipoDiabetes,
      usaInsulina: usaInsulina,
      dataCriacao: DateTime.now(),
    );

    final erro = await servicoApiUsuario.cadastrarUsuario(
      usuario,
    );

    if (!mounted) return;

    if (erro != null) {
      mostrarMensagem(erro);
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
          'Criar conta',
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
                  Text(
                    'Cadastro do usuário',
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: azulPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie seu acesso com CPF e PIN de 6 dígitos para entrar de forma rápida e segura.',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  campoDecorado(
                    child: TextField(
                      controller: controladorNome,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      controller: controladorPin,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'PIN de acesso',
                        hintText: '6 dígitos',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: selecionarDataNascimento,
                    borderRadius: BorderRadius.circular(18),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data de nascimento',
                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      child: Text(
                        formatarData(dataNascimento),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  campoDecorado(
                    child: DropdownButtonFormField<String>(
                      value: tipoDiabetes,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de diabetes',
                        prefixIcon: Icon(Icons.bloodtype_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tipo 1',
                          child: Text('Tipo 1'),
                        ),
                        DropdownMenuItem(
                          value: 'Tipo 2',
                          child: Text('Tipo 2'),
                        ),
                        DropdownMenuItem(
                          value: 'Gestacional',
                          child: Text('Gestacional'),
                        ),
                        DropdownMenuItem(
                          value: 'Não informado',
                          child: Text('Não informado'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;

                        setState(() {
                          tipoDiabetes = valor;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: azulPrincipal,
                      title: const Text(
                        'Usa insulina?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Essa informação ajuda a personalizar sua rotina.',
                      ),
                      value: usaInsulina,
                      onChanged: (valor) {
                        setState(() {
                          usaInsulina = valor;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: cadastrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulPrincipal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Criar conta',
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
    );
  }
}