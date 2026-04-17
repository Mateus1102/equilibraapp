class Medicamento {
  final String nome;
  final String dosagem;
  final String observacao;
  final DateTime dataHora;
  final DateTime dataCriacao;

  Medicamento({
    required this.nome,
    required this.dosagem,
    required this.observacao,
    required this.dataHora,
    required this.dataCriacao,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'dosagem': dosagem,
      'observacao': observacao,
      'dataHora': dataHora.toIso8601String(),
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory Medicamento.deMapa(Map<String, dynamic> mapa) {
    return Medicamento(
      nome: mapa['nome'],
      dosagem: mapa['dosagem'],
      observacao: mapa['observacao'],
      dataHora: DateTime.parse(mapa['dataHora']),
      dataCriacao: mapa['dataCriacao'] != null
          ? DateTime.parse(mapa['dataCriacao'])
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Medicamento copiarCom({
    String? nome,
    String? dosagem,
    String? observacao,
    DateTime? dataHora,
    DateTime? dataCriacao,
  }) {
    return Medicamento(
      nome: nome ?? this.nome,
      dosagem: dosagem ?? this.dosagem,
      observacao: observacao ?? this.observacao,
      dataHora: dataHora ?? this.dataHora,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}