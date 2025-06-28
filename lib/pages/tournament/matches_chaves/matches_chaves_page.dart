import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/pages/tournament/matches_chaves/widgets/add_player_to_key_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/matches_chaves/widgets/edit_key_team_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/matches_chaves/widgets/finals_widget.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/check_admin_dialog.dart';
import '../../../controller/data_controller.dart';
import '../../../model/partida.dart';
import '../../../model/player.dart';
import '../widgets/edit_player_dialog.dart';
import '../widgets/edit_players_dialog.dart';
import '../widgets/remove_match_dialog.dart';
import '../widgets/remove_player_dialog.dart';
import '../widgets/set_winner_dialog.dart';

class MatchesChavesPage extends StatefulWidget {
  final String tournamentName;
  const MatchesChavesPage({super.key, required this.tournamentName});

  @override
  State<MatchesChavesPage> createState() => _MatchesChavesPageState();
}

class _MatchesChavesPageState extends State<MatchesChavesPage> with SingleTickerProviderStateMixin {
  late final PageController _chavesController = PageController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  late final TabController _tabController = TabController(length: 5, vsync: this);
  String _selectedSort = '';
  List<Player> players = [];
  List<Partida> partidasFiltradas = [];
  List<List<Partida>> partidasByKey = [];
  List<Partida> partidasHistory = [];
  int currentKey = 0;
  int _playersPerTeam = 0;
  bool? _admin;
  bool _nameSort = false;
  bool _gamesSort = false;
  bool _pointsSort = false;
  bool _mediaSort = false;
  bool _loading = false;

  List<Partida> createMatchesForKeys() {
    final key = dataProvider.tournament!.chaves![currentKey];

    List<Partida> keyMatches = [];

    // Gerar combinações de partidas para todos os times da chave
    for (int i = 0; i < key.times.values.length; i++) {
      for (int j = i + 1; j < key.times.values.length; j++) {
        final team1 = key.times.values.toList()[i];
        final team2 = key.times.values.toList()[j];
        keyMatches.add(Partida(team1: team1, team2: team2));
      }
    }

    return keyMatches;
  }

  void startGames() {
    setState(() {
      partidasByKey[currentKey] = createMatchesForKeys();
      partidasFiltradas = partidasByKey[currentKey];
    });
    saveData(setPlayers: false, setKeys: false);
  }

  Future<void> saveData({bool setPlayers = true, bool setMatches = true, bool setKeys = true}) async {
    if(setPlayers) {
      final playersJson = dataProvider.tournament!.jogadores!.map((jogador) => jogador.toJson()).toList();
      await dataProvider.updateTorneioData({"jogadores": playersJson}, dataProvider.tournament!.id!);
    }
    if(setMatches) {
      for(var partidaChave in getChavesOrdenadas(dataProvider.tournament!.partidasChave)) {
        final index = int.parse(partidaChave.key);
        partidaChave.value.partidas = partidasByKey[index];
      }

      final partidasChaveMap = dataProvider.tournament!.partidasChave?.map((key, value) => MapEntry(key, value.toJson()));

      await dataProvider.updateTorneioData({"partidasChave": partidasChaveMap}, dataProvider.tournament!.id!);
    }
    if(setKeys) {
      final keysJson = dataProvider.tournament!.chaves?.map((key) => key.toJson()).toList();
      await dataProvider.updateTorneioData({"chaves": keysJson}, dataProvider.tournament!.id!);
    }
  }

  List<MapEntry<String, PartidaChave>> getChavesOrdenadas(Map<String, PartidaChave>? chaves) {
    if (chaves == null) return [];
    final entries = chaves.entries.toList();
    entries.sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    return entries;
  }

  Future<void> loadTournamentFromBd() async {
    dataProvider.carregarTorneio(widget.tournamentName).whenComplete(() {
      if(dataProvider.tournament == null) {
        GoRouter.of(context).go('/');
        return;
      }
      _playersPerTeam = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
      for(int i = 0; i < dataProvider.tournament!.chaves!.length; i++) {
        partidasByKey.add([]);
      }
      setPlayers();
      for(var partidaChave in getChavesOrdenadas(dataProvider.tournament!.partidasChave)) {
        final index = int.parse(partidaChave.key);
        partidasByKey[index].addAll(partidaChave.value.partidas ?? []);
      }
      partidasFiltradas = partidasByKey[currentKey];
      partidasHistory = partidasByKey[currentKey].where((partida) => partida.finished == true).toList();
      setState(() {});
    });
  }

  Future<void> simulateResults() async {
    setState(() => _loading = true);
    for(Partida partida in partidasByKey[currentKey]) {
      final vencedor = Random().nextInt(2);
      setState(() {
        partida.vencedor = vencedor;
        partida.finished = true;
        for(Player player in partida.team1!) {
          final playerInList = getKeyPlayer(player);
          final playerTournament = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
          playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) + 1;
          playerTournament.jogosFinalizados = (playerTournament.jogosFinalizados ?? 0) + 1;
          if(vencedor == 0) {
            playerTournament.pontosAtuais = (playerTournament.pontosAtuais ?? 0) + 1;
            playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
          }
        }
        for(Player player in partida.team2!) {
          final playerInList = getKeyPlayer(player);
          final playerTournament = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
          playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) + 1;
          playerTournament.jogosFinalizados = (playerTournament.jogosFinalizados ?? 0) + 1;
          if(vencedor == 1) {
            playerTournament.pontosAtuais = (playerTournament.pontosAtuais ?? 0) + 1;
            playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
          }
        }
        partidasHistory.add(partida);
      });
    }
    await saveData(setKeys: false);
    setState(() => _loading = false);
  }

  Future<void> resetMatches() async {
    setState(() {
      for(Partida partida in partidasByKey[currentKey]) {
        partida.vencedor = null;
        partida.finished = null;
        for(Player player in [...partida.team1!, ...partida.team2!]) {
          final playerTournament = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
          final playerInList = getKeyPlayer(player);
          playerInList.pontosAtuais = 0;
          playerInList.jogosFinalizados = 0;
          playerTournament.pontosAtuais = 0;
          playerTournament.jogosFinalizados = 0;
        }
      }
      partidasHistory = [];
    });
    await saveData(setKeys: false);
  }

  void excluirPartidas() {
    for(Partida partida in partidasByKey[currentKey]) {
      for(Player player in [...partida.team1 ?? [], ...partida.team2 ?? []]) {
        final playerInList = getKeyPlayer(player);
        final tournamentPlayerInList = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
        playerInList.pontosAtuais = 0;
        playerInList.jogosFinalizados = 0;
        tournamentPlayerInList.pontosAtuais = 0;
        tournamentPlayerInList.jogosFinalizados = 0;
      }
    }
    setState(() {
      partidasByKey[currentKey] = [];
    });
    saveData(setKeys: false);
  }

  Player getKeyPlayer(Player player) {
    Player matchPlayer = players.firstWhere((p) => p.id == player.id, orElse: () => Player());
    if(matchPlayer.id == null) {
      matchPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id, orElse: () => Player());
    }

    return matchPlayer.id != null ? matchPlayer : player;
  }

  void setPlayers() {
    final keyTeams = dataProvider.tournament!.chaves![currentKey].times.values.toList();
    final keyTeamsIds = keyTeams.map((t) => t.map((p) => p.id!).toList()).toList().expand((element) => element).toList();
    players = dataProvider.tournament!.jogadores!.where((p) => keyTeamsIds.contains(p.id)).toList();
  }

  Widget _buildSortableHeader({
    required String label,
    required bool isActive,
    required bool ascending,
    required double width,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isActive ? Colors.blue : null,
              ),
            ),
            if (isActive)
              Icon(
                ascending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  Widget appBarTitle() {
    if(partidasByKey.isEmpty) {
      return const Text('Fase classificatória');
    }else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _chavesController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
            icon: const Icon(Icons.arrow_back_ios_new_rounded)
          ),
          Text('${dataProvider.tournament!.chaves![currentKey].nome}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            onPressed: () => _chavesController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
            icon: const Icon(Icons.arrow_forward_ios_rounded)
          ),
        ],
      );
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dataProvider.checkIfUserIsAlreadyLoggedIn(widget.tournamentName).then((res) {
        if(res) {
          _admin = true;
          loadTournamentFromBd();
        }else {
          showDialog(context: context, barrierDismissible: false, builder: (context) => CheckAdminDialog(tournamentName: widget.tournamentName,)).then((res) {
            _admin = res;
            loadTournamentFromBd();
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: dataProvider.tournament == null ? null : AppBar(
        centerTitle: true,
        title: appBarTitle(),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home),
        ),
        actions: [
          if(_admin ?? false)
            IconButton(
                onPressed: () => context.go(context.namedLocation(
                  'settings',
                  pathParameters: {"nomeDoTorneio": widget.tournamentName},
                  queryParameters: {"m": "keys"}
                )),
                icon: const Icon(Icons.settings)
            )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Consumer<DataController>(
            builder: (context, value, _) {
              if(value.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if(value.tournament == null || _admin == null) {
                return const Center(
                  child: Text('AGUARDANDO ADMINISTRADOR INICIAR O TORNEIO'),
                );
              }

              if(partidasByKey.isEmpty && _admin == true) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => startGames(),
                        child: const Text('Gerar times')
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          dataProvider.addRoundManually(context, jogadoresDisponiveis: players).then((partida) {
                            if(partida == null) return;
                            final team1Id = const Uuid().v4();
                            final team2Id = const Uuid().v4();
                            setState(() {
                              for (var player in partida.team1!) {
                                final matchPlayer = getKeyPlayer(player);
                                final matchTournamentPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
                                matchPlayer.teamId = team1Id;
                                matchTournamentPlayer.teamId = team1Id;
                              }
                              for (var player in partida.team2!) {
                                final matchPlayer = getKeyPlayer(player);
                                final matchTournamentPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
                                matchPlayer.teamId = team2Id;
                                matchTournamentPlayer.teamId = team2Id;
                              }
                              final qtdTimes = dataProvider.tournament!.chaves![currentKey].times.length;
                              dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 1}"] = partida.team1!;
                              dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 2}"] = partida.team2!;
                              partidasByKey[currentKey].insert(partidasByKey[currentKey].length, partida);
                            });
                            saveData();
                          });
                        },
                        child: const Text('Adicionar manualmente')
                      )
                    ],
                  ),
                );
              }

              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: PageView.builder(
                  controller: _chavesController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: partidasByKey.length,
                  onPageChanged: (page) {
                    setState(() {
                      currentKey = page;
                      partidasFiltradas = partidasByKey[currentKey];
                      partidasHistory = partidasByKey[currentKey].where((p) => p.finished == true).toList();
                      setPlayers();
                      _tabController.animateTo(0);
                    });
                  },
                  itemBuilder: (context, index) {
                    if(partidasByKey[currentKey].isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => startGames(),
                            child: const Text('Gerar times')
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              dataProvider.addRoundManually(context, jogadoresDisponiveis: players).then((partida) {
                                if(partida == null) return;
                                final team1Id = const Uuid().v4();
                                final team2Id = const Uuid().v4();
                                setState(() {
                                  for (var player in partida.team1!) {
                                    final matchPlayer = getKeyPlayer(player);
                                    final matchTournamentPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
                                    matchPlayer.teamId = team1Id;
                                    matchTournamentPlayer.teamId = team1Id;
                                  }
                                  for (var player in partida.team2!) {
                                    final matchPlayer = getKeyPlayer(player);
                                    final matchTournamentPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
                                    matchPlayer.teamId = team2Id;
                                    matchTournamentPlayer.teamId = team2Id;
                                  }
                                  final qtdTimes = dataProvider.tournament!.chaves![currentKey].times.length;
                                  dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 1}"] = partida.team1!;
                                  dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 2}"] = partida.team2!;
                                  partidasByKey[currentKey].insert(partidasByKey[currentKey].length, partida);
                                });
                                saveData();
                              });
                            },
                            child: const Text('Adicionar manualmente')
                          )
                        ],
                      );
                    }
                    return Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          dividerHeight: 0,
                          tabs: [
                            Tab(text: 'Jogadores ${players.length}'),
                            const Tab(text: 'Chaves'),
                            Tab(text: 'Partidas ${partidasByKey[currentKey].length}'),
                            const Tab(text: 'Histórico'),
                            const Tab(text: 'Classificações'),
                          ],
                          tabAlignment: TabAlignment.fill,
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                SingleChildScrollView(
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: 900),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildSortableHeader(
                                                label: 'Nome',
                                                ascending: _nameSort,
                                                isActive: _selectedSort == 'name',
                                                width: 250,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedSort = 'name';
                                                    _nameSort = !_nameSort;
                                                    players.sort((a, b) => _nameSort
                                                      ? a.nome!.compareTo(b.nome!)
                                                      : b.nome!.compareTo(a.nome!)
                                                    );
                                                  });
                                                },
                                              ),
                                              _buildSortableHeader(
                                                label: 'Jogos',
                                                ascending: _gamesSort,
                                                isActive: _selectedSort == 'games',
                                                width: 80,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedSort = 'games';
                                                    _gamesSort = !_gamesSort;
                                                    players.sort((a, b) => _gamesSort
                                                        ? (a.jogosFinalizados ?? 0)
                                                        .compareTo(b.jogosFinalizados ?? 0)
                                                        : (b.jogosFinalizados ?? 0)
                                                        .compareTo(a.jogosFinalizados ?? 0));
                                                  });
                                                },
                                              ),
                                              _buildSortableHeader(
                                                label: 'Pontos',
                                                ascending: _pointsSort,
                                                isActive: _selectedSort == 'points',
                                                width: 80,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedSort = 'points';
                                                    _pointsSort = !_pointsSort;
                                                    players.sort((a, b) => _pointsSort
                                                        ? (a.pontosAtuais ?? 0)
                                                        .compareTo(b.pontosAtuais ?? 0)
                                                        : (b.pontosAtuais ?? 0)
                                                        .compareTo(a.pontosAtuais ?? 0));
                                                  });
                                                },
                                              ),
                                              _buildSortableHeader(
                                                label: 'Média',
                                                ascending: _mediaSort,
                                                isActive: _selectedSort == 'media',
                                                width: 80,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedSort = 'media';
                                                    _mediaSort = !_mediaSort;
                                                    players.sort((a, b) {
                                                      final mediaA = (a.pontosAtuais ?? 0) / (a.jogosFinalizados ?? 1);
                                                      final mediaB = (b.pontosAtuais ?? 0) / (b.jogosFinalizados ?? 1);
                                                      return _mediaSort ? mediaA.compareTo(mediaB) : mediaB.compareTo(mediaA);
                                                    });
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const Divider(thickness: 1),
                                          Column(
                                            children: players.map((player) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Nome + ações de admin
                                                    SizedBox(
                                                      width: 250,
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              player.nome!,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(fontSize: 18),
                                                            ),
                                                          ),
                                                          if (_admin == true) ...[
                                                            IconButton(
                                                              icon: const Icon(Icons.edit),
                                                              onPressed: () async {
                                                                final matchPlayer = dataProvider.tournament!.jogadores!
                                                                    .firstWhere((p) => p.id == player.id);
                                                                final res = await showDialog(
                                                                  context: context,
                                                                  builder: (context) => EditPlayerDialog(player: matchPlayer),
                                                                );
                                                                if (res is Player) {
                                                                  setState(() {});
                                                                  saveData(setMatches: false, setKeys: false);
                                                                }
                                                              },
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete),
                                                              onPressed: () async {
                                                                final confirm = await showDialog(
                                                                  context: context,
                                                                  builder: (context) => RemovePlayerTournamentDialog(player: player),
                                                                );
                                                                if (confirm == true) {
                                                                  setState(() {
                                                                    players.remove(player);
                                                                  });
                                                                  dataProvider.removeSingle(
                                                                      'jogadores', player.toJson(), dataProvider.tournament!.id!);
                                                                  for (Chave chave in dataProvider.tournament!.chaves ?? []) {
                                                                    for (List<Player> times in chave.times.values) {
                                                                      times.removeWhere((p) => p.id == player.id);
                                                                    }
                                                                  }
                                                                  for (Partida partida in partidasByKey[currentKey]) {
                                                                    partida.team1?.removeWhere((p) => p.id == player.id);
                                                                    partida.team2?.removeWhere((p) => p.id == player.id);
                                                                  }
                                                                  saveData(setPlayers: false);
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 80,
                                                      child: Text(
                                                        '${player.jogosFinalizados ?? 0}',
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontSize: 16),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 80,
                                                      child: Text(
                                                        '${player.pontosAtuais ?? 0}',
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 80,
                                                      child: Text(
                                                        ((player.pontosAtuais ?? 0) / (player.jogosFinalizados ?? 1)).toStringAsFixed(2),
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontSize: 16),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: SizedBox(
                                    width: constraints.maxWidth * .7,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        for(var i = 0; i < dataProvider.tournament!.chaves!.length; i++)
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(dataProvider.tournament!.chaves![i].nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
                                                  if(_admin == true)
                                                    IconButton(
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (context) => AddPlayerToKeyDialog(
                                                        existingTeams: dataProvider.tournament!.chaves![i].times.values.toList(),
                                                        selectedKey: dataProvider.tournament!.chaves![i],
                                                      )
                                                    ).then((result) {
                                                      if (result != null) {
                                                        final Player jogador = result['player'];
                                                        final dynamic destino = result['team'];

                                                        if (destino == 'new_team') {
                                                          final qtdTimes = dataProvider.tournament!.chaves![i].times.length;
                                                          dataProvider.tournament!.chaves![i].times['time${qtdTimes + 1}'] = [jogador];
                                                        } else if (destino is List<Player>) {
                                                          final matchTeam = dataProvider.tournament!.chaves![i].times.values.toList().firstWhere((team) => team.where((p) => p.teamId == jogador.teamId).isNotEmpty);
                                                          matchTeam.add(jogador);
                                                        }
                                                        setPlayers();
                                                        saveData(setPlayers: false, setMatches: false);
                                                        setState(() {});
                                                      }
                                                    }),
                                                    icon: const Icon(Icons.add)
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: 200,
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: dataProvider.tournament?.chaves?[i].times.entries.toList().length ?? 0,
                                                  itemBuilder: (context, index) {
                                                    final times = dataProvider.tournament?.chaves![i].times.entries.toList()[index];
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 16.0),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              children: times!.value.map((player) => Text(player.nome!, textAlign: TextAlign.center,)).toList(),
                                                            ),
                                                          ),
                                                          if(_admin == true)
                                                            IconButton(
                                                            onPressed: () {
                                                              showDialog<List<Player>>(
                                                                context: context,
                                                                builder: (context) {
                                                                  return EditKeyTeamDialog(
                                                                    jogadoresDisponiveis: dataProvider.tournament!.chaves![i].times.values.toList().expand((element) => element).toList(),
                                                                    jogadoresAtuais: times.value,
                                                                    playersPerTeam: _playersPerTeam,
                                                                  );
                                                                },
                                                              ).then((res) {
                                                                if(res is List<Player>) {
                                                                  setState(() {
                                                                    times.value.clear();
                                                                    times.value.addAll(res);
                                                                  });
                                                                  saveData();
                                                                }
                                                              });
                                                            },
                                                            icon: const Icon(Icons.edit)
                                                          ),
                                                          if(_admin == true)
                                                            IconButton(
                                                            onPressed: () {
                                                              showDialog(
                                                                context: context,
                                                                builder: (context) {
                                                                  return AlertDialog(
                                                                    title: const Text('Alerta'),
                                                                    content: const Text('Deseja realmete remover esse time da chave?'),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () => Navigator.pop(context, true),
                                                                        child: const Text('Sim')
                                                                      ),
                                                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Não')),
                                                                    ],
                                                                  );
                                                                },
                                                              ).then((res) {
                                                                if(res == true) {
                                                                  final key = times.key;
                                                                  dataProvider.tournament?.chaves![i].times.remove(key);
                                                                  //TODO FAZER UMA FUNCAO PARA REMOVER AS PARTIDAS NAO FINALIZADAS EM QUE ESSE TIME ESTA PRESENTE
                                                                  setPlayers();
                                                                  saveData(setPlayers: false, setMatches: false);
                                                                  setState(() {});
                                                                }
                                                              });
                                                            },
                                                            icon: const Icon(Icons.delete)
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
                                      ],
                                    ),
                                  )
                                ),
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Text(
                                          'Jogos finalizados: ${partidasByKey[currentKey].where((p) => p.finished == true).length}',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      SizedBox(
                                        width: constraints.maxWidth,
                                        height: constraints.maxHeight,
                                        child: Column(
                                          children: [
                                            if(partidasByKey[currentKey].isNotEmpty && _admin == true)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 16.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () => setState(() => partidasByKey[currentKey].shuffle(Random())),
                                                      label: const Text('Embaralhar partidas'),
                                                      icon: const Icon(Icons.shuffle),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    ElevatedButton.icon(
                                                      onPressed: () async {
                                                        final playersIds = players.map((p) => p.id!).toList();
                                                        final matchPlayers = dataProvider.tournament!.jogadores!.where((p) => playersIds.contains(p.id)).toList();
                                                        final partida = await dataProvider.addRoundManually(context, jogadoresDisponiveis: matchPlayers);
                                                        if(partida != null) {
                                                          setState(() => partidasByKey[currentKey].add(partida));
                                                          saveData(setKeys: false, setPlayers: false);
                                                        }
                                                      },
                                                      label: const Text('Adicionar partida'),
                                                      icon: const Icon(Icons.add),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    if(_loading)
                                                      Container(
                                                        width: 200,
                                                        height: 50,
                                                        alignment: Alignment.center,
                                                        child: SizedBox(
                                                            width: 35,
                                                            child: const CircularProgressIndicator()
                                                        ),
                                                      )
                                                    else
                                                      if(partidasByKey[currentKey].any((p) => p.finished == null))
                                                        ElevatedButton.icon(
                                                          onPressed: simulateResults,
                                                          label: const Text('Finalizar partidas'),
                                                          icon: const Icon(Icons.check),
                                                        ),
                                                    const SizedBox(width: 16),
                                                    ElevatedButton.icon(
                                                      onPressed: resetMatches,
                                                      label: const Text('Resetar partidas'),
                                                      icon: const Icon(Icons.restart_alt),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    ElevatedButton.icon(
                                                      onPressed: excluirPartidas,
                                                      label: const Text('Excluir partidas'),
                                                      icon: const Icon(Icons.delete),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Container(
                                              padding: const EdgeInsets.only(bottom: 16.0),
                                              width: constraints.maxWidth * .5,
                                              child: TextFormField(
                                                decoration: InputDecoration(
                                                  hintText: 'Pesquisar partida...',
                                                  enabledBorder: OutlineInputBorder(
                                                      borderSide: const BorderSide(color: Colors.grey),
                                                      borderRadius: BorderRadius.circular(8)
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                      borderSide: const BorderSide(color: Colors.grey),
                                                      borderRadius: BorderRadius.circular(8)
                                                  ),
                                                  prefixIcon: const Icon(Icons.search)
                                                ),
                                                onFieldSubmitted: (value) {
                                                  setState(() {
                                                    final query = value.trim().toLowerCase();
                                                    partidasFiltradas = partidasByKey[currentKey].where((partida) {
                                                      final team1Names = partida.team1?.map((t) => t.nome!.toLowerCase()) ?? [];
                                                      final team2Names = partida.team2?.map((t) => t.nome!.toLowerCase()) ?? [];
                                                      return team1Names.any((nome) => nome.contains(query)) ||
                                                          team2Names.any((nome) => nome.contains(query));
                                                    }).toList();
                                                  });
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              child: SizedBox(
                                                width: constraints.maxWidth * .7,
                                                height: constraints.maxHeight,
                                                child: ListView.separated(
                                                  itemCount: partidasFiltradas.length,
                                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                                  separatorBuilder: (context, index) => const Divider(),
                                                  itemBuilder: (context, index) {
                                                    final partida = partidasFiltradas[index];
                                                    final team1 = partida.team1;
                                                    final team2 = partida.team2;

                                                    return Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              Text('Jogo ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                              PartidaItem(
                                                                team1: team1!,
                                                                team2: team2!,
                                                                partida: partida,
                                                                playersPerTeam: _playersPerTeam,
                                                                admin: _admin,
                                                                onSave: () {
                                                                  setState(() {});
                                                                  saveData(setKeys: false, setPlayers: false);
                                                                },
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                        if(_admin == true)
                                                          Row(
                                                            children: [
                                                              if(partida.finished != true)
                                                                IconButton(
                                                                  onPressed: () {
                                                                    context.go(
                                                                      context.namedLocation(
                                                                        'match-score',
                                                                        pathParameters: {"nomeDoTorneio": widget.tournamentName},
                                                                        queryParameters: {"m": "keys"}
                                                                      ),
                                                                      extra: {"partida": partida}
                                                                    );
                                                                  },
                                                                  style: IconButton.styleFrom(
                                                                      backgroundColor: Colors.blue,
                                                                      foregroundColor: Colors.white,
                                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                                                                  ),
                                                                  icon: const Icon(Icons.play_arrow_rounded)
                                                                ),
                                                              const SizedBox(width: 8),
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  showDialog(
                                                                    context: context,
                                                                    builder: (context) => SetWinnerDialog(partida: partida, players: players)).then((res) {
                                                                      if(res != null) {
                                                                        setState(() {
                                                                          partidasHistory = partidasFiltradas.where((p) => p.finished == true).toList();
                                                                        });
                                                                        saveData(setKeys: false);
                                                                      }
                                                                    }
                                                                  );
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                                  fixedSize: const Size(118, 40),
                                                                  backgroundColor: partida.vencedor != null ? Colors.blue : const Color.fromRGBO(42, 35, 42, 1)
                                                                ),
                                                                child: partida.vencedor != null ? const Text('EDITAR') : const Text('FINALIZAR')
                                                              ),
                                                              const SizedBox(width: 8),
                                                              IconButton(
                                                                  onPressed: () => showDialog(
                                                                      context: context,
                                                                      builder: (context) => const RemoveMatchDialog()
                                                                  ).then((res) async {
                                                                    if(res == true) {
                                                                      final partida = partidasByKey[currentKey][index];
                                                                      setState(() {
                                                                        if(partida.finished == true) {
                                                                          final team1 = partida.team1;
                                                                          final team2 = partida.team2;
                                                                          for(var player in team1 ?? []) {
                                                                            final playerInList = getKeyPlayer(player);
                                                                            playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) - 1;
                                                                            if(partida.vencedor == 0) {
                                                                              playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) - 1;
                                                                            }
                                                                          }
                                                                          for(var player in team2 ?? []) {
                                                                            final playerInList = getKeyPlayer(player);
                                                                            playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) - 1;
                                                                            if(partida.vencedor == 1) {
                                                                              playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) - 1;
                                                                            }
                                                                          }
                                                                        }
                                                                        partidasByKey[currentKey].remove(partida);
                                                                      });
                                                                      await saveData(setKeys: false);
                                                                    }
                                                                  }),
                                                                  style: IconButton.styleFrom(
                                                                      backgroundColor: Colors.red,
                                                                      foregroundColor: Colors.white,
                                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                                                                  ),
                                                                  icon: const Icon(Icons.delete)
                                                              )
                                                            ],
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: Center(
                                    child: SizedBox(
                                      width: MediaQuery.sizeOf(context).width * .7,
                                      child: Column(
                                        children: [
                                          Text('Histórico de jogos', style: Theme.of(context).textTheme.titleLarge),
                                          const SizedBox(height: 16),
                                          for(var i = 0; i < partidasHistory.length; i++)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 16.0, left: 12, right: 12),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        width: 300,
                                                        height: 60,
                                                        child: Row(
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: partidasHistory[i].team1!.map((player) => Text(player.nome!, overflow: TextOverflow.clip,)).toList(),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            if(partidasHistory[i].vencedor == 0)
                                                              const Icon(FontAwesome5Solid.medal)
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        '${partidasHistory[i].pontos?.split('X')[0].trim() ?? ''} X ${partidasHistory[i].pontos?.split('X')[1].trim() ?? ''}',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                                      ),
                                                      SizedBox(
                                                        width: 300,
                                                        height: 60,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                          children: [
                                                            if(partidasHistory[i].vencedor == 1)
                                                              const Icon(FontAwesome5Solid.medal),
                                                            const SizedBox(width: 16),
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                              children: partidasHistory[i].team2!.map((player) => Text(player.nome!, overflow: TextOverflow.clip)).toList(),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Divider()
                                                ],
                                              ),
                                            ),
                                        ],
                                      )
                                    ),
                                  ),
                                ),
                                FinalsWidget(
                                  constraints: constraints,
                                  chave: dataProvider.tournament!.chaves![currentKey],
                                  admin: _admin ?? false
                                )
                              ]
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                )
              );
            },
          );
        }
      ),
    );
  }
}

class PartidaItem extends StatefulWidget {
  final List<Player> team1;
  final List<Player> team2;
  final Partida partida;
  final bool? admin;
  final int playersPerTeam;
  final Function() onSave;
  const PartidaItem({super.key, required this.team1, required this.team2, required this.partida, required this.admin, required this.playersPerTeam, required this.onSave});

  @override
  State<PartidaItem> createState() => _PartidaItemState();
}

class _PartidaItemState extends State<PartidaItem> {
  TextStyle style() {
    if(widget.partida.finished ?? false) {
      return const TextStyle(color: Colors.black54, fontSize: 16);
    }

    return const TextStyle(color: Colors.black, fontSize: 18);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 300,
          height: 60,
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.team1.map((p) => Text(p.nome ?? '', style: style())).toList(),
              ),
              if(widget.partida.vencedor == 0)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Icon(FontAwesome5Solid.medal),
                ),
              const SizedBox(width: 16),
              if(widget.admin == true)
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => EditPlayersDialog(
                      team: widget.team1,
                      otherTeam: widget.team2,
                      playersPerTeam: widget.playersPerTeam,
                    )
                  ).then((res) {
                    if(res == true) {
                      setState(() {});
                      widget.onSave();
                    }
                  }),
                  icon: const Icon(Icons.edit)
                ),
            ],
          ),
        ),
        Text(
            'X',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.partida.finished ?? false ? 18 : 20,
                color: widget.partida.finished ?? false ? Colors.black54 : Colors.black
            )
        ),
        SizedBox(
          width: 300,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if(widget.partida.vencedor == 1)
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Icon(FontAwesome5Solid.medal),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.team2.map((p) => Text(p.nome ?? '', style: style())).toList(),
              ),
              const SizedBox(width: 16),
              if(widget.admin == true)
                IconButton(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (context) => EditPlayersDialog(
                        team: widget.team2,
                        otherTeam: widget.team1,
                        playersPerTeam: widget.playersPerTeam,
                      )
                  ).then((res) {
                    if(res == true) {
                      setState(() {});
                      widget.onSave();
                    }
                  }),
                  icon: const Icon(Icons.edit)
                ),
            ],
          ),
        ),
      ],
    );
  }
}