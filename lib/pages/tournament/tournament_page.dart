import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'package:volleyball_tournament_app/model/tournament.dart';
import 'package:volleyball_tournament_app/shared/player_info_widget.dart';
import '../../helpers/remover_acentos.dart';
import '../../model/categoria.dart';
import '../players/player_dialog_actions.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  late final DataController _dataController;
  final PageController _pageController = PageController();
  final TextEditingController _controller = TextEditingController();
  ValueNotifier<bool> updateList = ValueNotifier(false);
  Tournament? _tournament;
  List<Player> readyPlayers = [];
  List<Player> searchList = [];
  int addedPlayers = 0;
  bool _hideButton = false;

  Widget playersList(List<Player> players) => Expanded(
    child: ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100),
      itemCount: players.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final player = players[index];

        return PlayerInfoWidget(
            player: player,
            trailing: Transform.scale(
              scale: .7,
              child: ChoiceChip(
                selected: readyPlayers.contains(player),
                onSelected: (value) {
                  if(readyPlayers.contains(player)) {
                    addedPlayers--;
                    readyPlayers.remove(player);
                  }else {
                    addedPlayers++;
                    readyPlayers.add(player);
                  }
                  setState(() {
                    addedPlayers;
                    readyPlayers;
                  });
                },
                label: Text(
                    readyPlayers.contains(player) ? 'CHECK-OUT' : 'CHECK-IN',
                    style: const TextStyle(color: Colors.white)
                ),
                backgroundColor: const Color.fromRGBO(42, 35, 42, 1),
              )
            )
        );
      },
    ),
  );

  @override
  void initState() {
    _dataController = Provider.of<DataController>(context, listen: false);
    _tournament = _dataController.tournament;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_dataController.players.isEmpty) {
        _dataController.getPlayers().whenComplete(() {
          _dataController.players.sort((a, b) => a.nome!.compareTo(b.nome!));
        });
      }
    });
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
    _pageController.dispose();
  }

  Widget _playerRow(Player player) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(player.nome ?? ''),
            const SizedBox(width: 8),
            Icon((player.sex == 0) ? Icons.man : Icons.woman)
          ],
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () {
            setState(() {
              addedPlayers--;
              readyPlayers.remove(player);
              updateList.value = !updateList.value;
            });
            if(readyPlayers.isEmpty) {
              Navigator.pop(context);
            }
          },
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.red
            ),
            child: const Icon(Icons.delete, color: Colors.white, size: 18,),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Selecionar jogadores'),
        actions: [
          TextButton.icon(
            onPressed: () => showDialog(
                context: context,
                builder: (context) => const AddPlayerDialog(isTournament: true)
            ).then((res) {
              if(res is Player) {
                setState(() {
                  addedPlayers++;
                  readyPlayers.add(res);
                });
              }
            }),
            label: const Text('Adicionar jogador'), icon: const Icon(Icons.add)
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
          
          if(value.players.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nenhum jogador disponível...'),
                ElevatedButton.icon(onPressed: () {}, label: const Text('Adicionar jogador'), icon: const Icon(Icons.add),)
              ],
            );
          }
          
          return PageView(
            controller: _pageController,
            onPageChanged: (page) {
              if(page == 0) setState(() => _hideButton = false);
              if(page == 1) setState(() => _hideButton = true);
            },
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      controller: _controller,
                      onChanged: (newValue) {
                        if(newValue.isEmpty) {
                          setState(() {
                            searchList = [];
                            value.players.sort((a, b) => a.nome!.compareTo(b.nome!));
                          });
                        }else {
                          final querySemAcento = removerAcentos(newValue.toLowerCase());
                          setState(() {
                            searchList = value.players.where((player) => removerAcentos(player.nome!.toLowerCase()).startsWith(querySemAcento) || player.nome!.toLowerCase().contains(querySemAcento)).toList();
                          });
                        }
                      },
                      decoration: InputDecoration(
                          hintText: 'Pesquisar jogador...',
                          suffixIcon: IconButton(
                              onPressed: () {
                                _controller.clear();
                                setState(() => searchList = []);
                              },
                              icon: const Icon(Icons.close)
                          ),
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
                    ),
                  ),
                  if(searchList.isNotEmpty)
                    playersList(searchList)
                  else
                    playersList(value.players),
                ],
              ),
              if(_tournament!.modelo == 'Chaves')
                ChavesWidget(tournament: _tournament!, jogadores: readyPlayers)
            ],
          );
        },
      ),
      floatingActionButton: addedPlayers == 0 ? null
        : Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if(_tournament!.modelo == 'Chaves')
              if(!_hideButton)
                InkWell(
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue,
                    ),
                    child: const Text('Próximo', style: TextStyle(color: Colors.white),),
                  ),
                ),
            if(_tournament!.modelo != 'Chaves')
              if(!_hideButton)
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: ValueListenableBuilder(
                        valueListenable: updateList,
                        builder: (context, value, _) {
                          final homensList = readyPlayers.where((player) => player.sex == 0).length;
                          final mulheresList = readyPlayers.where((player) => player.sex == 1).length;

                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: readyPlayers.map((player) => _playerRow(player)).toList(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text('$homensList Homens | $mulheresList Mulheres'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if(readyPlayers.isNotEmpty) {
                                      _tournament!.jogadores = readyPlayers;
                                      _tournament!.partidas ??= [];
                                      _tournament!.ativo = true;
                                      _dataController.salvarTorneio().whenComplete(() {
                                        GoRouter.of(context).go('/tournament/${_tournament!.nomeTorneio!}/match');
                                      });
                                    }
                                  },
                                  label: const Text('Iniciar torneio'),
                                  icon: const Icon(Icons.play_arrow_rounded)
                                )
                              ],
                            ),
                          );
                        }
                      ),
                    )
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue,
                    ),
                    child: Text('Jogadores adicionados $addedPlayers', style: const TextStyle(color: Colors.white),),
                  ),
                ),
          ],
        ),
    );
  }
}

class ChavesWidget extends StatefulWidget {
  final Tournament tournament;
  final List<Player> jogadores;
  const ChavesWidget({super.key, required this.tournament, required this.jogadores});

  @override
  State<ChavesWidget> createState() => _ChavesWidgetState();
}

class _ChavesWidgetState extends State<ChavesWidget> {
  List<List<Player>> jogadoresDivididos = [];

  List<List<Player>> divideIntoKeys() {
    final numberOfKeys = widget.tournament.chaves?.length ?? 0;
    final players = List<Player>.from(widget.jogadores);
    players.shuffle();

    if (numberOfKeys <= 0) {
      throw ArgumentError('A quantidade de chaves deve ser maior que zero.');
    }

    List<List<Player>> keys = [];

    if (widget.tournament.misto ?? false) {
      // Separar jogadores por gênero
      List<Player> men = players.where((p) => p.sex == 0).toList();
      List<Player> women = players.where((p) => p.sex == 1).toList();

      // Calcular jogadores por chave para cada gênero
      int menPerKey = (men.length / numberOfKeys).ceil();
      int womenPerKey = (women.length / numberOfKeys).ceil();

      for (int i = 0; i < numberOfKeys; i++) {
        List<Player> key = [];

        for (int j = 0; j < menPerKey && men.isNotEmpty; j++) {
          key.add(men.removeAt(0));
        }
        for (int j = 0; j < womenPerKey && women.isNotEmpty; j++) {
          key.add(women.removeAt(0));
        }

        keys.add(key);
      }

      // Distribuir jogadores restantes
      while (men.isNotEmpty || women.isNotEmpty) {
        for (int i = 0; i < keys.length && (men.isNotEmpty || women.isNotEmpty); i++) {
          if (men.isNotEmpty) keys[i].add(men.removeAt(0));
          if (women.isNotEmpty) keys[i].add(women.removeAt(0));
        }
      }
    } else {
      // Divisão geral sem separar por gênero
      int playersPerKey = (players.length / numberOfKeys).ceil();

      for (int i = 0; i < numberOfKeys; i++) {
        List<Player> key = [];
        for (int j = 0; j < playersPerKey && players.isNotEmpty; j++) {
          key.add(players.removeAt(0));
        }
        keys.add(key);
      }

      // Distribuir jogadores restantes
      while (players.isNotEmpty) {
        for (int i = 0; i < keys.length && players.isNotEmpty; i++) {
          keys[i].add(players.removeAt(0));
        }
      }
    }

    return keys;
  }

  Map<String, List<Player>> divideIntoTeams(List<Player> players) {
    final playersPerTeam = int.parse(widget.tournament.qtdJogadoresEmCampo!.split('x')[0]);

    if (playersPerTeam <= 0) {
      throw ArgumentError('A quantidade de jogadores por time deve ser maior que zero.');
    }

    Map<String, List<Player>> teams = {};
    int teamIndex = 1; // Para identificar os times no mapa

    if (widget.tournament.misto ?? false) {
      List<Player> men = players.where((p) => p.sex == 0).toList();
      List<Player> women = players.where((p) => p.sex == 1).toList();

      while (men.isNotEmpty || women.isNotEmpty) {
        List<Player> team = [];
        int womenNeeded = (playersPerTeam / 2).floor();
        womenNeeded = women.isEmpty ? 0 : (women.length < womenNeeded ? women.length : womenNeeded);

        for (int i = 0; i < womenNeeded; i++) {
          if (women.isNotEmpty) team.add(women.removeAt(0));
        }

        int menNeeded = playersPerTeam - team.length;
        for (int i = 0; i < menNeeded; i++) {
          if (men.isNotEmpty) team.add(men.removeAt(0));
        }

        while (team.length < playersPerTeam && (men.isNotEmpty || women.isNotEmpty)) {
          if (women.isNotEmpty) {
            team.add(women.removeAt(0));
          } else if (men.isNotEmpty) {
            team.add(men.removeAt(0));
          }
        }

        final teamId = const Uuid().v4();
        for (Player player in team) {
          player.teamId = teamId;
        }
        teams['time$teamIndex'] = team;
        teamIndex++;
      }
    } else {
      players.shuffle(); // Aleatorizar jogadores para divisão uniforme

      while (players.isNotEmpty) {
        List<Player> team = [];
        for (int i = 0; i < playersPerTeam && players.isNotEmpty; i++) {
          team.add(players.removeAt(0));
        }

        final teamId = const Uuid().v4();
        for (Player player in team) {
          player.teamId = teamId;
        }
        teams['time$teamIndex'] = team;
        teamIndex++;
      }
    }

    return teams;
  }

  @override
  Widget build(BuildContext context) {
    final men = widget.jogadores.where((p) => p.sex == 0).toList();
    final women = widget.jogadores.where((p) => p.sex == 1).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.tournament.chaves?.length ?? 0,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final chave  = widget.tournament.chaves![index];
                  final times = chave.times.values.toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chave.nome ?? ''),
                      for(var i = 0; i < times.length; i++)
                        Row(
                          children: [
                            Text('Time ${i + 1}'),
                            const SizedBox(width: 12),
                            Text(times[i].map((jogador) => jogador.nome!).join(', '))
                          ],
                        ),
                    ],
                  );
                },
              ),
              if(widget.jogadores.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            jogadoresDivididos = divideIntoKeys();
                            for(var (index, chave) in widget.tournament.chaves!.indexed) {
                              chave.times = divideIntoTeams(jogadoresDivididos[index]);
                            }
                            setState(() {});
                          },
                          child: const Text('Gerar chaves')
                      ),

                      if(jogadoresDivididos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final dataController = Provider.of<DataController>(context, listen: false);
                              widget.tournament.jogadores = widget.jogadores;
                              widget.tournament.partidas ??= [];
                              widget.tournament.ativo = true;
                              dataController.salvarTorneio().whenComplete(() {
                                GoRouter.of(context).go(context.namedLocation(
                                  'matches',
                                  pathParameters: {"nomeDoTorneio": widget.tournament.nomeTorneio!},
                                  queryParameters: {"m": "keys"}
                                ));
                              });
                            },
                            label: const Text('Iniciar torneio'),
                            icon: const Icon(Icons.play_arrow),
                          ),
                        ),
                    ],
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jogadores - ${men.length} Homens - ${women.length} Mulheres', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.jogadores.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final jogador = widget.jogadores[index];

                      return Row(
                        children: [
                          Text(jogador.nome ?? ''),
                          const SizedBox(width: 8),
                          Icon((jogador.sex == 0) ? Icons.man : Icons.woman)
                        ],
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}