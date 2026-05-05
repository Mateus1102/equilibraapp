class ControleMedicamentoDiario {
  final String medicamentoId;
  final String dataControle;
  final bool tomado;
  final DateTime? dataConfirmacao;

  ControleMedicamentoDiario({
    required this.medicamentoId,
    required this.dataControle,
    required this.tomado,
    this.dataConfirmacao,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'medicamentoId': medicamentoId,
      'dataControle': dataControle,
      'tomado': tomado,
      'dataConfirmacao': dataConfirmacao?.toIso8601String(),
    };
  }

  factory ControleMedicamentoDiario.deMapa(Map<String, dynamic> mapa) {
    return ControleMedicamentoDiario(
      medicamentoId: mapa['medicamentoId'] ?? '',
      dataControle: mapa['dataControle'] ?? '',
      tomado: mapa['tomado'] ?? false,
      dataConfirmacao: mapa['dataConfirmacao'] != null
          ? DateTime.parse(mapa['dataConfirmacao'])
          : null,
    );
  }

  ControleMedicamentoDiario copiarCom({
    String? medicamentoId,
    String? dataControle,
    bool? tomado,
    DateTime? dataConfirmacao,
  }) {
    return ControleMedicamentoDiario(
      medicamentoId: medicamentoId ?? this.medicamentoId,
      dataControle: dataControle ?? this.dataControle,
      tomado: tomado ?? this.tomado,
      dataConfirmacao: dataConfirmacao ?? this.dataConfirmacao,
    );
  }
}