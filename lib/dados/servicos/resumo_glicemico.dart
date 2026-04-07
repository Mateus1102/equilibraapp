import '../modelos/registro_glicemico.dart';

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

    final valores = registros.map((registro) => registro.glicemia).toList();
    final soma = valores.reduce((valorGlicemia1, valorGlicemia2) => valorGlicemia1 + valorGlicemia2);
    final media = soma / valores.length;

    return ResumoGlicemico(
      totalRegistros: registros.length,
      ultimoRegistro: registros.first,
      mediaGlicemia: media,
      maiorGlicemia: valores.reduce((valorGlicemia1, valorGlicemia2) => valorGlicemia1 > valorGlicemia2 ? valorGlicemia1 : valorGlicemia2),
      menorGlicemia: valores.reduce((valorGlicemia1, valorGlicemia2) => valorGlicemia1 < valorGlicemia2 ? valorGlicemia1 : valorGlicemia2),
    );
  }
}