import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/check_admin_dialog.dart';
import '../../../controller/data_controller.dart';
import '../../../model/partida.dart';
import '../../../model/player.dart';
import '../widgets/edit_players_dialog.dart';
import '../widgets/set_winner_mobile_dialog.dart';

class MatchesChavesMobilePage extends StatefulWidget {
  final String tournamentName;
  const MatchesChavesMobilePage({super.key, required this.tournamentName});

  @override
  State<MatchesChavesMobilePage> createState() => _MatchesChavesMobilePageState();
}

class _MatchesChavesMobilePageState extends State<MatchesChavesMobilePage> {
  final PageController _controller = PageController();
  final PageController _chavesController = PageController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  List<Player> players = [];
  List<Partida> partidas = [];
  List<List<Partida>> partidasByKey = [];
  List<Partida> partidasHistory = [];
  int playersBySide = 0;
  int currentRound = 0;
  int currentMatch = 0;
  int currentKey = 0;
  bool? _admin;

  List<List<Partida>> createMatchesForKeys() {
    List<List<Partida>> matches = [];

    for (var key in dataProvider.tournament!.chaves!) {
      List<Partida> keyMatches = [];

      // Gerar combinações de partidas para todos os times da chave
      for (int i = 0; i < key.times.values.length; i++) {
        for (int j = i + 1; j < key.times.values.length; j++) {
          final team1 = key.times.values.toList()[i];
          final team2 = key.times.values.toList()[j];
          for(Player player in [...team1, ...team2]) {
            player.totalJogos = (player.totalJogos ?? 0) + 1;
          }
          keyMatches.add(Partida(team1: team1, team2: team2));
        }
      }

      matches.add(keyMatches);
    }

    return matches;
  }

  void startGames() {
    partidas = [];
    setState(() {
      partidasByKey = createMatchesForKeys();
      partidas.shuffle(Random());
    });
    final Map<String, dynamic> partidasObj = {};
    for(var (index, chave) in dataProvider.tournament!.chaves!.indexed) {
      final nome = chave.nome!;
      partidasObj[nome] = partidasByKey[index].map((p) => p.toJson()).toList();
    }

    dataProvider.updateTorneioData({"partidasChave": partidasObj}, dataProvider.tournament!.id!);
  }

  void updatePlayerGames(List<Player> team) {
    final playersInKeys = dataProvider.tournament!.chaves![currentKey].times.values.toList();
    final matchPlayers = playersInKeys.firstWhere((players) => players == team);
    for (var player in matchPlayers) {
      final playerFromList = players.firstWhere((p) => p.nome == player.nome);
      playerFromList.jogosFinalizados = (playerFromList.jogosFinalizados ?? 0) + 1;
    }
    final playersJson = players.map((jogador) => jogador.toJson());
    setState(() => players);
    dataProvider.updateTorneioData({"jogadores": playersJson}, dataProvider.tournament!.id!);
  }

  void updatePlayerPoints(List<Player> team) {
    final playersInKeys = dataProvider.tournament!.chaves![currentKey].times.values.toList();
    final matchPlayers = playersInKeys.firstWhere((players) => players == team);
    for (var player in matchPlayers) {
      final playerFromList = players.firstWhere((p) => p.nome == player.nome);
      player.pontosAtuais = (player.pontosAtuais ?? 0) + 1;
      playerFromList.pontosAtuais = (playerFromList.pontosAtuais ?? 0) + 1;
    }
    final playersJson = players.map((jogador) => jogador.toJson());
    setState(() => players);
    dataProvider.updateTorneioData({"jogadores": playersJson}, dataProvider.tournament!.id!);
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

      final partidasChaveMap = dataProvider.tournament!.partidasChave!.map((key, value) => MapEntry(key, value.toJson()));

      await dataProvider.updateTorneioData({"partidasChave": partidasChaveMap}, dataProvider.tournament!.id!);
    }
    if(setKeys) {
      final keysJson = dataProvider.tournament!.chaves?.map((key) => key.toJson()).toList();
      await dataProvider.updateTorneioData({"chaves": keysJson}, dataProvider.tournament!.id!);
    }
  }

  Future<bool> checkIfUserIsAlreadyLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString('admin')?.isEmpty ?? true) {
      return false;
    }

    return await dataProvider.checkPass(nomeDoTorneio: widget.tournamentName, userPass: prefs.getString('admin')!);
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
      players = dataProvider.tournament!.jogadores ?? [];
      partidas = dataProvider.tournament!.partidas ?? [];
      for(var partidaChave in getChavesOrdenadas(dataProvider.tournament!.partidasChave)) {
        final index = int.parse(partidaChave.key);
        partidasByKey[index].addAll(partidaChave.value.partidas ?? []);
      }
      partidasHistory = dataProvider.tournament!.partidas?.where((partida) => partida.finished == true).toList() ?? [];
      playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
      setState(() {});
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkIfUserIsAlreadyLoggedIn().then((res) {
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

  Widget appBarTitle() {
    if(partidasByKey.isEmpty) {
      return const Text('Fase classificatória');
    }else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () => _chavesController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
              icon: const Icon(Icons.arrow_back_ios)
          ),
          Text('${dataProvider.tournament!.chaves![currentKey].nome}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          IconButton(
              onPressed: () => _chavesController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
              icon: const Icon(Icons.arrow_forward_ios)
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: dataProvider.tournament == null ? null : AppBar(
          centerTitle: true,
          title: appBarTitle(),
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
        body: Consumer<DataController>(
          builder: (context, value, _) {
            if(value.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if(value.tournament == null || _admin == null) {
              return const Center(
                child: SizedBox(
                  child: Text('AGUARDANDO ADMINISTRADOR INICIAR O TORNEIO'),
                ),
              );
            }

            return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        if(partidasByKey.isEmpty)
                          if(_admin ?? false)
                            SizedBox(
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
                                        dataProvider.addRoundManually(context).then((partida) {
                                          if(partida == null) return;
                                          final team1Id = const Uuid().v4();
                                          final team2Id = const Uuid().v4();
                                          setState(() {
                                            for (var player in partida.team1!) {
                                              final matchPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
                                              player.teamId = team1Id;
                                              matchPlayer.teamId = team1Id;
                                            }
                                            for (var player in partida.team2!) {
                                              final matchPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id);
                                              player.teamId = team2Id;
                                              matchPlayer.teamId = team2Id;
                                            }
                                            final qtdTimes = dataProvider.tournament!.chaves![currentKey].times.length;
                                            dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 1}"] = partida.team1!;
                                            dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 2}"] = partida.team2!;
                                            partidasByKey[currentKey].insert(partidas.length, partida);
                                          });
                                          final Map<String, dynamic> partidasObj = {};
                                          for(var (index, chave) in dataProvider.tournament!.chaves!.indexed) {
                                            final nome = chave.nome!;
                                            partidasObj[nome] = partidasByKey[index].map((p) => p.toJson()).toList();
                                          }
                                          dataProvider.updateTorneioData({"partidasChave": partidasObj}, dataProvider.tournament!.id!);
                                          final chavesJson = dataProvider.tournament!.chaves!.map((chave) => chave.toJson()).toList();
                                          dataProvider.updateTorneioData({"chaves": chavesJson}, dataProvider.tournament!.id!);
                                        });
                                      },
                                      child: const Text('Adicionar manualmente')
                                  )
                                ],
                              ),
                            )
                          else const Center(
                            child: Text('Aguarde o administrador iniciar os jogos'),
                          )
                        else
                          SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: PageView.builder(
                              controller: _chavesController,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: partidasByKey.length,
                              onPageChanged: (page) {
                                currentMatch = 0;
                                setState(() => currentKey = page);
                              },
                              itemBuilder: (context, index) {
                                partidas = partidasByKey[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 24.0, right: 8),
                                      child: Text('Jogos finalizados: ${partidas.where((p) => p.finished == true).length}'),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                            onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                                            icon: const Icon(Icons.arrow_back_ios)
                                        ),
                                        Text(
                                            'Jogo ${currentMatch + 1} de ${partidas.length}',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.titleLarge
                                        ),
                                        IconButton(
                                            onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                                            icon: const Icon(Icons.arrow_forward_ios)
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: PageView.builder(
                                        controller: _controller,
                                        onPageChanged: (page) => setState(() => currentMatch = page),
                                        itemCount: partidas.length,
                                        itemBuilder: (context, index) {
                                          final team1 = partidas[index].team1;
                                          final team2 = partidas[index].team2;

                                          return Column(
                                            mainAxisAlignment: (_admin ?? false) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              const SizedBox.shrink(),
                                              PartidaItem(
                                                team1: team1!,
                                                team2: team2!,
                                                partida: partidas[index],
                                                admin: _admin ?? false,
                                              ),
                                              if(_admin ?? false)
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                                  child: ElevatedButton(
                                                      onPressed: () {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) => SetWinnerMobileDialog(partida: partidas[index])).then((res) {
                                                          if(res is List) {
                                                            _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                                                            setState(() {
                                                              updatePlayerGames(team1);
                                                              updatePlayerGames(team2);
                                                              partidas[index].finished = true;
                                                              partidas[index].vencedor = res[0] ? 0 : 1;
                                                              partidas[index].pontos = res[2];
                                                              partidasHistory.add(partidas[index]);
                                                              if(res[1]) {
                                                                if(res[0]) {
                                                                  updatePlayerPoints(team1);
                                                                }else {
                                                                  updatePlayerPoints(team2);
                                                                }
                                                              }
                                                              final partidasJson = partidas.map((partida) => partida.toJson());
                                                              dataProvider.updateTorneioData({"partidas": partidasJson}, dataProvider.tournament!.id!);
                                                            });
                                                          }
                                                        }
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                          fixedSize: const Size(118, 30),
                                                          backgroundColor: partidas[index].vencedor != null ? Colors.blue : const Color.fromRGBO(42, 35, 42, 1)
                                                      ),
                                                      child: partidas[index].vencedor != null ? const Text('EDITAR PARTIDA') : const Text('MARCAR RESULTADO')
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            children: [
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                      width: 140,
                                      child: Text('Nome', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16))
                                  ),
                                  Text('Jogos', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16), textAlign: TextAlign.center,),
                                  Text('Pontos', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)),
                                  Text('Media', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: players.map((player) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                          width: 120,
                                          child: Text(player.nome!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)
                                      ),
                                      Text(player.jogosFinalizados?.toString() ?? '0', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                      Text('${player.pontosAtuais ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 10.0),
                                        child: Text(((player.pontosAtuais ?? 0) / (player.jogosFinalizados ?? 0)).toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                      ),
                                    ],
                                  ),
                                )
                                ).toList(),
                              ),
                              const SizedBox(height: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Chaves', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for(var i = 0; i < dataProvider.tournament!.chaves!.length; i++)
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(dataProvider.tournament!.chaves![i].nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: 100,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: dataProvider.tournament?.chaves![i].times.values.toList().length ?? 0,
                                                itemBuilder: (context, index) {
                                                  final times = dataProvider.tournament?.chaves![i].times.values.toList()[index];
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 16.0),
                                                    child: Column(
                                                      children: times!.map((player) => Text(player.nome!, textAlign: TextAlign.center,)).toList(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        Column(
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
                                        Row(
                                          children: [
                                            Column(
                                              children: partidasHistory[i].team1!.map((player) => Text(player.nome!, overflow: TextOverflow.clip,)).toList(),
                                            ),
                                            const SizedBox(width: 16),
                                            if(partidasHistory[i].vencedor == 0)
                                              const Icon(FontAwesome5Solid.medal)
                                          ],
                                        ),
                                        Text(
                                          '${partidasHistory[i].pontos?.split('X')[0].trim() ?? ''} X ${partidasHistory[i].pontos?.split('X')[1].trim() ?? ''}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                        ),
                                        Row(
                                          children: [
                                            if(partidasHistory[i].vencedor == 1)
                                              const Icon(FontAwesome5Solid.medal),
                                            const SizedBox(width: 16),
                                            Column(
                                              children: partidasHistory[i].team2!.map((player) => Text(player.nome!, overflow: TextOverflow.clip)).toList(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider()
                                  ],
                                ),
                              ),
                            const SizedBox(height: 100)
                          ],
                        )
                      ],
                    ),
                  );
                }
            );
          },
        ),
        floatingActionButton: (_admin ?? false)
            ? FloatingActionButton(
          onPressed: () {
            dataProvider.addRoundManually(context).then((partida) {
              if(partida == null) return;
              setState(() {
                final qtdTimes = dataProvider.tournament!.chaves![currentKey].times.length;
                dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 1}"] = partida.team1!;
                dataProvider.tournament!.chaves![currentKey].times["time${qtdTimes + 2}"] = partida.team2!;
                partidasByKey[currentKey].insert(partidas.length, partida);
              });
              final Map<String, dynamic> partidasObj = {};
              for(var (index, chave) in dataProvider.tournament!.chaves!.indexed) {
                final nome = chave.nome!;
                partidasObj[nome] = partidasByKey[index].map((p) => p.toJson()).toList();
              }
              dataProvider.updateTorneioData({"partidasChave": partidasObj}, dataProvider.tournament!.id!);
              final chavesJson = dataProvider.tournament!.chaves!.map((chave) => chave.toJson()).toList();
              dataProvider.updateTorneioData({"chaves": chavesJson}, dataProvider.tournament!.id!);
            });
          },
          child: const Icon(Icons.add),
        )
            : null
    );
  }
}

class PartidaItem extends StatefulWidget {
  final List<Player> team1;
  final List<Player> team2;
  final Partida partida;
  final bool admin;
  const PartidaItem({super.key, required this.team1, required this.team2, required this.partida, required this.admin});

  @override
  State<PartidaItem> createState() => _PartidaItemState();
}

class _PartidaItemState extends State<PartidaItem> {
  TextStyle style() {
    if(widget.partida.finished ?? false) {
      return const TextStyle(color: Colors.black54, fontSize: 30, fontWeight: FontWeight.bold);
    }

    return const TextStyle(color: Colors.black, fontSize: 28);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.team1.map((p) => Text(p.nome ?? '', style: style())).toList(),
            ),
            if(widget.partida.vencedor == 0)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(FontAwesome5Solid.medal, size: 24),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
              'X',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.partida.finished ?? false ? 30 : 28,
                  color: widget.partida.finished ?? false ? Colors.black54 : Colors.black
              )
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.team2.map((p) => Text(p.nome ?? '', style: style())).toList(),
            ),
            if(widget.partida.vencedor == 1)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(FontAwesome5Solid.medal, size: 24,),
              ),
          ],
        ),
      ],
    );
  }
}