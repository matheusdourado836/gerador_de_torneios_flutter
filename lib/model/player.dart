class Player {
  String? id;
  DateTime? createdAt;
  String? nome;
  int? sex;
  int? totalJogos;
  int? vitorias;
  int? derrotas;
  int? pontos;
  int? pontosAtuais;
  int? jogosFinalizados;

  Player({
    this.id,
    this.createdAt,
    this.nome,
    this.sex,
    this.totalJogos,
    this.vitorias,
    this.derrotas,
    this.pontos,
    this.pontosAtuais,
    this.jogosFinalizados,
  });

  @override
  String toString() {
    return 'nome: $nome';
  }

  Player.withName(this.nome, this.sex) {
    createdAt = DateTime.now();
    totalJogos = 0;
    vitorias = 0;
    derrotas = 0;
    pontos = 0;
    pontosAtuais = 0;
    jogosFinalizados = 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt?.toIso8601String(),
    'nome': nome,
    'sex': sex,
    'totalJogos': totalJogos,
    'vitorias': vitorias,
    'derrotas': derrotas,
    'pontosAtuais': pontosAtuais,
    'pontos': pontos,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    nome: json['nome'],
    sex: json['sex'] != null
        ? (json['sex'] is String) ? int.parse(json['sex']) : json['sex']
        : null,
    totalJogos: json['totalJogos'],
    vitorias: json['vitorias'],
    derrotas: json['derrotas'],
    pontos: json['pontos'],
    pontosAtuais: json['pontosAtuais'],
  );
}