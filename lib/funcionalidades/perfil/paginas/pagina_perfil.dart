import 'package:flutter/material.dart';

import '../../../dados/modelos/usuario.dart';
import '../../../dados/servicos/armazenamento_usuario.dart';
import '../../autenticacao/paginas/pagina_login.dart';

class PaginaPerfil extends StatefulWidget {
  const PaginaPerfil({super.key});

  @override
  State<PaginaPerfil> createState() => _PaginaPerfilState();
}

class _PaginaPerfilState extends State<PaginaPerfil> {
  final ArmazenamentoUsuario armazenamentoUsuario =
      ArmazenamentoUsuario();

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
            color: Colors.black.withOpacity(0.05),
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
              color: azulPrincipal.withOpacity(0.10),
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
                            color: azulPrincipal.withOpacity(0.20),
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
                              color: Colors.white.withOpacity(0.18),
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
                          itemInformacao(
                            icone:
                                Icons.medication_outlined,
                            titulo: 'Uso de insulina',
                            descricao:
                                usuario!.usaInsulina
                                    ? 'Sim'
                                    : 'Não',
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
                        onPressed: sairDaConta,
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
    );
  }
}