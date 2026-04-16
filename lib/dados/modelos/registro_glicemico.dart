class RegistroGlicemico {
  final int glicemia;
  final DateTime dataHora;
  final String observacao;
  final DateTime dataCriacao;

  RegistroGlicemico({
    required this.glicemia,
    required this.dataHora,
    required this.observacao,
    required this.dataCriacao,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'glicemia': glicemia,
      'dataHora': dataHora.toIso8601String(),
      'observacao': observacao,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory RegistroGlicemico.deMapa(Map<String, dynamic> mapa) {
    return RegistroGlicemico(
      glicemia: mapa['glicemia'],
      dataHora: DateTime.parse(mapa['dataHora']),
      observacao: mapa['observacao'],
      dataCriacao: mapa['dataCriacao'] != null
          ? DateTime.parse(mapa['dataCriacao'])
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  RegistroGlicemico copiarCom({
    int? glicemia,
    DateTime? dataHora,
    String? observacao,
    DateTime? dataCriacao,
  }) {
    return RegistroGlicemico(
      glicemia: glicemia ?? this.glicemia,
      dataHora: dataHora ?? this.dataHora,
      observacao: observacao ?? this.observacao,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}