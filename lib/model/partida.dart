import 'package:volleyball_tournament_app/model/player.dart';

class Partida {
  List<Player>? team1;
  List<Player>? team2;
  int? vencedor;
  String? pontos;
  bool? finished;

  Partida({
    this.team1,
    this.team2,
    this.vencedor,
    this.pontos,
    this.finished,
  });

  @override
  toString() {
    return '$team1 /// $team2';
  }

  Map<String, dynamic> toJson() {
    return {
      'team1': team1?.map((player) => player.toJson()).toList(),
      'team2': team2?.map((player) => player.toJson()).toList(),
      'vencedor': vencedor,
      'pontos': pontos,
      'finished': finished,
    };
  }

  factory Partida.fromJson(Map<String, dynamic> json) {
    return Partida(
      team1: (json['team1'] as List?)?.map((item) => Player.fromJson(item)).toList(),
      team2: (json['team2'] as List?)?.map((item) => Player.fromJson(item)).toList(),
      vencedor: json['vencedor'],
      pontos: json['pontos'],
      finished: json['finished'],
    );
  }
}