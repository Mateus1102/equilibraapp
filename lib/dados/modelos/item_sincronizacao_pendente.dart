class ItemSincronizacaoPendente {
  final String tipo;
  final Map<String, dynamic> dados;

  ItemSincronizacaoPendente({
    required this.tipo,
    required this.dados,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'tipo': tipo,
      'dados': dados,
    };
  }

  factory ItemSincronizacaoPendente.deMapa(
    Map<String, dynamic> mapa,
  ) {
    return ItemSincronizacaoPendente(
      tipo: mapa['tipo'],
      dados: Map<String, dynamic>.from(
        mapa['dados'],
      ),
    );
  }
}