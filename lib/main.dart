import 'package:flutter/material.dart';

import 'app.dart';
import 'dados/servicos/servico_notificacoes.dart';
import 'dados/modelos/controle_medicamento_diario.dart';
import 'dados/modelos/item_sincronizacao_pendente.dart';
import 'dados/servicos/armazenamento_controle_medicamentos.dart';
import 'dados/servicos/armazenamento_sincronizacao.dart';
import 'dados/api/servico_api_controle_medicamentos.dart';
import 'funcionalidades/medicamentos/paginas/pagina_medicamentos.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServicoNotificacoes.inicializar();

  ServicoNotificacoes.aoTocarNotificacao = (payload) {
    processarCliqueNotificacaoMedicamento(payload);
  };

  runApp(const AppEquilibra());

  final payloadInicial = ServicoNotificacoes.payloadInicial;

  if (payloadInicial != null) {
    ServicoNotificacoes.payloadInicial = null;

    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        processarCliqueNotificacaoMedicamento(payloadInicial);
      },
    );
  }
}

Future<void> processarCliqueNotificacaoMedicamento(
  String? payload,
) async {
  if (payload == null || payload.isEmpty) return;

  final partes = payload.split('|');

  if (partes.isEmpty) return;

  final medicamentoId = partes[0];
  final hoje = formatarDataControle(DateTime.now());
  final agora = DateTime.now();

  final armazenamentoControle =
      ArmazenamentoControleMedicamentos();

  final servicoApiControle =
      ServicoApiControleMedicamentos();

  final armazenamentoSincronizacao =
      ArmazenamentoSincronizacao();

  final controles =
      await armazenamentoControle.carregar();

  controles.removeWhere((controle) {
    return controle.medicamentoId == medicamentoId &&
        controle.dataControle == hoje;
  });

  controles.add(
    ControleMedicamentoDiario(
      medicamentoId: medicamentoId,
      dataControle: hoje,
      tomado: true,
      dataConfirmacao: agora,
    ),
  );

  await armazenamentoControle.salvar(controles);

  final sucesso = await servicoApiControle.marcar(
    medicamentoId: medicamentoId,
    dataControle: hoje,
    tomado: true,
    dataConfirmacao: agora,
  );

  if (!sucesso) {
    final pendentes =
        await armazenamentoSincronizacao.carregar();

    pendentes.add(
      ItemSincronizacaoPendente(
        tipo: 'controle_medicamento',
        dados: {
          'medicamentoId': medicamentoId,
          'dataControle': hoje,
          'tomado': true,
          'dataConfirmacao': agora.toIso8601String(),
        },
      ),
    );

    await armazenamentoSincronizacao.salvar(pendentes);
  }

  final navegador =
      AppEquilibra.navigatorKey.currentState;

  if (navegador == null) return;

  navegador.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const PaginaMedicamentos(
        abaInicial: 2,
      ),
    ),
    (route) => false,
  );
}

String formatarDataControle(DateTime data) {
  final ano = data.year.toString();
  final mes = data.month.toString().padLeft(2, '0');
  final dia = data.day.toString().padLeft(2, '0');

  return '$ano-$mes-$dia';
}