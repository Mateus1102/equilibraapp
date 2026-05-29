import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/item_sincronizacao_pendente.dart';

class ArmazenamentoSincronizacao {
  static const String chave =
      'sincronizacao_pendente';

  Future<List<ItemSincronizacaoPendente>>
      carregar() async {
    final prefs =
        await SharedPreferences.getInstance();

    final texto = prefs.getString(chave);

    if (texto == null || texto.isEmpty) {
      return [];
    }

    final lista = jsonDecode(texto) as List;

    return lista.map((item) {
      return ItemSincronizacaoPendente.deMapa(
        item,
      );
    }).toList();
  }

  Future<void> salvar(
    List<ItemSincronizacaoPendente> itens,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final lista = itens.map((item) {
      return item.paraMapa();
    }).toList();

    await prefs.setString(
      chave,
      jsonEncode(lista),
    );
  }
}