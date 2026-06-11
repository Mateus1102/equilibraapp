import 'package:flutter/material.dart';

class PaginaTermosUso extends StatelessWidget {
  const PaginaTermosUso({super.key});

  final Color azulPrincipal = const Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulPrincipal,
        centerTitle: true,
        title: const Text(
          'Termos de Uso',
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
            const Text(
              '''TERMO DE ACEITE E CONSENTIMENTO PARA TRATAMENTO DE DADOS PESSOAIS – APLICATIVO "EQUILIBRA"
                    Este Termo de Aceite e Consentimento regula o tratamento de dados pessoais dos usuários do aplicativo “Equilibra”, em conformidade com a Lei Geral de Proteção de Dados Pessoais (LGPD) – Lei nº 13.709/2018.
                    1. Controlador dos Dados
                    A “Equilibra”, doravante denominada Controladora, é a responsável pelo tratamento dos dados pessoais coletados por meio do aplicativo “Equilibra”.
                    2. Dados Pessoais Coletados
                    O aplicativo “Equilibra” coleta os seguintes dados dos usuários:
                    •	Nome completo;
                    •	Endereço de e-mail;
                    •	Data de nascimento;
                    •	CPF.
                    3. Finalidade da Coleta dos Dados
                    Os dados são coletados com as seguintes finalidades:
                    •	Cadastro e autenticação do usuário no aplicativo;
                    •	Cumprimento de obrigações legais e regulatórias;
                    •	Melhoria dos serviços oferecidos pelo aplicativo.
                    4. Compartilhamento de Dados
                    Os dados poderão ser compartilhados com:
                    •	Parceiros tecnológicos e provedores de serviços essenciais ao funcionamento do aplicativo;
                    •	Autoridades legais, mediante requisição legal ou judicial.
                    5. Armazenamento e Segurança
                    Os dados serão armazenados de forma segura, em ambiente controlado, utilizando medidas técnicas e administrativas adequadas à proteção de dados pessoais contra acessos não autorizados, perda, destruição ou qualquer forma de tratamento inadequado.
                    6. Direitos do Titular dos Dados
                    Nos termos da LGPD, o usuário tem direito a:
                    •	Confirmar a existência de tratamento;
                    •	Acessar os dados;
                    •	Corrigir dados incompletos, inexatos ou desatualizados;
                    •	Solicitar a anonimização, bloqueio ou eliminação de dados desnecessários;
                    •	Revogar o consentimento a qualquer momento.
                    7. Consentimento
                    Ao clicar em “Aceito”, o usuário declara ter lido, compreendido e concordado com os termos deste documento, autorizando expressamente o tratamento dos seus dados pessoais conforme descrito.
                    8. Atualizações
                    Este termo poderá ser atualizado a qualquer momento para refletir mudanças legais ou melhorias no aplicativo. Os usuários serão notificados em caso de alterações relevantes.
              ''',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Li e aceito os termos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
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