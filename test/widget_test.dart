// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_tournament_app/model/partida.dart';
import 'package:volleyball_tournament_app/model/player.dart';

List<List<Player>> quartetsMistos = [];
List<Partida> partidas = [];

void main() {
  test('O teste deve montar quartetos sem repetir jogadores', () {
    print('TEM ${players.length} JOGADORES');
    List<Player> mulheres = players.where((p) => p.sex == 1).toList();
    List<Player> homens = players.where((p) => p.sex == 0).toList();
    print('${homens.length} HOMENS E ${mulheres.length} MULHERES');
    //startGames();
    try {
      List<List<Player>> teams = generateTeams(minGames: 3);
      // for (int i = 0; i < teams.length; i++) {
      //   print("Time ${i + 1}: ${teams[i].map((p) => p.nome!).join(", ")}");
      // }

      partidas = generateMatches(teams);

      // Exibir as partidas
      // for (int i = 0; i < partidas.length; i++) {
      //   var match = partidas[i];
      //   print("Quarteto ${i + 1}:");
      //   print("  Time 1: ${match.team1!.map((p) => p.nome).join(", ")}");
      //   print("  Time 2: ${match.team2!.map((p) => p.nome).join(", ")}");
      //   print("");
      // }
    }catch(e) {
      print("Erro: $e");
    }

    for (int i = 0; i < partidas.length; i++) {
      print("Match ${i + 1}:");
      print("Team 1: ${partidas[i].team1!.map((p) => p.nome).toList()}");
      print("Team 2: ${partidas[i].team2!.map((p) => p.nome).toList()}");
    }

    Map<String, int> matchesCount = {};
    for(Partida partida in partidas) {
      final p = [...partida.team1!, ...partida.team2!];
      for(var pp in p) {
        matchesCount[pp.nome!] = (matchesCount[pp.nome] ?? 0) + 1;
      }
    }

    matchesCount.forEach((k, v) {
      print('O JOGADOR $k JOGOU $v VEZES');
    });
    //expect(checkIfHasEqualTeam(partidas), false);
  });
}

// void startGames() {
//   quartetsMistos = generateQuartets(players, groupSize: 4, maxGroupsPerPlayer: 5);
//   partidas = createMatches();
//   checkIfHasEqualTeam(partidas);
//   balanceMatches(partidas);
// }

List<List<Player>> generateTeams({int minGames = 3}) {
  // Separar os jogadores por gênero
  List<Player> males = players.where((p) => p.sex == 0).toList();
  List<Player> females = players.where((p) => p.sex == 1).toList();

  if (females.length > males.length * 2) {
    throw Exception("Impossível formar times com no máximo 2 mulheres por time.");
  }

  // Controlar o número de jogos de cada jogador
  //Map<String, int> playCounts = {for (var p in players) p.nome!: 0};
  List<List<Player>> teams = [];

  // Rotacionar jogadores para formar times
  while (players.any((p) => (p.totalJogos ?? 0) < minGames)) {
    males.shuffle(Random());
    females.shuffle(Random());

    List<Player> team = [];

    // Selecionar até 2 mulheres
    if (females.length >= 2) {
      team.addAll(females.take(2));
    } else if (females.isNotEmpty) {
      team.addAll(females);
    }

    // Completar com homens
    team.addAll(males.take(4 - team.length));

    // Garantir que o time tenha exatamente 4 jogadores
    if (team.length == 4) {
      // Verificar se todos no time ainda precisam jogar
      if (team.every((player) => (player.totalJogos ?? 0) < minGames)) {
        // Atualizar a contagem de jogos dos jogadores
        for (var player in team) {
          player.totalJogos = (player.totalJogos ?? 0) + 1;
        }
        teams.add(team);

        // Remover os jogadores do time atual temporariamente para próxima rotação
        males.removeWhere((p) => team.contains(p));
        females.removeWhere((p) => team.contains(p));
      }
    }

    // Reabastecer as listas quando necessário
    if (males.isEmpty && females.isEmpty) {
      males = players.where((p) => p.sex == 0).toList();
      females = players.where((p) => p.sex == 1).toList();
    }
  }

  return teams;
}

List<Partida> generateMatches(List<List<Player>> teams) {
  List<Partida> matches = [];
  Map<String, int> playerAppearances = {};

  // Inicializa o contador de participações
  for (var team in teams) {
    for (var player in team) {
      playerAppearances[player.nome!] = 0;
    }
  }

  for (int i = 0; i < teams.length; i++) {
    for (int j = i + 1; j < teams.length; j++) {
      List<Player> team1 = teams[i];
      List<Player> team2 = teams[j];

      // Verificar se há jogadores em comum
      bool hasCommonPlayers = team1.any((player1) =>
          team2.any((player2) => player1.nome == player2.nome));

      if (hasCommonPlayers) continue;

      // Verificar se adicionar a partida ultrapassaria o limite
      bool exceedsLimit = false;

      for (var player in [...team1, ...team2]) {
        if (playerAppearances[player.nome]! >= 5) {
          exceedsLimit = true;
          break;
        }
      }

      if (!exceedsLimit) {
        matches.add(Partida(team1: team1, team2: team2));

        // Atualiza as participações dos jogadores
        for (var player in [...team1, ...team2]) {
          playerAppearances[player.nome!] =
              (playerAppearances[player.nome!] ?? 0) + 1;
        }
      }
    }
  }

  return matches;
}

List<Player> players = [
  Player.withName('Matheus', 0),
  //Player.withName('Maria', 1),
  Player.withName('Joao', 0),
  //Player.withName('Bia', 1),
  Player.withName('Victor', 0),
  //Player.withName('Anna', 1),
  Player.withName('Luis', 0),
  //Player.withName('Dani', 1),
  //Player.withName('Andre', 0),
  Player.withName('Clara', 1),
  //Player.withName('Fernando', 0),
  Player.withName('Juliana', 1),
  //Player.withName('Carlos', 0),
  Player.withName('Roberta', 1),
  //Player.withName('Gustavo', 0),
  //Player.withName('Sofia', 1),
  Player.withName('Rafael', 0),
  //Player.withName('Larissa', 1),
  Player.withName('Thiago', 0),
  //Player.withName('Patricia', 1),
  Player.withName('Bruno', 0),
  //Player.withName('Jéssica', 1),
  Player.withName('Diego', 0),
  Player.withName('Fernanda', 1),
  Player.withName('Eduardo', 0),
  Player.withName('Vanessa', 1),
  Player.withName('Marcelo', 0),
  Player.withName('Priscila', 1),
  Player.withName('Alan', 0),
  Player.withName('Natalia', 1),
  Player.withName('Leandro', 0),
  Player.withName('Rafaela', 1),
];
