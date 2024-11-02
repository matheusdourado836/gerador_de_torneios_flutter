import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'package:volleyball_tournament_app/service/firebase_service.dart';
import '../model/tournament.dart';

class DataController extends ChangeNotifier {
  static final FirebaseService _service = FirebaseService();

  List<Player> players = [];
  Tournament? tournament;
  bool loading = false;

  Future<void> getPlayers() async {
    loading = true;
    players = [];
    notifyListeners();
    players = await _service.getPlayers();
    loading = false;
    notifyListeners();
  }

  Future<dynamic> addPlayer({required Player player}) async {
    return await _service.addPlayer(player: player).whenComplete(() => getPlayers());
  }

  Future<void> removePlayer({required String playerId}) async {
    return await _service.removePlayer(playerId: playerId).whenComplete(() => getPlayers());
  }

  Future<void> updatePlayerData(Map<String, dynamic> info, String id) async {
    return await _service.updatePlayerData(info, id);
  }

  Future<void> updateTorneioData(Map<String, dynamic> info, String id) async {
    return await _service.updateTorneioData(info, id);
  }

  Future<void> addTorneio({required Tournament torneio}) async {
    final res = await _service.addTorneio(torneio: torneio);
    if(res != null) {
      tournament!.id = res;
    }
    return;
  }

  Future<void> salvarTorneio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await addTorneio(torneio: tournament!);
      final torneiosSalvos = prefs.getString('torneios') ?? '{}';
      final torneiosMap = json.decode(torneiosSalvos) as Map<String, dynamic>;

      torneiosMap[tournament!.nomeTorneio!] = tournament!.toJson();
      prefs.setString('torneios', json.encode(torneiosMap));
    }catch(e, stack) {
      log('ERRO AO SALVAR TORNEIO $e', stackTrace: stack);
    }
  }

  Future<bool> checkPass({required String nomeDoTorneio, required String userPass}) async {
    final pass = await _service.checkPass(nomeDoTorneio: nomeDoTorneio);

    return pass == userPass;
  }

  Future<String?> getTorneioByCode({required String code}) async {
    return await _service.getTorneioByCode(code: code);
  }

  Future<void> carregarTorneio(String nomeDoTorneio) async {
    try {
      loading = true;
      notifyListeners();
      await loadFromBd(nomeDoTorneio: nomeDoTorneio);
      if(tournament == null) {
        final prefs = await SharedPreferences.getInstance();
        final torneiosSalvos = prefs.getString('torneios') ?? '{}';
        final torneiosMap = json.decode(torneiosSalvos) as Map<String, dynamic>;

        loading = false;
        tournament = Tournament.fromJson(torneiosMap[nomeDoTorneio]);
        players = tournament?.jogadores ?? [];
      }else {
        players = tournament?.jogadores ?? [];
        loading = false;
        notifyListeners();
      }
    }catch(e, stack) {
      log('ERRO AO CARREGAR TORNEIO $e', stackTrace: stack);
    }
  }

  Future<void> loadFromBd({required String nomeDoTorneio}) async {
    tournament = await _service.loadFromBd(nomeDoTorneio: nomeDoTorneio);
    notifyListeners();
    return;
  }

  Future<void> cancelarTorneio({required String nomeDoTorneio}) async {
    final prefs = await SharedPreferences.getInstance();
    final torneiosSalvos = prefs.getString('torneios') ?? '{}';
    final torneiosMap = json.decode(torneiosSalvos) as Map<String, dynamic>;
    if(torneiosMap[nomeDoTorneio].isNotEmpty) {
      torneiosMap[nomeDoTorneio] = '';
      prefs.setString('torneios', jsonEncode(torneiosMap));
    }

    return;
  }

  List<List<Player>> generate4x4Combinations({bool misto = false}) {
    List<List<Player>> quartets = [];
    Map<String, int> playerCount = {};

    // Filtra jogadores por sexo
    List<Player> men = tournament!.jogadores!.where((player) => player.sex == 0).toList();
    List<Player> women = tournament!.jogadores!.where((player) => player.sex == 1).toList();

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

  List<List<Player>> generate2x2Combinations({bool misto = false}) {
    List<List<Player>> listaDeDuplas = [];

    if (misto) {
      // Separar jogadores por sexo
      List<Player> homens = players.where((p) => p.sex == null || p.sex == 0).toList();
      List<Player> mulheres = players.where((p) => p.sex == 1).toList();

      homens.sort((a, b) {
        a.partidasJogadas ??= 0;
        b.partidasJogadas ??= 0;
        return a.partidasJogadas!.compareTo(b.partidasJogadas!);
      });
      mulheres.sort((a, b) {
        a.partidasJogadas ??= 0;
        b.partidasJogadas ??= 0;
        return a.partidasJogadas!.compareTo(b.partidasJogadas!);
      });

      // Criar combinações entre homens e mulheres
      for (var homem in homens) {
        for (var mulher in mulheres) {
          listaDeDuplas.add([homem, mulher]);
        }
      }
    } else {
      // Caso misto seja falso, cria todas as combinações normalmente
      void combine(List<Player> combo, int start) {
        if (combo.length == 2) {
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

    return listaDeDuplas;
  }
}