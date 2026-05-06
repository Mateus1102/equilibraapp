import 'package:flutter/material.dart';
import 'app.dart';
import 'dados/servicos/servico_notificacoes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServicoNotificacoes.inicializar();

  runApp(const AppEquilibra());
}