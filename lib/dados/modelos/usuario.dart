class Usuario {
  final String nome;
  final String cpf;
  final String emailRecuperacao;
  final String pin;
  final DateTime dataNascimento;
  final String tipoDiabetes;
  final bool usaInsulina;
  final DateTime dataCriacao;

  Usuario({
    required this.nome,
    required this.cpf,
    required this.emailRecuperacao,
    required this.pin,
    required this.dataNascimento,
    required this.tipoDiabetes,
    required this.usaInsulina,
    required this.dataCriacao,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'cpf': cpf,
      'emailRecuperacao': emailRecuperacao,
      'pin': pin,
      'dataNascimento': dataNascimento.toIso8601String(),
      'tipoDiabetes': tipoDiabetes,
      'usaInsulina': usaInsulina,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory Usuario.deMapa(Map<String, dynamic> mapa) {
    return Usuario(
      nome: mapa['nome'] ?? '',
      cpf: mapa['cpf'] ?? '',
      emailRecuperacao: mapa['emailRecuperacao'] ?? '',
      pin: mapa['pin'] ?? '',
      dataNascimento: mapa['dataNascimento'] != null
          ? DateTime.parse(mapa['dataNascimento'])
          : DateTime.now(),
      tipoDiabetes: mapa['tipoDiabetes'] ?? 'Não informado',
      usaInsulina: mapa['usaInsulina'] ?? false,
      dataCriacao: mapa['dataCriacao'] != null
          ? DateTime.parse(mapa['dataCriacao'])
          : DateTime.now(),
    );
  }

  Usuario copiarCom({
    String? nome,
    String? cpf,
    String? emailRecuperacao,
    String? pin,
    DateTime? dataNascimento,
    String? tipoDiabetes,
    bool? usaInsulina,
    DateTime? dataCriacao,
  }) {
    return Usuario(
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      emailRecuperacao: emailRecuperacao ?? this.emailRecuperacao,
      pin: pin ?? this.pin,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      tipoDiabetes: tipoDiabetes ?? this.tipoDiabetes,
      usaInsulina: usaInsulina ?? this.usaInsulina,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}