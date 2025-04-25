import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/edit_players_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/remove_match_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/set_winner_dialog.dart';
import '../../../model/partida.dart';
import '../widgets/check_admin_dialog.dart';
import '../widgets/edit_player_dialog.dart';
import '../widgets/remove_player_dialog.dart';

class MatchesPage extends StatefulWidget {
  final String tournamentName;
  const MatchesPage({super.key, required this.tournamentName});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with SingleTickerProviderStateMixin {
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  late final TabController _tabController = TabController(length: 4, vsync: this);
  List<Player> players = [];
  List<Partida> partidas = [];
  List<Partida> partidasFiltradas = [];
  List<Partida> partidasHistory = [];
  bool? _admin;
  int playersBySide = 0;
  List<double> fatorDeAjusteList = [0.33, 0.4, 0.55];
  bool _nameSort = false;
  bool _gamesSort = false;
  bool _pointsSort = false;
  bool _mediaSort = false;
  bool _loading = false;

  void startGames() {
    partidas = [];
    if(playersBySide == 2) {
      dataProvider.generate2x2Combinations();
    }else if(playersBySide == 3) {

    }else if(playersBySide == 4) {
      dataProvider.generate4x4Combinations();
    }
    dataProvider.generateMatches();
    setState(() {
      partidas = dataProvider.partidas;
      partidasFiltradas = dataProvider.partidas;
      partidas.shuffle(Random());
    });
    final partidasJson = partidas.map((partida) => partida.toJson()).toList();
    dataProvider.updateTorneioData({"partidas": partidasJson}, dataProvider.tournament!.id!);
  }

  void updatePlayerRank(List<Player> players) {
    try{
      final categorias = dataProvider.tournament!.categorias!;

      // Função auxiliar para adicionar o jogador à categoria e removê-lo das outras.
      void updateCategoria(int index, Player player) {
        final categoria = categorias[index];
        if (categoria.players?.where((p) => p.nome == player.nome).isNotEmpty ?? false) return;

        Player newPlayer = Player();
        newPlayer = player;
        newPlayer.jogosFinalizados = 0;
        newPlayer.pontosAtuais = 0;

        categoria.players ??= [];
        categoria.players!.add(newPlayer);

        for (var otherCategoria in categorias.where((c) => c != categoria)) {
          otherCategoria.players?.removeWhere((p) => p.nome == player.nome);
        }
      }

      for(Player player in players) {
        final playerMedia = (player.pontosAtuais ?? 0) / (player.jogosFinalizados ?? 0);
        for (int i = fatorDeAjusteList.length - 1; i >= 0; i--) {
          final fatorDeAjuste = fatorDeAjusteList[i];
          if (i == 0) {
            updateCategoria(0, player);
            return;
          } else if (playerMedia >= fatorDeAjuste) {
            updateCategoria(i, player);
            return;
          }
        }
      }
    }catch(e) {
      print('ERRO AO ATUALIZAR RANKING DOS JOGADORES $e');
    }
  }

  Future<void> checkIfUserIsLogged() async {
    final isLogged = await dataProvider.checkIfUserIsAlreadyLoggedIn(widget.tournamentName);
    if(isLogged) {
      _admin = true;
    }else {
      await showDialog(context: context, barrierDismissible: false, builder: (context) => CheckAdminDialog(tournamentName: widget.tournamentName)).then((res) {
        _admin = res;
      });
    }
  }

  Future<void> saveData({bool setPlayers = true, bool setMatches = true, bool setCategorias = true}) async {
    if(setPlayers) {
      final playersJson = players.map((jogador) => jogador.toJson()).toList();
      await dataProvider.updateTorneioData({"jogadores": playersJson}, dataProvider.tournament!.id!);
    }
    if(setMatches) {
      final partidasJson = partidas.map((partida) => partida.toJson()).toList();
      await dataProvider.updateTorneioData({"partidas": partidasJson}, dataProvider.tournament!.id!);
    }
    if(setCategorias) {
      final categoriasJson = dataProvider.tournament!.categorias?.map((categoria) => categoria.toJson()).toList();
      await dataProvider.updateTorneioData({"categorias": categoriasJson}, dataProvider.tournament!.id!);
    }
  }

  Future <void> simulateResults() async {
    setState(() => _loading = true);
    for(Partida partida in partidas) {
      setState(() {
        final vencedor = Random().nextInt(2);
        partida.vencedor = vencedor;
        partida.finished = true;
        for(Player player in partida.team1!) {
          final playerInList = players.firstWhere((p) => p.nome == player.nome);
          playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) + 1;
          if(vencedor == 0) {
            player.pontosAtuais = (player.pontosAtuais ?? 0) + 1;
            playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
          }
        }
        for(Player player in partida.team2!) {
          final playerInList = players.firstWhere((p) => p.nome == player.nome);
          playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) + 1;
          if(vencedor == 1) {
            player.pontosAtuais = (player.pontosAtuais ?? 0) + 1;
            playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
          }
        }
        partidasHistory.add(partida);
      });
      updatePlayerRank([...partida.team1 ?? [], ...partida.team2 ?? []]);
    }
    await saveData();
    setState(() => _loading = false);
  }

  Future<void> resetMatches() async {
    setState(() {
      for(Partida partida in partidas) {
        partida.vencedor = null;
        partida.finished = false;
        for(Player player in partida.team1!) {
          final playerInList = players.firstWhere((p) => p.nome == player.nome);
          playerInList.pontosAtuais = 0;
          playerInList.jogosFinalizados = 0;
        }
        for(Player player in partida.team2!) {
          final playerInList = players.firstWhere((p) => p.nome == player.nome);
          playerInList.pontosAtuais = 0;
          playerInList.jogosFinalizados = 0;
        }
      }
      for(Player player in players) {
        player.pontosAtuais = 0;
        player.jogosFinalizados = 0;
      }
      for(Categoria categoria in dataProvider.tournament!.categorias ?? []) {
        categoria.players = [];
        categoria.partidas = [];
      }
      partidasHistory = [];
    });
    await saveData();
  }

  void exlcuirPartidas() {
    setState(() {
      partidas = [];
    });
    dataProvider.tournament!.partidas = [];
    dataProvider.updateTorneioData({"partidas": []}, dataProvider.tournament!.id!);
  }

  Future<void> loadTournamentFromBd() async {
    await checkIfUserIsLogged();
    List<Future> futures = [dataProvider.carregarTorneio(widget.tournamentName)];
    if(dataProvider.players.isEmpty) {
      futures.add(dataProvider.getPlayers());
    }
    await Future.wait(futures);

    if(dataProvider.tournament == null) {
      GoRouter.of(context).go('/');
      return;
    }
    players = dataProvider.tournament!.jogadores ?? [];
    players.sort((a, b) => a.nome!.compareTo(b.nome!));
    partidas = dataProvider.tournament!.partidas ?? [];
    partidasFiltradas = dataProvider.tournament!.partidas ?? [];
    partidasHistory = dataProvider.tournament!.partidas?.where((partida) => partida.finished == true).toList() ?? [];
    playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
    dataProvider.tournament!.categorias!.sort((a, b) {
      if(a.nivelCategoria! == 'Iniciante') {
        return 0;
      }else if(a.nivelCategoria == 'Amador') {
        return 0;
      }else {
        return 1;
      }
    });
    switch(dataProvider.tournament!.categorias!.length) {
      case 1: return setState(() => fatorDeAjusteList = [0.5]);
      case 2: return setState(() => fatorDeAjusteList = [0.5, 1]);
      case 3: return setState(() => fatorDeAjusteList = [0.33, 0.4, 0.55]);
      case 4: return setState(() => fatorDeAjusteList = [0.3, 0.4, 0.7, 0.9]);
    }
  }

  void _showJogadoresComQuemJaJogou(Player playerSelecionado) {
    // Filtra partidas finalizadas onde o jogador está em alguma dupla
    final partidasFinalizadas = partidas.where((p) => (p.finished == true) &&
        (p.team1!.map((t) => t.nome).contains(playerSelecionado.nome) || p.team2!.map((t) => t.nome).contains(playerSelecionado.nome))).toList();

    // Set para evitar duplicatas
    final Set<Player> companheiros = {};

    for (final partida in partidasFinalizadas) {
      final dupla = partida.team1!.map((t) => t.nome).contains(playerSelecionado.nome) ? partida.team1! : partida.team2!;
      companheiros.addAll(dupla.where((p) => p.nome != playerSelecionado.nome));
    }


    final companheirosNames = companheiros.map((p) => p.nome).toList();
    final partnersRemaining = dataProvider.tournament!.jogadores!.where((p) => !companheirosNames.contains(p.nome) && p.nome != playerSelecionado.nome).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${playerSelecionado.nome} Já jogou com:'),
        content: companheiros.isEmpty
          ? Text('Ainda não jogou nenhuma partida finalizada.')
          : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: companheiros.map((p) => Row(
                    children: [
                      Checkbox(value: true, onChanged: (v) {}),
                      Text(p.nome!),
                    ],
                  )).toList(),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Text('Jogadores restantes:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: partnersRemaining.map((p) => Text(p.nome!)).toList(),
                ),
              ],
            ),
          ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar')),
        ],
      ),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadTournamentFromBd());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Fase classificatória - Duração média ${((1.5 * partidas.length) / 60).round()}h'),
        actions: [
          if(_admin == true)
            IconButton(
                onPressed: () => context.go(context.namedLocation('settings', pathParameters: {"nomeDoTorneio": widget.tournamentName})),
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

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                dividerHeight: 0,
                tabs: [
                  Tab(text: 'Jogadores ${dataProvider.tournament?.jogadores?.length ?? 0}'),
                  const Tab(text: 'Classificações'),
                  Tab(text: 'Partidas ${partidas.length}'),
                  const Tab(text: 'Histórico'),
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
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width * .7,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _nameSort = !_nameSort;
                                          players.sort((a, b) {
                                            if(_nameSort) {
                                              return a.nome!.compareTo(b.nome!);
                                            }else {
                                              return b.nome!.compareTo(a.nome!);
                                            }
                                          });
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 210,
                                            child: Text('Nome', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _gamesSort = !_gamesSort;
                                          players.sort((a, b) {
                                            if(_gamesSort) {
                                              return (a.jogosFinalizados ?? 0).compareTo(b.jogosFinalizados ?? 0);
                                            }else {
                                              return (b.jogosFinalizados ?? 0).compareTo(a.jogosFinalizados ?? 0);
                                            }
                                          });
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 200,
                                            child: Text('Partidas jogadas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center,)
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _pointsSort = !_pointsSort;
                                          players.sort((a, b) {
                                            if(_pointsSort) {
                                              return (a.pontosAtuais ?? 0).compareTo(b.pontosAtuais ?? 0);
                                            }else {
                                              return (b.pontosAtuais ?? 0).compareTo(a.pontosAtuais ?? 0);
                                            }
                                          });
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            'Pontos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _mediaSort = !_mediaSort;
                                          players.sort((a, b) {
                                            final mediaA = (a.pontosAtuais ?? 0) / (a.jogosFinalizados ?? 1);
                                            final mediaB = (b.pontosAtuais ?? 0) / (b.jogosFinalizados ?? 1);
                                            if(_mediaSort) {
                                              return mediaA.compareTo(mediaB);
                                            }else {
                                              return mediaB.compareTo(mediaA);
                                            }
                                          });
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            'Media', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
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
                                          width: 250,
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: InkWell(
                                                  onTap: () => _showJogadoresComQuemJaJogou(player),
                                                  child: Text(player.nome!, style: const TextStyle(fontSize: 18),)
                                                )
                                              ),
                                              const SizedBox(width: 8),
                                              if(_admin == true)
                                                IconButton(
                                                  onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (context) => EditPlayerDialog(player: player)
                                                  ).then((res) {
                                                    if(res is Player) {
                                                      setState(() {
                                                        final index = players.indexWhere((p) => p.nome == player.nome);
                                                        players[index] = res;
                                                        updatePlayerRank([players[index]]);
                                                      });
                                                      saveData(setMatches: false);
                                                    }
                                                  }),
                                                  icon: const Icon(Icons.edit)
                                                ),
                                              if(_admin == true)
                                                IconButton(
                                                onPressed: () => showDialog(
                                                  context: context,
                                                  builder: (context) => RemovePlayerTournamentDialog(player: player)
                                                ).then((res) {
                                                  if(res == true) {
                                                   setState(() {
                                                     players.remove(player);
                                                   });
                                                   dataProvider.removeSingle('jogadores', player.toJson(), dataProvider.tournament!.id!);
                                                   for(Categoria categoria in dataProvider.tournament!.categorias ?? []) {
                                                     categoria.players?.removeWhere((p) => p.nome == player.nome);
                                                     for(Partida partida in categoria.partidas ?? []) {
                                                       partida.team1?.removeWhere((p) => p.nome == player.nome);
                                                       partida.team2?.removeWhere((p) => p.nome == player.nome);
                                                     }
                                                   }
                                                   final categoriasJson = dataProvider.tournament!.categorias?.map((categoria) => categoria.toJson()).toList();
                                                   dataProvider.updateTorneioData({"categorias": categoriasJson}, dataProvider.tournament!.id!);
                                                  }
                                                }),
                                                icon: const Icon(Icons.delete)
                                              ),
                                            ],
                                          )
                                        ),
                                        SizedBox(width: 70, child: Text(player.jogosFinalizados?.toString() ?? '0', style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,)),
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            '${player.pontosAtuais ?? 0}',
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                          )
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10.0),
                                          child: Text(((player.pontosAtuais ?? 0) / (player.jogosFinalizados ?? 1)).toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                        ),
                                      ],),
                                  )
                                  ).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width * .7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Categorias', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for(var i = 0; i < (dataProvider.tournament?.categorias?.length ?? 0); i++)
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Text(dataProvider.tournament?.categorias?[i].nome ?? '', style: const TextStyle(fontWeight: FontWeight.bold),),
                                              if(i == 0)
                                                Text('media < ${fatorDeAjusteList[i]}', style: const TextStyle(fontSize: 10))
                                              else
                                                Text('media >= ${fatorDeAjusteList[i]}', style: const TextStyle(fontSize: 10))
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: 100,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: dataProvider.tournament?.categorias?[i].players?.length ?? 0,
                                              itemBuilder: (context, index) {
                                                final player = dataProvider.tournament?.categorias?[i].players![index];
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 16.0),
                                                  child: Text(player!.nome!, textAlign: TextAlign.center,),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                  ],
                                )
                              ],
                            ),
                          )
                        )
                      ),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          child: Column(
                            children: [
                              if(partidas.isNotEmpty && _admin == true)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final partida = await dataProvider.addRoundManually(context);
                                          if(partida != null) {
                                            setState(() => partidas.add(partida));
                                            dataProvider.insertSingle(
                                              'partidas',
                                              partida.toJson(),
                                              dataProvider.tournament!.id!
                                            );
                                          }
                                        },
                                        label: const Text('Adicionar partida'),
                                        icon: const Icon(Icons.add),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => setState(() => partidas.shuffle(Random())),
                                        label: const Text('Embaralhar partidas'),
                                        icon: const Icon(Icons.shuffle),
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
                                        ElevatedButton(
                                          onPressed: simulateResults,
                                          child: const Text('Finalizar partidas'),
                                        ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: resetMatches,
                                        child: const Text('Resetar partidas'),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: exlcuirPartidas,
                                        child: const Text('Exlcuir partidas'),
                                      ),
                                    ],
                                  ),
                                ),
                              if(partidas.isEmpty && _admin != true)
                                Center(
                                  child: Text('AGUARDE O ADMINISTRADOR INICIAR OS JOGOS'),
                                ),
                              Container(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                width: MediaQuery.sizeOf(context).width * .5,
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
                                      partidasFiltradas = partidas.where((partida) {
                                        final team1Names = partida.team1?.map((t) => t.nome!.toLowerCase()) ?? [];
                                        final team2Names = partida.team2?.map((t) => t.nome!.toLowerCase()) ?? [];
                                        return team1Names.any((nome) => nome.contains(query)) ||
                                            team2Names.any((nome) => nome.contains(query));
                                      }).toList();
                                    });
                                  },
                                ),
                              ),
                              if(partidas.isEmpty && _admin == true)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: startGames,
                                      child: const Text('Gerar times')
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final partida = await dataProvider.addRoundManually(context);
                                        if(partida != null) {
                                          setState(() => partidas.add(partida));
                                          dataProvider.insertSingle(
                                            'partidas',
                                            partida.toJson(),
                                            dataProvider.tournament!.id!
                                          );
                                        }
                                      },
                                      child: const Text('Adicionar manualmente')
                                    )
                                  ]
                                )
                              else
                                Expanded(
                                  child: SizedBox(
                                    width: MediaQuery.sizeOf(context).width * .7,
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
                                                    admin: _admin,
                                                  )
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => SetWinnerDialog(partida: partida)).then((res) {
                                                    if (res is List) {
                                                      setState(() {
                                                        dataProvider.updatePlayerGames(team1, players);
                                                        dataProvider.updatePlayerGames(team2, players);
                                                        final partida = partidas[index];
                                                        partida.finished = true;
                                                        partida.vencedor = res[0] ? 0 : 1;
                                                        partida.pontos = res[2];
                                                        partidasHistory.add(partida);

                                                        if (res[1]) {
                                                          final vencedor = res[0] ? partida.team1 : partida.team2;
                                                          final perdedor = res[0] ? partida.team2 : partida.team1;

                                                          for (var player in vencedor ?? []) {
                                                            final playerInList = players.firstWhere((p) => p.nome == player.nome);
                                                            playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
                                                            playerInList.pontos = (playerInList.pontos ?? 0) + 1;
                                                          }

                                                          updatePlayerRank(vencedor ?? []);
                                                          updatePlayerRank(perdedor ?? []);
                                                        }
                                                      });
                                                      saveData();
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
                                                  final partida = partidas[index];
                                                  await dataProvider.removeSingle('partidas', partida.toJson(), dataProvider.tournament!.id!);
                                                  setState(() {
                                                    if(partida.finished == true) {
                                                      final team1 = partida.team1;
                                                      final team2 = partida.team2;
                                                      for(var player in team1 ?? []) {
                                                        final playerInList = players.firstWhere((p) => p.nome == player.nome);
                                                        playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) - 1;
                                                        if(partida.vencedor == 0) {
                                                          playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) - 1;
                                                        }
                                                      }
                                                      for(var player in team2 ?? []) {
                                                        final playerInList = players.firstWhere((p) => p.nome == player.nome);
                                                        playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) - 1;
                                                        if(partida.vencedor == 1) {
                                                          playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) - 1;
                                                        }
                                                      }
                                                      updatePlayerRank([...team1 ?? [], ...team2 ?? []]);
                                                    }
                                                    partidas.remove(partida);
                                                  });
                                                  await saveData(setMatches: false);
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
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PartidaItem extends StatefulWidget {
  final List<Player> team1;
  final List<Player> team2;
  final Partida partida;
  final bool? admin;
  const PartidaItem({super.key, required this.team1, required this.team2, required this.partida, required this.admin});

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
                    builder: (context) => EditPlayersDialog(team: widget.team1, otherTeam: widget.team2)
                  ).then((res) {
                    if(res == true) setState(() {});
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
                    builder: (context) => EditPlayersDialog(team: widget.team2, otherTeam: widget.team1)
                  ).then((res) {
                    if(res == true) setState(() {});
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
