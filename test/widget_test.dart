// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_tournament_app/main.dart';
import 'package:volleyball_tournament_app/model/partida.dart';
import 'package:volleyball_tournament_app/model/player.dart';

List<List<Player>> listaDeDuplas = [];
List<List<Player>> duplasQueJaJogaram = [];
List<Partida> partidas = [];
int modoDeJogo = 2;

void main() {
  test('a função deve montar as duplas corretamente sem repetir', () {
    combinations(2);
    gerar2x2game(1);

    // Limitar a 28 combinações
    int limit = 28;
    int count = 0;

    for (var combo in listaDeDuplas) {
      if (count < limit) {
        print('Dupla ${count + 1}: ${combo[0].nome} e ${combo[1].nome}');
        count++;
      } else {
        break;
      }
    }
    for (int i = 0; i < partidas.length; i++) {
      print('Partida ${i + 1}: ${partidas[i].team1!.map((p) => p.nome)} vs ${partidas[i].team2!.map((p) => p.nome)}');
    }
    // for(var i = 0; i < 2; i++) {
    //   generate2x2Game(i + 1);
    // }
    // for(var player in players) {
    //   print('O JOGADOR ${player.nome} JOGOU ${player.partidasJogadas} PARTIDAS');
    // }

  });
}

void gerar2x2game(int rodada) {
  partidas = [];
  Set<String> duplasUsadas = {};

  for (int i = 0; i < listaDeDuplas.length; i++) {
    for (int j = i + 1; j < listaDeDuplas.length; j++) {
      List<String> time1 = listaDeDuplas[i].map((dupla) => dupla.toString()).toList();
      List<String> time2 = listaDeDuplas[j].map((dupla) => dupla.toString()).toList();

      if (time1.toSet().intersection(time2.toSet()).isEmpty) {
        // Cria chaves para as duplas
        String chaveTime1 = time1.join(',');
        String chaveTime2 = time2.join(',');

        // Verifica se as duplas já jogaram
        if (!duplasUsadas.contains(chaveTime1) && !duplasUsadas.contains(chaveTime2)) {
          partidas.add(Partida(team1: listaDeDuplas[i], team2: listaDeDuplas[j]));
          duplasUsadas.add(chaveTime1);
          duplasUsadas.add(chaveTime2);
        }
      }
    }
  }
}

void combinations(int r) {
  listaDeDuplas = [];
  void combine(List<Player> combo, int start) {
    if (combo.length == r) {
      listaDeDuplas.add(List.from(combo));
      return;
    }

    for (int i = start; i < players.length; i++) {
      combo.add(players[i]);
      combine(combo, i + 1);
      combo.removeLast();
    }
  }

  combine([], 0);
}

void generate2x2Games(int rodada) {
  partidas = [];
  List<Player> dupla = [];
  Player? skippedPlayer;
  int count = 0;
  players.shuffle();

  if (players.length.isOdd) {
    final randomIndex = Random().nextInt(players.length);
    skippedPlayer = players[randomIndex];
    players = players.where((player) => player.nome != players[randomIndex].nome).toList();
  }

  for (var i = 0; i < 28; i++) {
    dupla = [];
    if (count + 1 >= players.length - 1) {
      dupla.addAll([players[count], players[0]]);
      count = 0;
    }else {
      dupla.addAll([players[count], players[count + 1]]);
    }

    if (checkIfIsUnique(dupla, listaDeDuplas)) {
      listaDeDuplas.add(dupla);
    }
    count++;
  }

  print('${listaDeDuplas.length} DUPLAS FORMADAS');

  listaDeDuplas.shuffle();

  for (var i = 0; i < listaDeDuplas.length; i++) {
    if (i < listaDeDuplas.length) {
      final team1 = listaDeDuplas[i];
      if (checkIfIsUnique(team1, duplasQueJaJogaram)) {
        duplasQueJaJogaram.add(team1);
        int opponentIndex = generateRandomIndex(team1);
        duplasQueJaJogaram.add(listaDeDuplas[opponentIndex]);

        for (var player in listaDeDuplas[opponentIndex]) {
          player.partidasJogadas = (player.partidasJogadas ?? 0) + 1;
        }

        for (var player in team1) {
          player.partidasJogadas = (player.partidasJogadas ?? 0) + 1;
        }

        partidas.add(Partida(
          team1: team1,
          team2: listaDeDuplas[opponentIndex],
        ));
      }
    }
  }

  // Remove o jogador "Bye" no final da geração das partidas
  players.removeWhere((p) => p.nome == 'Bye');
}

// Método para gerar um índice aleatório que representa um time oponente único
int generateRandomIndex(List<Player> team1) {
  int randomIndex = Random().nextInt(listaDeDuplas.length);

  // Verifica se o time gerado é único e que não contém jogadores que já jogaram no mesmo time
  while (!checkIfIsUnique(listaDeDuplas[randomIndex], duplasQueJaJogaram) ||
      checkIfIsInSameTeam(team1, listaDeDuplas[randomIndex])) {
    randomIndex = Random().nextInt(listaDeDuplas.length);
  }

  return randomIndex;
}

// Verifica se dois times têm os mesmos jogadores, independentemente da ordem
bool checkIfIsInSameTeam(List<Player> team1, List<Player> team2) {
  return (team1[0].nome == team2[0].nome || team1[0].nome == team2[1].nome) &&
      (team1[1].nome == team2[0].nome || team1[1].nome == team2[1].nome);
}

// Verifica se a dupla é única dentro da lista de duplas já formadas
bool checkIfIsUnique(List<Player> dupla, List<List<Player>> duplasJaFormadas) {
  return duplasJaFormadas.where((t) =>
  (t[0].nome == dupla[0].nome && t[1].nome == dupla[1].nome) ||
      (t[0].nome == dupla[1].nome && t[1].nome == dupla[0].nome)).isEmpty;
}

// Atualiza o número de partidas jogadas pelos jogadores de um time
void updatePlayerGames(List<Player> team) {
  for (var player in team) {
    player.partidasJogadas = (player.partidasJogadas ?? 0) + 1;
  }
}


List<Player> players = [
  Player.withName('Matheus', 0),
  Player.withName('Pedro', 0),
  Player.withName('Joao', 0),
  Player.withName('Ricardo', 0),
  Player.withName('Victor', 0),
  Player.withName('Diego', 0),
  Player.withName('Luis', 0),
  Player.withName('Marcos', 0),
  Player.withName('Andre', 0),
  Player.withName('Daniel', 0),
];