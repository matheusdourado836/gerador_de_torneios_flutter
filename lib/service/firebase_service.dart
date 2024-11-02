import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:volleyball_tournament_app/model/player.dart';

import '../model/tournament.dart';

class FirebaseService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;

  Future<List<Player>> getPlayers() async {
    List<Player> players = [];
    await _database.collection('players').get().then((res) {
      if(res.docs.isNotEmpty) {
        for(var doc in res.docs) {
          if(doc.exists) {
            players.add(Player.fromJson(doc.data()));
          }
        }
      }
    });

    return players;
  }

  Future<dynamic> addPlayer({required Player player}) async {
    final querySnapshot = await _database
        .collection('players')
        .where('nome', isEqualTo: player.nome)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return 'Jogador com o mesmo nome já existe!';
    }

    final ref = await _database.collection('players').add(player.toJson());
    player.id = ref.id;

    return await updatePlayerData({"id": player.id}, ref.id);
  }

  Future<void> removePlayer({required String playerId}) async {
    return await _database.collection('players').doc(playerId).delete();
  }

  Future<void> updatePlayerData(Map<String, dynamic> info, String id) async {
    return await _database.collection('players').doc(id).update(info);
  }

  Future<void> updateTorneioData(Map<String, dynamic> info, String id) async {
    return await _database.collection('torneios').doc(id).update(info);
  }

  Future<String?> checkPass({required String nomeDoTorneio}) async {
    final querySnapshot = await _database
        .collection('torneios')
        .where('nomeTorneio', isEqualTo: nomeDoTorneio)
        .get();

    if(querySnapshot.docs.isNotEmpty) {
      final torneio = querySnapshot.docs.first.data();
      return torneio["senha"];
    }

    return null;
  }

  Future<Tournament?> loadFromBd({required String nomeDoTorneio}) async {
    try {
      final querySnapshot = await _database
          .collection('torneios')
          .where('nomeTorneio', isEqualTo: nomeDoTorneio)
          .get();

      if(querySnapshot.docs.isNotEmpty) {
        final torneio = querySnapshot.docs.first.data();
        return Tournament.fromJson(torneio);
      }

      return null;
    }catch(e, stack) {
      log('Não foi possivel carergar o torneio pelo nome $e', stackTrace: stack);
      return null;
    }
  }

  Future<String?> addTorneio({required Tournament torneio}) async {
    try{
      final torneioJson = torneio.toJson();
      final ref = await _database.collection('torneios').add(torneioJson);
      await updateTorneioData({"id": ref.id}, ref.id);
      return ref.id;
    }catch(e, stack) {
      log('NAO FOI POSSIVEL ADICIONAR O TORNEIO $e', stackTrace: stack);
      return null;
    }
  }
}