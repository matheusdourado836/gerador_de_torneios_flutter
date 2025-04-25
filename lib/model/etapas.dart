import 'package:volleyball_tournament_app/model/partida.dart';

class AllFases {
  Map<String, dynamic> fases;

  AllFases({required this.fases});

  factory AllFases.fromJson(Map<String, dynamic> json) => AllFases(fases: json);
}

class Fase {
  final String nome;
  final List<Partida> partidas;
  
  Fase({required this.nome, required this.partidas});

  factory Fase.fromJson(Map<String, dynamic> json) => Fase(
    nome: json['nome'],
    partidas: json['partidas'] != null
        ? (json['partidas'] as List).map((partida) => Partida.fromJson(partida)).toList()
        : [],
  );

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "partidas": partidas.map((p) => p.toJson()).toList(),
  };
}