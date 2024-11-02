class Player {
  String? id;
  DateTime? createdAt;
  String? nome;
  int? sex;
  int? partidasJogadas;
  int? vitorias;
  int? derrotas;
  int? pontos;
  int? pontosAtuais;
  int? rodadasJogadas;

  Player({
    this.id,
    this.createdAt,
    this.nome,
    this.sex,
    this.partidasJogadas,
    this.vitorias,
    this.derrotas,
    this.pontos,
    this.pontosAtuais,
    this.rodadasJogadas,
  });

  @override
  String toString() {
    return 'id: $id, nome: $nome, sex: $sex, createdAt: $createdAt, vitorias: $vitorias, derrotas: $derrotas, partidasJogadas$partidasJogadas, pontos: $pontos';
  }

  Player.withName(this.nome, this.sex) {
    createdAt = DateTime.now();
    partidasJogadas = 0;
    vitorias = 0;
    derrotas = 0;
    pontos = 0;
    pontosAtuais = 0;
    rodadasJogadas = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'nome': nome,
      'sex': sex,
      'partidasJogadas': partidasJogadas,
      'vitorias': vitorias,
      'derrotas': derrotas,
      'pontosAtuais': pontosAtuais,
      'pontos': pontos,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      nome: json['nome'],
      sex: json['sex'] != null ? (json['sex'] is String) ? int.parse(json['sex']) : json['sex'] : null,
      partidasJogadas: json['partidasJogadas'],
      vitorias: json['vitorias'],
      derrotas: json['derrotas'],
      pontos: json['pontos'],
      pontosAtuais: json['pontosAtuais'],
    );
  }
}