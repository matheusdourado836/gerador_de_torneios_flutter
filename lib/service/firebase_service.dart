import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:volleyball_tournament_app/model/player.dart';

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
}