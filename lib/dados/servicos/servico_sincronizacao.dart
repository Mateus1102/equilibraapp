import '../api/servico_api_anotacoes.dart';
import '../api/servico_api_glicemia.dart';
import '../api/servico_api_medicamentos.dart';

import '../modelos/anotacao_diaria.dart';
import '../modelos/item_sincronizacao_pendente.dart';
import '../modelos/medicamentos.dart';
import '../modelos/registro_glicemico.dart';

import '../api/servico_api_controle_medicamentos.dart';
import '../modelos/controle_medicamento_diario.dart';

import 'armazenamento_sincronizacao.dart';

import '../api/servico_api_horarios_refeicoes.dart';

class ServicoSincronizacao {
  final ArmazenamentoSincronizacao armazenamento =
      ArmazenamentoSincronizacao();

  final ServicoApiGlicemia servicoApiGlicemia =
      ServicoApiGlicemia();

  final ServicoApiAnotacoes servicoApiAnotacoes =
      ServicoApiAnotacoes();

  final ServicoApiMedicamentos servicoApiMedicamentos =
      ServicoApiMedicamentos();

  final ServicoApiHorariosRefeicoes servicoApiHorariosRefeicoes =
    ServicoApiHorariosRefeicoes();
      
  final ServicoApiControleMedicamentos
    servicoApiControleMedicamentos =
    ServicoApiControleMedicamentos();

  Future<void> sincronizar() async {
    final pendentes = await armazenamento.carregar();

    final restantes = <ItemSincronizacaoPendente>[];

    for (final item in pendentes) {
      try {
        if (item.tipo == 'glicemia') {
          final registro = RegistroGlicemico(
            glicemia: item.dados['glicemia'],
            observacao: item.dados['observacao'],
            dataHora: DateTime.parse(
              item.dados['dataHora'],
            ),
            dataCriacao: DateTime.parse(
              item.dados['dataCriacao'],
            ),
          );

          final sucesso =
              await servicoApiGlicemia.salvarRegistro(
            registro,
          );

          if (!sucesso) {
            restantes.add(item);
          }
        } else if (item.tipo == 'anotacao') {
          final anotacao = AnotacaoDiaria(
            texto: item.dados['texto'],
            dataHora: DateTime.parse(
              item.dados['dataHora'],
            ),
            dataCriacao: DateTime.parse(
              item.dados['dataCriacao'],
            ),
          );

          final sucesso =
              await servicoApiAnotacoes.salvarAnotacao(
            anotacao,
          );

          if (!sucesso) {
            restantes.add(item);
          }
        } else if (item.tipo == 'medicamento') {
          final medicamento = Medicamento(
            id: item.dados['id'],
            nome: item.dados['nome'],
            tipo: item.dados['tipo'],
            refeicao: item.dados['refeicao'],
            momento: item.dados['momento'],
            observacao: item.dados['observacao'],
            dataCriacao: DateTime.parse(
              item.dados['dataCriacao'],
            ),
          );

          final idApi =
              await servicoApiMedicamentos.salvarMedicamento(
            medicamento,
          );

          if (idApi == null) {
            restantes.add(item);
          }
        } else if (item.tipo == 'controle_medicamento') {
          final controle =
              ControleMedicamentoDiario(
            medicamentoId:
                item.dados['medicamentoId'],
            dataControle:
                item.dados['dataControle'],
            tomado:
                item.dados['tomado'],
            dataConfirmacao:
                item.dados['dataConfirmacao'] != null
                    ? DateTime.parse(
                        item.dados['dataConfirmacao'],
                      )
                    : null,
          );

          final sucesso =
              await servicoApiControleMedicamentos
                  .marcar(
            medicamentoId:
                controle.medicamentoId,
            dataControle:
                controle.dataControle,
            tomado: controle.tomado,
            dataConfirmacao:
                controle.dataConfirmacao,
          );

          if (!sucesso) {
            restantes.add(item);
          }
        } else if (item.tipo == 'horarios_refeicoes') {
          final horarios = {
            'cafe': item.dados['cafe'].toString(),
            'almoco': item.dados['almoco'].toString(),
            'jantar': item.dados['jantar'].toString(),
          };

          final sucesso = await servicoApiHorariosRefeicoes.salvar(
            horarios,
          );

          if (!sucesso) {
            restantes.add(item);
          }
        } else {
          restantes.add(item);
        }
      } catch (_) {
        restantes.add(item);
      }
    }

    await armazenamento.salvar(restantes);
  }
}