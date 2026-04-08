import '../modelos/registro_glicemico.dart';
import 'package:flutter/material.dart';

class ResumoGlicemico {
  final int totalRegistros;
  final RegistroGlicemico? ultimoRegistro;
  final double mediaGlicemia;
  final int? maiorGlicemia;
  final int? menorGlicemia;

  ResumoGlicemico({
    required this.totalRegistros,
    required this.ultimoRegistro,
    required this.mediaGlicemia,
    required this.maiorGlicemia,
    required this.menorGlicemia,
  });

  factory ResumoGlicemico.vazio() {
    return ResumoGlicemico(
      totalRegistros: 0,
      ultimoRegistro: null,
      mediaGlicemia: 0,
      maiorGlicemia: null,
      menorGlicemia: null,
    );
  }

  factory ResumoGlicemico.aPartirDeLista(List<RegistroGlicemico> registros) {
    if (registros.isEmpty) {
      return ResumoGlicemico.vazio();
    }

    double media = 0;

    final agora = DateTime.now();
    final dataLimite = DateTime(
      agora.year,
      agora.month - 1,
      agora.day,
      agora.hour,
      agora.minute,
      agora.second,
      agora.millisecond,
      agora.microsecond,
    );

    final registrosUltimoMes = registros.where((registro) {
      return !registro.dataHora.isBefore(dataLimite) &&
          !registro.dataHora.isAfter(agora);
    }).toList();

    int? maiorGlicemia;
    int? menorGlicemia;

    if (registrosUltimoMes.isNotEmpty) {
      final valoresUltimoMes = registrosUltimoMes
          .map((registro) => registro.glicemia)
          .toList();

      final somaUltimoMes = valoresUltimoMes.reduce(
        (valorGlicemia1, valorGlicemia2) =>
            valorGlicemia1 + valorGlicemia2,
      );

      media = somaUltimoMes / valoresUltimoMes.length;

      maiorGlicemia = valoresUltimoMes.reduce(
        (valorGlicemia1, valorGlicemia2) =>
            valorGlicemia1 > valorGlicemia2
                ? valorGlicemia1
                : valorGlicemia2,
      );

      menorGlicemia = valoresUltimoMes.reduce(
        (valorGlicemia1, valorGlicemia2) =>
            valorGlicemia1 < valorGlicemia2
                ? valorGlicemia1
                : valorGlicemia2,
      );
    }

    return ResumoGlicemico(
      totalRegistros: registros.length,
      ultimoRegistro: registros.first,
      mediaGlicemia: media,
      maiorGlicemia: maiorGlicemia,
      menorGlicemia: menorGlicemia,
    );
  }

  String obterClassificacaoUltimoRegistro() {
    if (ultimoRegistro == null) {
      return 'Sem dados';
    }

    final valor = ultimoRegistro!.glicemia;

    if (valor < 70) {
      return 'Baixo';
    } else if (valor <= 140) {
      return 'Normal';
    } else if (valor <= 180) {
      return 'Atenção';
    } else {
      return 'Alto';
    }
  }

  String obterClassificacaoMedia() {
    if (mediaGlicemia == 0) {
      return 'Sem dados';
    }

    if (mediaGlicemia < 70) {
      return 'Baixo';
    } else if (mediaGlicemia <= 140) {
      return 'Normal';
    } else if (mediaGlicemia <= 180) {
      return 'Atenção';
    } else {
      return 'Alto';
    }
  }

  Color obterCorStatus(String status) {
    switch (status) {
      case 'Baixo':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Atenção':
        return Colors.orange;
      case 'Alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}