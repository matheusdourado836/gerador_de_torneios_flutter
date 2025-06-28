import 'package:volleyball_tournament_app/model/partida.dart';
import 'package:volleyball_tournament_app/model/player.dart';

import 'etapas.dart';

class Categoria {
  String? nome;
  String? nivelCategoria;
  List<Player>? players;
  List<Partida>? partidas;

  Categoria({this.nome, this.nivelCategoria, this.players, this.partidas});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    nome: json['nome'],
    nivelCategoria: json['nivelCategoria'],
    players: json['players'] != null
        ? (json['players'] as List).map((player) => Player.fromJson(player)).toList()
        : null,
    partidas: json['partidas'] != null ? (json['partidas'] as List).map((partida) => Partida.fromJson(partida)).toList() : null,
  );

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "nivelCategoria": nivelCategoria,
    "players": players?.map((player) => player.toJson()).toList(),
    "partidas": partidas?.map((partida) => partida.toJson()).toList(),
  };
}

class Chave {
  String? nome;
  Map<String, List<Player>> times;
  AllFases? selectedStage;
  Partida? thirdPlaceMatch;

  Chave({required this.nome, required this.times, this.selectedStage, this.thirdPlaceMatch});

  factory Chave.fromJson(Map<String, dynamic> json) => Chave(
    nome: json["nome"],
    times: json['times'] != null
        ? (json['times'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as List).map((player) => Player.fromJson(player)).toList()),
        )
        : {},
    selectedStage: json['selectedStage'] != null
        ? AllFases.fromJson(json['selectedStage'])
        : null,
    thirdPlaceMatch: json['thirdPlaceMatch'] != null ? Partida.fromJson(json['thirdPlaceMatch']) : null,
  );

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "times": times.map(
      (key, value) => MapEntry(key, value.map((jogador) => jogador.toJson()).toList()),
    ),
    "selectedStage": selectedStage?.fases,
    "thirdPlaceMatch": thirdPlaceMatch?.toJson()
  };
}