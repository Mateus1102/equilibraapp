import 'package:flutter/material.dart';

class PaginaLogin extends StatelessWidget {
  const PaginaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Tela de Login',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}