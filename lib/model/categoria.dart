import 'package:volleyball_tournament_app/model/player.dart';

class Categoria {
  String? nome;
  String? nivelCategoria;
  List<Player>? players;

  Categoria({this.nome, this.nivelCategoria, this.players});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    nome: json['nome'],
    nivelCategoria: json['nivelCategoria'],
    players: json['players'] != null
        ? (json['players'] as List).map((player) => Player.fromJson(player)).toList()
        : null,
  );

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "nivelCategoria": nivelCategoria,
    "players": players?.map((player) => player.toJson()).toList()
  };
}