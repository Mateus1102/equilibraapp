class RegistroGlicemico {
  final int glicemia;
  final DateTime dataHora;
  final String observacao;

  RegistroGlicemico({
    required this.glicemia,
    required this.dataHora,
    required this.observacao,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'glicemia': glicemia,
      'dataHora': dataHora.toIso8601String(),
      'observacao': observacao,
    };
  }

  factory RegistroGlicemico.deMapa(Map<String, dynamic> mapa) {
    return RegistroGlicemico(
      glicemia: mapa['glicemia'],
      dataHora: DateTime.parse(mapa['dataHora']),
      observacao: mapa['observacao'],
    );
  }

  RegistroGlicemico copiarCom({
    int? glicemia,
    DateTime? dataHora,
    String? observacao,
  }) {
    return RegistroGlicemico(
      glicemia: glicemia ?? this.glicemia,
      dataHora: dataHora ?? this.dataHora,
      observacao: observacao ?? this.observacao,
    );
  }
}