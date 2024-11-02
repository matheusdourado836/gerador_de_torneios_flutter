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

  test('A função deve montar os quartetos corretamente sem repetir onde cada jogador jogou 3x', () {
    List<List<Player>> quartetsMistos = generate4x4Game(true);
    print("Quartetos mistos:");
    quartetsMistos.forEach((quartet) {
      print(quartet.map((player) => player.nome).toList());
    });
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

List<List<Player>> generate4x4Game(bool misto) {
  List<List<Player>> quartets = [];
  Map<String, int> playerCount = {};

  // Filtra jogadores por sexo
  List<Player> men = players.where((player) => player.sex == 0).toList();
  List<Player> women = players.where((player) => player.sex == 1).toList();

  // Gera combinações de quartetos
  void backtrack(List<Player> currentQuartet, int startMen, int startWomen) {
    if (currentQuartet.length == 4) {
      // Adiciona apenas se nenhum jogador excedeu o limite
      if (currentQuartet.every((player) => playerCount[player.nome!]! < 3)) {
        quartets.add(List.from(currentQuartet));
        for (var player in currentQuartet) {
          playerCount[player.nome!] = playerCount[player.nome!]! + 1; // Incrementa a contagem
        }
      }
      return;
    }

    // Adiciona homens
    if (currentQuartet.length < 2 && startMen < men.length) {
      currentQuartet.add(men[startMen]);
      backtrack(currentQuartet, startMen + 1, startWomen);
      currentQuartet.removeLast();
    }

    // Adiciona mulheres
    if (currentQuartet.length < 4 && startWomen < women.length) {
      currentQuartet.add(women[startWomen]);
      backtrack(currentQuartet, startMen, startWomen + 1);
      currentQuartet.removeLast();
    }
  }

  if (misto) {
    // Gera quartetos mistos com 2 homens e 2 mulheres
    for (int i = 0; i < men.length; i++) {
      for (int j = i + 1; j < men.length; j++) {
        for (int k = 0; k < women.length; k++) {
          for (int l = k + 1; l < women.length; l++) {
            var quartet = [men[i], men[j], women[k], women[l]];
            if (quartet.every((player) => playerCount[player.nome!] == null || playerCount[player.nome!]! < 3)) {
              quartets.add(quartet);
              for (var player in quartet) {
                playerCount[player.nome!] = (playerCount[player.nome!] ?? 0) + 1; // Incrementa a contagem
              }
            }
          }
        }
      }
    }
  } else {
    // Gera quartetos não mistos (apenas homens)
    backtrack([], 0, 0);
  }

  return quartets;
}



List<Player> players = [
  Player.withName('Matheus', 0),
  Player.withName('Maria', 1),
  Player.withName('Joao', 0),
  Player.withName('Bia', 1),
  Player.withName('Victor', 0),
  Player.withName('Anna', 1),
  Player.withName('Luis', 0),
  Player.withName('Dani', 1),
  Player.withName('Andre', 0),
  Player.withName('Clara', 1),
  Player.withName('Fernando', 0),
  Player.withName('Juliana', 1),
  Player.withName('Carlos', 0),
  Player.withName('Roberta', 1),
  Player.withName('Gustavo', 0),
  Player.withName('Sofia', 1),
  Player.withName('Rafael', 0),
  Player.withName('Larissa', 1),
  Player.withName('Thiago', 0),
  Player.withName('Patricia', 1),
  Player.withName('Bruno', 0),
  Player.withName('Jéssica', 1),
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
