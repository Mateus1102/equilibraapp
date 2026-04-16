class AnotacaoDiaria {
  final String texto;
  final DateTime dataHora;
  final DateTime dataCriacao;

  AnotacaoDiaria({
    required this.texto,
    required this.dataHora,
    required this.dataCriacao,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'texto': texto,
      'dataHora': dataHora.toIso8601String(),
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory AnotacaoDiaria.deMapa(Map<String, dynamic> mapa) {
    return AnotacaoDiaria(
      texto: mapa['texto'],
      dataHora: DateTime.parse(mapa['dataHora']),
      dataCriacao: mapa['dataCriacao'] != null
          ? DateTime.parse(mapa['dataCriacao'])
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  AnotacaoDiaria copiarCom({
    String? texto,
    DateTime? dataHora,
    DateTime? dataCriacao,
  }) {
    return AnotacaoDiaria(
      texto: texto ?? this.texto,
      dataHora: dataHora ?? this.dataHora,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}