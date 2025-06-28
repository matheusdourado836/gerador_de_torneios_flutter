import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'package:volleyball_tournament_app/service/firebase_service.dart';
import '../model/partida.dart';
import '../model/tournament.dart';

class DataController extends ChangeNotifier {
  static final FirebaseService _service = FirebaseService();

  List<Player> players = [];
  Tournament? tournament;
  List<List<Player>> listaDeCombinacoes = [];
  List<Partida> partidas = [];
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

  Future<void> insertSingle(String key, Map<String, dynamic> value, String id) async {
    return await _service.insertSingle(key, value, id);
  }

  Future<void> removeSingle(String key, Map<String, dynamic> value, String id) async {
    return await _service.removeSingle(key, value, id);
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

  Future<bool> checkIfUserIsAlreadyLoggedIn(String tournamentName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString('admin')?.isEmpty ?? true) {
      return false;
    }

    return await checkPass(nomeDoTorneio: tournamentName, userPass: prefs.getString('admin')!);
  }

  Future<bool> checkPass({required String nomeDoTorneio, required String userPass}) async {
    final pass = await _service.getPass(nomeDoTorneio: nomeDoTorneio);

    return pass == userPass;
  }

  Future<bool> checkIfIsActive({required String nomeDoTorneio}) async {
    return await _service.getActive(nomeDoTorneio: nomeDoTorneio);
  }

  Future<String> gerarCodigoTorneio() async {
    return await _service.gerarCodigoTorneio();
  }

  Future<Map<String, dynamic>?> getTorneioByCode({required String code}) async {
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
        tournament?.jogadores ??= [];
      }else {
        tournament?.jogadores ??= [];
        loading = false;
        notifyListeners();
      }
    }catch(e, stack) {
      log('ERRO AO CARREGAR TORNEIO $e', stackTrace: stack);
    }
  }

  Future<void> loadFromBd({required String nomeDoTorneio}) async {
    loading = true;
    notifyListeners();
    tournament = await _service.loadFromBd(nomeDoTorneio: nomeDoTorneio);
    loading = false;
    notifyListeners();
    return;
  }

  Future<void> getClassifiedPlayers() async {
    tournament!.timesClassificados =  await _service.getClassifiedPlayers(torneioId: tournament!.id!);
  }

  Future<void> resetClassifiedTeams({required String torneioId}) async => await _service.resetClassifiedTeams(torneioId: torneioId);

  Future<void> addToClassifiedTeams({required List<Player> players}) async {
    return await _service.addToClassifiedTeams(torneioId: tournament!.id!, players: players);
  }

  Future<void> disqualifyTeam({required List<Player> players}) async {
    return await _service.disqualifyTeam(torneioId: tournament!.id!, players: players);
  }

  Future<void> cancelarTorneio({required String nomeDoTorneio}) async {
    final prefs = await SharedPreferences.getInstance();
    final torneiosSalvos = prefs.getString('torneios') ?? '{}';
    final Map<String, dynamic> torneiosMap = json.decode(torneiosSalvos) as Map<String, dynamic>;
    if(torneiosMap.isNotEmpty && torneiosMap[nomeDoTorneio].isNotEmpty) {
      torneiosMap[nomeDoTorneio] = '';
      prefs.setString('torneios', jsonEncode(torneiosMap));
    }
    updateTorneioData({"ativo": false}, tournament!.id!);

    return;
  }

  void updatePlayerGames(List<Player> team, List<Player> players) {
    for (var player in team) {
      final playerFromList = players.firstWhere((p) => p.nome == player.nome);
      playerFromList.jogosFinalizados = (playerFromList.jogosFinalizados ?? 0) + 1;
    }
  }

  List<List<Player>> generate4x4Combinations({bool misto = false}) {
    listaDeCombinacoes = [];
    List<Player> players = tournament!.jogadores!;

    List<Player> males = players.where((p) => p.sex == 0).toList();
    List<Player> females = players.where((p) => p.sex == 1).toList();

    if (females.length > males.length * 2) {
      throw Exception("Impossível formar times com no máximo 2 mulheres por time.");
    }

    for(Player player in players) {
      player.totalJogos = 0;
    }

    // Rotacionar jogadores para formar times
    while (players.any((p) => (p.totalJogos ?? 0) < 3)) {
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
        if (team.every((player) => (player.totalJogos ?? 0) < 3)) {
          // Atualizar a contagem de jogos dos jogadores
          for (var player in team) {
            player.totalJogos = (player.totalJogos ?? 0) + 1;
          }
          listaDeCombinacoes.add(team);

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

    for(Player player in players) {
      player.totalJogos = 0;
    }

    return listaDeCombinacoes;
  }

  void generate2x2Combinations() {
    listaDeCombinacoes = [];
    List<Player> players = tournament?.jogadores ?? [];
    bool misto = tournament?.misto ?? false;

    Set<String> generatedPairs = {};

    if (misto) {
      List<Player> males = players.where((p) => p.sex == 0).toList();
      List<Player> females = players.where((p) => p.sex == 1).toList();

      for (var male in males) {
        for (var female in females) {
          List<String> sortedNames = [male.nome!, female.nome!]..sort();
          String pairKey = '${sortedNames[0]}-${sortedNames[1]}';
          if (!generatedPairs.contains(pairKey)) {
            listaDeCombinacoes.add([male, female]);
            generatedPairs.add(pairKey);
          }
        }
      }
    } else {
      for (int i = 0; i < players.length; i++) {
        for (int j = i + 1; j < players.length; j++) {
          Player p1 = players[i];
          Player p2 = players[j];

          String pairKey = '${(p1.nome ?? '').trim().toLowerCase()}-${(p2.nome ?? '').trim().toLowerCase()}';
          String pairKeyReversed = '${(p2.nome ?? '').trim().toLowerCase()}-${(p1.nome ?? '').trim().toLowerCase()}';
          if (!generatedPairs.contains(pairKey) && !generatedPairs.contains(pairKeyReversed)) {
            listaDeCombinacoes.add([p1, p2]);
            generatedPairs.add(pairKey);
            generatedPairs.add(pairKeyReversed);
          }
        }
      }
    }

    // Ordenar internamente cada dupla
    listaDeCombinacoes = listaDeCombinacoes.map((dupla) {
      dupla.sort((a, b) => a.nome!.compareTo(b.nome!));
      return dupla;
    }).toList();

    // Ordenar a lista de duplas
    listaDeCombinacoes.sort((a, b) {
      final nomeA = '${a[0].nome}${a[1].nome}';
      final nomeB = '${b[0].nome}${b[1].nome}';
      return nomeA.compareTo(nomeB);
    });

    // final mapa = getMapaDeDuplasComoLista();
    // final resultado = verificarDuplasIncompletas(mapa, tournament!.jogadores!);
  }

  Map<String, Set<String>> getMapaDeDuplas() {
    Map<String, Set<String>> mapa = {};

    for (var dupla in listaDeCombinacoes) {
      final jogador1 = dupla[0].nome!;
      final jogador2 = dupla[1].nome!;

      mapa.putIfAbsent(jogador1, () => {});
      mapa.putIfAbsent(jogador2, () => {});

      mapa[jogador1]!.add(jogador2);
      mapa[jogador2]!.add(jogador1);
    }

    return mapa;
  }

  Map<String, List<String>> getMapaDeDuplasComoLista() {
    final mapa = getMapaDeDuplas();
    mapa["Bia"]!.remove('Dani');
    return mapa.map((key, value) => MapEntry(key, value.toList()..sort()));
  }

  void generateMatches() {
    partidas = [];
    listaDeCombinacoes.shuffle();

    Set<String> duplasUsadas = {};

    for (int i = 0; i < listaDeCombinacoes.length; i++) {
      final duplaA = listaDeCombinacoes[i];
      final keyA = _duplaKey(duplaA);
      if (duplasUsadas.contains(keyA)) continue;

      for (int j = i + 1; j < listaDeCombinacoes.length; j++) {
        final duplaB = listaDeCombinacoes[j];
        final keyB = _duplaKey(duplaB);
        if (duplasUsadas.contains(keyB)) continue;

        // Verifica se há jogadores repetidos entre as duas duplas
        final jogadoresA = duplaA.map((p) => p.nome!.trim().toLowerCase()).toSet();
        final jogadoresB = duplaB.map((p) => p.nome!.trim().toLowerCase()).toSet();

        if (jogadoresA.intersection(jogadoresB).isNotEmpty) continue;

        // Marca duplas como usadas
        duplasUsadas.add(keyA);
        duplasUsadas.add(keyB);

        // Cria partida
        partidas.add(Partida(team1: duplaA, team2: duplaB));
        break; // segue para a próxima duplaA
      }
    }

    // Atualiza o total de jogos dos jogadores
    for (var partida in partidas) {
      for (var player in [...partida.team1!, ...partida.team2!]) {
        player.totalJogos = (player.totalJogos ?? 0) + 1;
      }
    }
  }

  Map<String, List<String>> verificarDuplasIncompletas(
      Map<String, List<String>> mapaDeDuplas, List<Player> todosJogadores) {

    // Cria um set com o nome de todos os jogadores
    final todosOsNomes = todosJogadores.map((p) => p.nome!).toSet();

    Map<String, List<String>> jogadoresFaltando = {};

    for (final entry in mapaDeDuplas.entries) {
      final jogador = entry.key;
      final parceiros = entry.value.toSet();

      // Remove o próprio jogador da lista de comparação
      final esperado = Set<String>.from(todosOsNomes)..remove(jogador);

      // Verifica quem está faltando
      final faltando = esperado.difference(parceiros);

      if (faltando.isNotEmpty) {
        jogadoresFaltando[jogador] = faltando.toList()..sort();
      }
    }

    return jogadoresFaltando;
  }

  String _duplaKey(List<Player> dupla) {
    final nomes = dupla.map((p) => p.nome!.trim().toLowerCase()).toList()..sort();
    return nomes.join(',');
  }


  Partida generateRandom2x2Match(List<Player> jogadores) {
    Partida partida = Partida();
    List<Player> team1 = [];
    List<Player> team2 = [];
    if(tournament?.misto ?? false) {
      // Ordenar os jogadores por total de jogos, priorizando os com menos jogos
      List<Player> males = jogadores.where((player) => player.sex == 0).toList();
      List<Player> females = jogadores.where((player) => player.sex == 1).toList();
      List<List<Player>> allMatches = [...partidas.map((p) => p.team1!), ...partidas.map((p) => p.team2!)];

      males.sort((a, b) => (a.totalJogos ?? 0).compareTo(b.totalJogos ?? 0));
      females.sort((a, b) => (a.totalJogos ?? 0).compareTo(b.totalJogos ?? 0));


      final firstMale = males.first;
      males.shuffle();
      final randomMale = males[Random().nextInt(males.length)];

      final firstFemale = females.first;
      females.shuffle();
      final randomFemale = females[Random().nextInt(females.length)];

      team1.add(firstMale);
      team1.add(randomFemale);

      team2.add(randomMale);
      team2.add(firstFemale);
    }else {
      Player shuffleList(List<Player> list) {
        list.shuffle();
        return list.removeAt(Random().nextInt(list.length));
      }
      final tempList = List<Player>.from(jogadores);
      final p1 = shuffleList(tempList);
      final p2 = shuffleList(tempList);
      final p3 = shuffleList(tempList);
      final p4 = shuffleList(tempList);

      team1.addAll([p1, p2]);
      team2.addAll([p3, p4]);
    }

    partida = Partida(team1: team1, team2: team2);

    return partida;
  }

  Partida generateRandomMatch() {
    // Ordenar jogadores por quantidade de jogos (priorizando os que jogaram menos)
    List<Player> sortedPlayers = players.toList()
      ..sort((a, b) => a.totalJogos!.compareTo(b.totalJogos!));

    // Selecionar os times
    List<Player> team1 = [];
    List<Player> team2 = [];
    List<Player> remainingPlayers = sortedPlayers.toList();

    // Função auxiliar para adicionar jogadores ao time com as regras
    void addPlayerToTeam(List<Player> team, Player player) {
      team.add(player);
      remainingPlayers.remove(player);
    }

    // Adicionar mulheres a ambos os times
    List<Player> women = remainingPlayers.where((p) => p.sex == 1).toList();
    if (women.length >= 2) {
      addPlayerToTeam(team1, women.removeAt(0));
      addPlayerToTeam(team2, women.removeAt(0));
    } else {
      throw Exception("Não há mulheres suficientes para formar dois times.");
    }

    // Completar os times com jogadores restantes, respeitando o limite de duas mulheres
    while (team1.length < 4) {
      Player nextPlayer = remainingPlayers.firstWhere(
            (p) => !team1.contains(p) && team1.where((t) => t.sex == 1).length < 2,
        orElse: () => remainingPlayers.first,
      );
      addPlayerToTeam(team1, nextPlayer);
    }

    while (team2.length < 4) {
      Player nextPlayer = remainingPlayers.firstWhere(
            (p) =>
        !team2.contains(p) && team2.where((t) => t.sex == 1).length < 2,
        orElse: () => remainingPlayers.first,
      );
      addPlayerToTeam(team2, nextPlayer);
    }

    for(Player player in [...team1, ...team2]) {
      player.totalJogos = player.totalJogos! + 1;
    }

    return Partida(team1: team1, team2: team2);
  }

  Future<Partida?> addRoundManually(BuildContext context, {List<Player>? jogadoresDisponiveis}) {
    return showDialog<Partida>(
      context: context,
      builder: (context) {
        final flag = ValueNotifier(false);
        final jogadores = jogadoresDisponiveis ?? tournament!.jogadores!;
        final playersNames = jogadores.map((p) => p.nome!).toList();
        final playersBySide = int.parse(tournament!.qtdJogadoresEmCampo!.split('x')[0]);
        final partida = Partida();
        final team1Selection = List<String?>.filled(playersBySide, null);
        final team2Selection = List<String?>.filled(playersBySide, null);

        Widget buildTeamDropdowns(List<String?> teamSelection, String teamLabel) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(teamLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              for (var i = 0; i < playersBySide; i++)
                DropdownButton<String>(
                  value: teamSelection[i],
                  isExpanded: true,
                  items: playersNames.map((player) {
                    final playerData = jogadores.firstWhere((p) => p.nome == player);
                    return DropdownMenuItem(
                      value: player,
                      child: Text('$player - ${playerData.jogosFinalizados ?? 0} jogos'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    teamSelection[i] = newValue;
                    flag.value = !flag.value;
                  },
                ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Adicionar Partida'),
          content: ValueListenableBuilder(
            valueListenable: flag,
            builder: (context, _, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTeamDropdowns(team1Selection, 'TIME A'),
                  const SizedBox(height: 16),
                  buildTeamDropdowns(team2Selection, 'TIME B'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (team1Selection.nonNulls.length == playersBySide &&
                    team2Selection.nonNulls.length == playersBySide) {
                  partida.team1 = team1Selection.nonNulls
                      .map((name) => jogadores.firstWhere((p) => p.nome == name))
                      .toList();
                  partida.team2 = team2Selection.nonNulls
                      .map((name) => jogadores.firstWhere((p) => p.nome == name))
                      .toList();
                  Navigator.pop(context, partida); // ✅ retorna a partida criada
                }
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () {
                final randomPartida = playersBySide == 2
                    ? generateRandom2x2Match(jogadores)
                    : generateRandomMatch();
                Navigator.pop(context, randomPartida); // ✅ retorna a aleatória
              },
              child: const Text('Gerar partida aleatória'),
            ),
          ],
        );
      },
    );
  }
}