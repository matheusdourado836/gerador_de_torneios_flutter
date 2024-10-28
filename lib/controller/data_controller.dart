import 'package:flutter/material.dart';
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
}