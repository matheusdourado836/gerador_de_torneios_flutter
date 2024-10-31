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

  Future<void> salvarTorneio({required Tournament tournament}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final torneiosSalvos = prefs.getString('torneios') ?? '{}';
      final torneiosMap = json.decode(torneiosSalvos) as Map<String, dynamic>;

      torneiosMap[tournament.nomeTorneio!] = tournament.toJson();
      prefs.setString('torneios', json.encode(torneiosMap));
    }catch(e, stack) {
      log('ERRO AO SALVAR TORNEIO $e', stackTrace: stack);
    }
  }

  Future<void> carregarTorneio(String nomeDoTorneio) async {
    try {
      loading = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final torneiosSalvos = prefs.getString('torneios') ?? '{}';
      final torneiosMap = json.decode(torneiosSalvos) as Map<String, dynamic>;

      loading = false;
      tournament = Tournament.fromJson(torneiosMap[nomeDoTorneio]);
      players = tournament?.jogadores ?? [];
      notifyListeners();
    }catch(e, stack) {
      log('ERRO AO CARREGAR TORNEIO $e', stackTrace: stack);
    }
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
}