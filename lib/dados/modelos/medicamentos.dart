class Medicamento {
  final String id;
  final String nome;
  final String tipo;
  final String refeicao;
  final String momento;
  final String observacao;
  final DateTime dataCriacao;

  Medicamento({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.refeicao,
    required this.momento,
    required this.observacao,
    required this.dataCriacao,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'refeicao': refeicao,
      'momento': momento,
      'observacao': observacao,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory Medicamento.deMapa(Map<String, dynamic> mapa) {
    return Medicamento(
      id: mapa['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nome: mapa['nome'] ?? '',
      tipo: mapa['tipo'] ?? 'Comprimido',
      refeicao: mapa['refeicao'] ?? 'Café da manhã',
      momento: mapa['momento'] ?? 'Após a refeição',
      observacao: mapa['observacao'] ?? '',
      dataCriacao: mapa['dataCriacao'] != null
          ? DateTime.parse(mapa['dataCriacao'])
          : DateTime.now(),
    );
  }

  Medicamento copiarCom({
    String? id,
    String? nome,
    String? tipo,
    String? refeicao,
    String? momento,
    String? observacao,
    DateTime? dataCriacao,
  }) {
    return Medicamento(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      refeicao: refeicao ?? this.refeicao,
      momento: momento ?? this.momento,
      observacao: observacao ?? this.observacao,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}