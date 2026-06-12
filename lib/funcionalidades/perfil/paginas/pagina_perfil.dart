import 'package:flutter/material.dart';

import '../../../dados/modelos/usuario.dart';
import '../../../dados/servicos/armazenamento_usuario.dart';
import '../../autenticacao/paginas/pagina_login.dart';
import '../../../dados/api/servico_api_usuario.dart';

class PaginaPerfil extends StatefulWidget {
  const PaginaPerfil({super.key});

  @override
  State<PaginaPerfil> createState() => _PaginaPerfilState();
}

class _PaginaPerfilState extends State<PaginaPerfil> {
  final ArmazenamentoUsuario armazenamentoUsuario =
      ArmazenamentoUsuario();

  final ServicoApiUsuario servicoApiUsuario =
    ServicoApiUsuario();

  final Color azulPrincipal = const Color(0xFF1565C0);
  final Color fundoTela = const Color(0xFFF6F9FF);

  Usuario? usuario;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  Future<void> carregarUsuario() async {
    final usuarioLogado =
        await armazenamentoUsuario.obterUsuarioLogado();

    if (!mounted) return;

    setState(() {
      usuario = usuarioLogado;
      carregando = false;
    });
  }

  String formatarCpf(String cpf) {
    if (cpf.length != 11) return cpf;

    return '${cpf.substring(0, 3)}.'
        '${cpf.substring(3, 6)}.'
        '${cpf.substring(6, 9)}-'
        '${cpf.substring(9)}';
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  Future<void> sairDaConta() async {
    await armazenamentoUsuario.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const PaginaLogin(),
      ),
      (route) => false,
    );
  }

  Future<void> confirmarSaida() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text(
            'Deseja realmente sair da sua conta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await sairDaConta();
    }
  }

  Future<void> mostrarPopup({
    required String titulo,
    required String mensagem,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(titulo),
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

  Widget cardModerno({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget itemInformacao({
    required IconData icone,
    required String titulo,
    required String descricao,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: azulPrincipal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icone,
              color: azulPrincipal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> editarPerfil() async {
    if (usuario == null) return;
    FocusScope.of(context).unfocus();

    final controladorNome =
        TextEditingController(
      text: usuario!.nome,
    );

    final controladorNomeUsuario =
        TextEditingController(
      text: usuario!.nomeUsuario,
    );

    final controladorEmail =
        TextEditingController(
      text: usuario!.emailRecuperacao,
    );

    String tipoSelecionado =
        usuario!.tipoDiabetes;
    
    DateTime dataNascimentoSelecionada =
        usuario!.dataNascimento;

    final resultado =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Editar perfil',
          ),
          content: StatefulBuilder(
            builder: (
              context,
              atualizarDialog,
            ) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          controladorNome,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nome',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controladorNomeUsuario,
                      decoration: const InputDecoration(
                        labelText: 'Nome de usuário',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: controladorEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    InkWell(
                      onTap: () async {
                        FocusScope.of(context).unfocus();

                        final data = await showDatePicker(
                          context: context,
                          initialDate: dataNascimentoSelecionada,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (data == null) {
                          return;
                        }

                        atualizarDialog(() {
                          dataNascimentoSelecionada = data;
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de nascimento',
                        ),
                        child: Text(
                          '${dataNascimentoSelecionada.day.toString().padLeft(2, '0')}/'
                          '${dataNascimentoSelecionada.month.toString().padLeft(2, '0')}/'
                          '${dataNascimentoSelecionada.year}',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue:
                          tipoSelecionado,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Tipo de diabetes',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value:
                              'Tipo 1',
                          child: Text(
                            'Tipo 1',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'Tipo 2',
                          child: Text(
                            'Tipo 2',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'Gestacional',
                          child: Text(
                            'Gestacional',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'Não informado',
                          child: Text(
                            'Não informado',
                          ),
                        ),
                      ],
                      onChanged: (
                        valor,
                      ) {
                        if (valor ==
                            null) {
                          return;
                        }

                        atualizarDialog(
                          () {
                            tipoSelecionado =
                                valor;
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();

                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      return;
    }

    final erro =
        await servicoApiUsuario.atualizarPerfil(
          cpf: usuario!.cpf,
          nome: controladorNome.text.trim(),
          nomeUsuario: controladorNomeUsuario.text.trim(),
          emailRecuperacao: controladorEmail.text.trim(),
          tipoDiabetes: tipoSelecionado,
          dataNascimento: dataNascimentoSelecionada,
        );

    if (erro != null) {
      await mostrarPopup(
        titulo: 'Erro ao atualizar',
        mensagem: erro,
      );
      return;
    }

    final usuarioAtualizado =
        usuario!.copiarCom(
      nome: controladorNome.text.trim(),
      nomeUsuario: controladorNomeUsuario.text.trim(),
      emailRecuperacao: controladorEmail.text.trim(),
      tipoDiabetes: tipoSelecionado,
      dataNascimento: dataNascimentoSelecionada,
    );

    final usuarios =
        await armazenamentoUsuario
            .carregarUsuarios();

    final indice =
        usuarios.indexWhere(
      (u) => u.cpf == usuario!.cpf,
    );

    if (indice != -1) {
      usuarios[indice] =
          usuarioAtualizado;
    }

    await armazenamentoUsuario
        .salvarUsuarios(
      usuarios,
    );

    await armazenamentoUsuario
        .salvarSessao(
      usuarioAtualizado.cpf,
    );

    setState(() {
      usuario =
          usuarioAtualizado;
    });

    await mostrarPopup(
      titulo: 'Perfil atualizado',
      mensagem: 'Seus dados foram atualizados com sucesso.',
    );
  }

  Future<void> alterarPin() async {
    if (usuario == null) return;

    FocusScope.of(context).unfocus();

    final controladorPinAtual = TextEditingController();
    final controladorNovoPin = TextEditingController();
    final controladorConfirmarPin = TextEditingController();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Alterar PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controladorPinAtual,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'PIN atual',
                  ),
                ),
                TextField(
                  controller: controladorNovoPin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Novo PIN',
                  ),
                ),
                TextField(
                  controller: controladorConfirmarPin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar novo PIN',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    final pinAtual = controladorPinAtual.text.trim();
    final novoPin = controladorNovoPin.text.trim();
    final confirmarPin = controladorConfirmarPin.text.trim();

    controladorPinAtual.dispose();
    controladorNovoPin.dispose();
    controladorConfirmarPin.dispose();

    if (confirmou != true) return;

    if (pinAtual.length != 6 || novoPin.length != 6) {
      await mostrarPopup(
        titulo: 'PIN inválido',
        mensagem: 'O PIN atual e o novo PIN devem conter 6 dígitos.',
      );
      return;
    }

    if (novoPin != confirmarPin) {
      await mostrarPopup(
        titulo: 'Confirmação inválida',
        mensagem: 'A confirmação do PIN não corresponde ao novo PIN.',
      );
      return;
    }

    final erro = await servicoApiUsuario.alterarPin(
      cpf: usuario!.cpf,
      pinAtual: pinAtual,
      novoPin: novoPin,
    );

    if (erro != null) {
      await mostrarPopup(
        titulo: 'Erro ao alterar PIN',
        mensagem: erro,
      );
      return;
    }

    final usuarioAtualizado = usuario!.copiarCom(
      pin: novoPin,
    );

    final usuarios = await armazenamentoUsuario.carregarUsuarios();

    final indice = usuarios.indexWhere(
      (u) => u.cpf == usuario!.cpf,
    );

    if (indice != -1) {
      usuarios[indice] = usuarioAtualizado;
    }

    await armazenamentoUsuario.salvarUsuarios(usuarios);

    setState(() {
      usuario = usuarioAtualizado;
    });

    await mostrarPopup(
      titulo: 'PIN alterado',
      mensagem: 'Seu PIN foi alterado com sucesso.',
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
              'Perfil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: carregando
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : usuario == null
                  ? const Center(
                      child: Text(
                        'Usuário não encontrado.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: azulPrincipal,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: azulPrincipal.withValues(alpha: 0.20),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 92,
                                width: 92,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 52,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                usuario!.nome,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${usuario!.nomeUsuario}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                usuario!.emailRecuperacao,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        cardModerno(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dados do usuário',
                                style: tema.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: azulPrincipal,
                                ),
                              ),
                              const SizedBox(height: 18),
                              itemInformacao(
                                icone: Icons.badge_outlined,
                                titulo: 'CPF',
                                descricao:
                                    formatarCpf(usuario!.cpf),
                              ),
                              itemInformacao(
                                icone:
                                    Icons.calendar_month_outlined,
                                titulo: 'Data de nascimento',
                                descricao: formatarData(
                                  usuario!.dataNascimento,
                                ),
                              ),
                              itemInformacao(
                                icone:
                                    Icons.bloodtype_outlined,
                                titulo: 'Tipo de diabetes',
                                descricao:
                                    usuario!.tipoDiabetes,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: editarPerfil,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text(
                                    'Editar perfil',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: azulPrincipal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: alterarPin,
                                  icon: const Icon(Icons.lock_reset_outlined),
                                  label: const Text(
                                    'Alterar PIN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: azulPrincipal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        cardModerno(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sobre o aplicativo',
                                style: tema.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: azulPrincipal,
                                ),
                              ),
                              const SizedBox(height: 18),
                              itemInformacao(
                                icone:
                                    Icons.monitor_heart_outlined,
                                titulo: 'Controle glicêmico',
                                descricao:
                                    'Registre medições, acompanhe gráficos e visualize indicadores importantes da sua glicemia.',
                              ),
                              itemInformacao(
                                icone:
                                    Icons.medication_outlined,
                                titulo: 'Medicamentos',
                                descricao:
                                    'Organize medicamentos por refeição e receba notificações inteligentes no momento correto.',
                              ),
                              itemInformacao(
                                icone:
                                    Icons.note_alt_outlined,
                                titulo: 'Anotações diárias',
                                descricao:
                                    'Registre sintomas, alimentação, rotina e observações importantes do dia a dia.',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: confirmarSaida,
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Sair da conta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      );
  }
}