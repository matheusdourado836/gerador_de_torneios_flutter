import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import '../../../model/partida.dart';
import '../matches_categoria/matches_page.dart';
import '../widgets/check_admin_dialog.dart';
import '../widgets/remove_match_dialog.dart';
import '../widgets/set_winner_dialog.dart';

class KnockoutStagePage extends StatefulWidget {
  final String nomeTorneio;
  const KnockoutStagePage({super.key, required this.nomeTorneio});

  @override
  State<KnockoutStagePage> createState() => _KnockoutStagePageState();
}

class _KnockoutStagePageState extends State<KnockoutStagePage> {
  late final DataController _dataController = Provider.of<DataController>(context, listen: false);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool? _admin;

  Future<void> checkIfUserIsLogged() async {
    final isLogged = await _dataController.checkIfUserIsAlreadyLoggedIn(widget.nomeTorneio);
    if(isLogged) {
      _admin = true;
    }else {
      showDialog(context: context, barrierDismissible: false, builder: (context) => CheckAdminDialog(tournamentName: widget.nomeTorneio,)).then((res) {
        _admin = res;
      });
    }
  }


  Future<void> loadTournament() async {
    await checkIfUserIsLogged();
    await _dataController.carregarTorneio(widget.nomeTorneio);
    _dataController.tournament?.categorias ??= [];
    setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadTournament());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Fase eliminatória'),
      ),
      body: Consumer<DataController>(
        builder: (context, value, _) {
          if(value.loading || value.tournament == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded)
                  ),
                  Text(_dataController.tournament?.categorias?[_currentPage].nome ?? ''),
                  IconButton(
                    onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                    icon: const Icon(Icons.arrow_forward_ios_rounded)
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: PageView.builder(
                  controller: _pageController,
                  allowImplicitScrolling: false,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemCount: value.tournament?.categorias?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    final categoria = value.tournament!.categorias![index];
                    return CategoriaSection(
                      categoria: categoria,
                      players: categoria.players ?? [],
                      admin: _admin,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(
          context.namedLocation(
            'podium',
            pathParameters: {"nomeDoTorneio": widget.nomeTorneio}
          ),
        ),
        label: const Text('Encerrar torneio'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}

class CategoriaSection extends StatefulWidget {
  final Categoria categoria;
  final List<Player> players;
  final bool? admin;
  const CategoriaSection({super.key, required this.categoria, required this.players, required this.admin});

  @override
  State<CategoriaSection> createState() => _CategoriaSectionState();
}

class _CategoriaSectionState extends State<CategoriaSection> with SingleTickerProviderStateMixin {
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  late final TabController _tabController = TabController(length: 4, vsync: this);
  List<Partida> partidas = [];
  List<Partida> partidasHistory = [];
  List<List<Player>> _teams = [];
  List<List<Player>> _teamsSorted = [];
  int playersBySide = 0;
  bool _gamesSort = false;
  bool _pointsSort = false;
  bool _mediaSort = false;

  void startGames() {
    partidas.clear();
    partidasHistory.clear();
    for (int i = 0; i < _teams.length; i++) {
      for (int j = i + 1; j < _teams.length; j++) {
        partidas.add(
          Partida(
            team1: _teams[i],
            team2: _teams[j],
            finished: false,
          ),
        );
      }
    }
    partidas.shuffle(Random());
    widget.categoria.partidas = partidas;
    dataProvider.updateTorneioData({"categorias": dataProvider.tournament!.categorias!.map((categoria) => categoria.toJson()).toList()}, dataProvider.tournament!.id!);
    setState(() => partidas);
  }

  void gerarTimesUnicos() {
    final Set<Player> usados = {};

    List<Player> homens = widget.players.where((p) => p.sex == 0).toList();
    List<Player> mulheres = widget.players.where((p) => p.sex == 1).toList();

    if (dataProvider.tournament?.misto ?? false) {
      if (playersBySide == 2) {
        int totalTimes = min(homens.length, mulheres.length);

        for (int i = 0; i < totalTimes; i++) {
          final h = homens[i];
          final m = mulheres[i];

          if (!usados.contains(h) && !usados.contains(m)) {
            _teams.add([h, m]);
            usados.add(h);
            usados.add(m);
          }
        }
      } else if (playersBySide == 3) {
        int totalTimes = min(homens.length ~/ 2, mulheres.length);

        for (int i = 0; i < totalTimes; i++) {
          final h1 = homens[i * 2];
          final h2 = homens[i * 2 + 1];
          final m = mulheres[i];

          if (!usados.contains(h1) && !usados.contains(h2) && !usados.contains(m)) {
            _teams.add([h1, h2, m]);
            usados.addAll([h1, h2, m]);
          }
        }
      } else {
        throw Exception('Número de jogadores por time não suportado no modo misto.');
      }
    } else {
      final disponiveis = widget.players.where((p) => !usados.contains(p)).toList();

      for (int i = 0; i <= disponiveis.length - playersBySide; i += playersBySide) {
        final grupo = disponiveis.sublist(i, i + playersBySide);
        if (grupo.every((p) => !usados.contains(p))) {
          _teams.add(grupo);
          usados.addAll(grupo);
        }
      }
    }
  }

  void getTeams() {
    if(partidas.isEmpty) {
      gerarTimesUnicos();
      return;
    }
    Set<String> timesSet = {};
    List<List<Player>> timesUnicos = [];

    for (var partida in partidas) {
      List<List<Player>?> timesDaPartida = [partida.team1, partida.team2];

      for (var time in timesDaPartida) {
        if (time != null) {
          // Gera uma "assinatura" do time (nomes ordenados)
          var nomesOrdenados = time.map((j) => j.nome).toList()..sort();
          var assinatura = nomesOrdenados.join(',');

          // Se ainda não foi adicionado
          if (!timesSet.contains(assinatura)) {
            // Pega os objetos reais da lista original
            List<Player> timeOriginal = nomesOrdenados.map((nomeJogador) {
              return widget.players.firstWhere((p) => p.nome == nomeJogador);
            }).toList();

            timesUnicos.add(timeOriginal);
            timesSet.add(assinatura);
          }
        }
      }
    }

    setState(() => _teams = timesUnicos);
  }

  double calculateMedia(Player jogador) {
    int jogos = 0;
    int vitorias = 0;
    int saldo = 0;

    for (var partida in partidas) {
      if (partida.team1 == null || partida.team2 == null || partida.pontos == null) continue;

      bool jogouTime1 = partida.team1!.any((p) => p.nome == jogador.nome);
      bool jogouTime2 = partida.team2!.any((p) => p.nome == jogador.nome);

      if (!jogouTime1 && !jogouTime2) continue;

      jogos++;

      final pontos = partida.pontos!.split('X').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (pontos.length != 2) continue;

      int pontosFeitos = jogouTime1 ? pontos[0] : pontos[1];
      int pontosSofridos = jogouTime1 ? pontos[1] : pontos[0];

      // Vitória
      if ((jogouTime1 && partida.vencedor == 0) || (jogouTime2 && partida.vencedor == 1)) {
        vitorias++;
      }

      saldo += (pontosFeitos - pontosSofridos);
    }

    if (jogos == 0) return 0;

    return (vitorias + saldo) / jogos;
  }

  @override
  void initState() {
    partidas = widget.categoria.partidas ?? [];
    partidasHistory = partidas.where((p) => p.finished == true).toList();
    playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
    getTeams();
    _tabController.addListener(() {
      if(_tabController.index == 2) {
        setState(() {
          _teamsSorted = List.from(_teams);
          _teamsSorted.sort((a, b) {
            final mediaA = calculateMedia(a.first);
            final mediaB = calculateMedia(b.first);
            if(_mediaSort) {
              return mediaA.compareTo(mediaB);
            }else {
              return mediaB.compareTo(mediaA);
            }
          });
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          dividerHeight: 0,
          tabs: [
            const Tab(text: 'Jogadores'),
            const Tab(text: 'Partidas'),
            const Tab(text: 'Classificações'),
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
                              SizedBox(
                                width: 210,
                                child: Text('Times', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _gamesSort = !_gamesSort;
                                    _teams.sort((a, b) {
                                      if(_gamesSort) {
                                        return (a.first.jogosFinalizados ?? 0).compareTo(b.first.jogosFinalizados ?? 0);
                                      }else {
                                        return (b.first.jogosFinalizados ?? 0).compareTo(a.first.jogosFinalizados ?? 0);
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
                                    _teams.sort((a, b) {
                                      if(_pointsSort) {
                                        return (a.first.pontosAtuais ?? 0).compareTo(b.first.pontosAtuais ?? 0);
                                      }else {
                                        return (b.first.pontosAtuais ?? 0).compareTo(a.first.pontosAtuais ?? 0);
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
                                    _teams.sort((a, b) {
                                      final mediaA = calculateMedia(a.first);
                                      final mediaB = calculateMedia(b.first);
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
                            children: _teams.map((team) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 350,
                                    child: Row(
                                      children: [
                                        Wrap(
                                          children: [
                                            for(var i = 0; i < team.length; i++)
                                              Text(
                                                '${team[i].nome}${i + 1 == team.length ? '' : ', '}',
                                                style: const TextStyle(fontSize: 18), textAlign: TextAlign.center
                                              )
                                          ],
                                        ),
                                      ],
                                    )
                                  ),
                                  SizedBox(width: 70, child: Text(team.first.jogosFinalizados?.toString() ?? '0', style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,)),
                                  SizedBox(
                                      width: 70,
                                      child: Text(
                                        '${team.first.pontosAtuais ?? 0}',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      )
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Text(calculateMedia(team.first).toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
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
                Center(
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width * .7,
                    child: Column(
                      children: [
                        if(partidas.isNotEmpty && widget.admin == true)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final partida = await dataProvider.addRoundManually(context, jogadoresDisponiveis: widget.players);
                                    if(partida != null) {
                                      setState(() => partidas.add(partida));
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
                              ],
                            ),
                          ),
                        if(partidas.isEmpty && widget.admin == true)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => startGames(),
                                child: const Text('Gerar times')
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final partida = await dataProvider.addRoundManually(context, jogadoresDisponiveis: widget.players);
                                  if(partida != null) {
                                    setState(() => partidas.add(partida));
                                  }
                                },
                                child: const Text('Adicionar manualmente')
                              )
                            ]
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              itemCount: partidas.length,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final partida = partidas[index];
                                final team1 = partida.team1;
                                final team2 = partida.team2;

                                return Row(
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
                                            admin: widget.admin,
                                          )
                                        ],
                                      ),
                                    ),
                                    if(widget.admin == true)
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => SetWinnerDialog(partida: partida)).then((res) {
                                                  if (res is List) {
                                                    dataProvider.updatePlayerGames(team1, widget.players);
                                                    dataProvider.updatePlayerGames(team2, widget.players);
                                                    setState(() {
                                                      final partida = partidas[index];
                                                      partida.finished = true;
                                                      partida.vencedor = res[0] ? 0 : 1;
                                                      partida.pontos = res[2];
                                                      partidasHistory.add(partida);

                                                      if (res[1]) {
                                                        final vencedor = res[0] ? partida.team1 : partida.team2;

                                                        for (var player in vencedor ?? []) {
                                                          final playerInList = widget.players.firstWhere((p) => p.nome == player.nome);
                                                          playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
                                                          playerInList.pontos = (playerInList.pontos ?? 0) + 1;
                                                        }
                                                      }

                                                      final categoriasJson = dataProvider.tournament!.categorias!.map((categoria) => categoria.toJson()).toList();
                                                      dataProvider.updateTorneioData({"categorias": categoriasJson}, dataProvider.tournament!.id!);
                                                    });
                                                  }
                                                });
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
                                              ).then((res) {
                                                if(res == true) {
                                                  setState(() => partidas.remove(partida));
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
                                      )
                                  ],
                                );
                              },
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teamsSorted.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          TextStyle? textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
                          if(index == 0) {
                            textStyle = textStyle?.copyWith(color: Color(0xFFFFD700));
                          }else if(index == 1) {
                            textStyle = textStyle?.copyWith(color: Colors.grey);
                          }else if(index == 2) {
                            textStyle = textStyle?.copyWith(color: Color(0xFFCD7F32));
                          }
                          final team = _teamsSorted[index];
                          final media = calculateMedia(team.first);
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text('${index + 1}º -', style: textStyle),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      for(var i = 0; i < team.length; i++)
                                        Text(
                                          '${team[i].nome}${i + 1 == team.length ? '' : ', '}',
                                          style: const TextStyle(fontSize: 18),
                                        )
                                    ]
                                  )
                                ),
                                Text(media.toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * .7,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: partidasHistory.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemBuilder: (context, i) {
                          final partida = partidasHistory[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
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
                                            children: partida.team1!
                                                .map((player) => Text(
                                              player.nome!,
                                              overflow: TextOverflow.clip,
                                            ))
                                                .toList(),
                                          ),
                                          const SizedBox(width: 16),
                                          if (partida.vencedor == 0)
                                            const Icon(FontAwesome5Solid.medal),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${partida.pontos?.split('X')[0].trim() ?? ''} X ${partida.pontos?.split('X')[1].trim() ?? ''}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                    SizedBox(
                                      width: 300,
                                      height: 60,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (partida.vencedor == 1)
                                            const Icon(FontAwesome5Solid.medal),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: partida.team2!
                                                .map((player) => Text(
                                              player.nome!,
                                              overflow: TextOverflow.clip,
                                            ))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      )
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

