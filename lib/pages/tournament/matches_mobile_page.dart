import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controller/data_controller.dart';
import '../../model/categoria.dart';
import '../../model/partida.dart';
import '../../model/player.dart';
import 'edit_players_dialog.dart';
import 'set_winner_mobile_dialog.dart';

class MatchesMobilePage extends StatefulWidget {
  final String tournamentName;
  const MatchesMobilePage({super.key, required this.tournamentName});

  @override
  State<MatchesMobilePage> createState() => _MatchesMobilePageState();
}

class _MatchesMobilePageState extends State<MatchesMobilePage> {
  final PageController _controller = PageController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  List<Player> players = [];
  List<List<Player>> listaDeDuplas = [];
  List<Partida> partidas = [];
  List<Partida> partidasHistory = [];
  Set<String> duplasUsadas = {};
  int playersBySide = 0;
  int qtdRounds = 0;
  int currentRound = 0;
  int currentMatch = 0;
  List<double> fatorDeAjusteList = [];

  void generate2x2game({bool misto = false}) {
    List<Partida> innerPartidas = [];
    combinations(2, misto: misto);

    for (int i = 0; i < listaDeDuplas.length; i++) {
      for (int j = i + 1; j < listaDeDuplas.length; j++) {
        List<String> time1 = listaDeDuplas[i].map((dupla) => dupla.nome!).toList();
        List<String> time2 = listaDeDuplas[j].map((dupla) => dupla.nome!).toList();

        if (time1.toSet().intersection(time2.toSet()).isEmpty) {
          String chaveTime1 = time1.join(',');
          String chaveTime2 = time2.join(',');

          if (!duplasUsadas.contains(chaveTime1) && !duplasUsadas.contains(chaveTime2)) {
            innerPartidas.add(Partida(team1: listaDeDuplas[i], team2: listaDeDuplas[j]));
            duplasUsadas.add(chaveTime1);
            duplasUsadas.add(chaveTime2);
          }
        }
      }
    }

    setState(() {
      partidas = innerPartidas;
      partidasHistory.addAll(partidas);
      partidas.shuffle();
    });
  }

  void combinations(int r, {bool misto = false}) {
    listaDeDuplas = [];

    if (misto) {
      // Separar jogadores por sexo
      List<Player> homens = players.where((p) => p.sex == null || p.sex == 0).toList();
      List<Player> mulheres = players.where((p) => p.sex == 1).toList();

      homens.sort((a, b) {
        a.partidasJogadas ??= 0;
        b.partidasJogadas ??= 0;
        return a.partidasJogadas!.compareTo(b.partidasJogadas!);
      });
      mulheres.sort((a, b) {
        a.partidasJogadas ??= 0;
        b.partidasJogadas ??= 0;
        return a.partidasJogadas!.compareTo(b.partidasJogadas!);
      });

      // Criar combinações entre homens e mulheres
      for (var homem in homens) {
        for (var mulher in mulheres) {
          listaDeDuplas.add([homem, mulher]);
        }
      }
      setState(() => listaDeDuplas);
    } else {
      // Caso misto seja falso, cria todas as combinações normalmente
      void combine(List<Player> combo, int start) {
        if (combo.length == r) {
          listaDeDuplas.add(List.from(combo));
          return;
        }

        for (int i = start; i < players.length; i++) {
          combo.add(players[i]);
          combine(combo, i + 1);
          combo.removeLast();
        }
      }

      combine([], 0);
    }
  }

  void updatePlayerGames(List<Player> team) {
    for (var player in team) {
      final playerFromList = players.firstWhere((p) => p.nome == player.nome);
      playerFromList.partidasJogadas = (playerFromList.partidasJogadas ?? 0) + 1;
    }
    setState(() => players);
  }

  void updatePlayerRank(Player player) {
    for(double fatorDeAjuste in fatorDeAjusteList.reversed) {
      final playerMedia = (player.pontos ?? 0) / (player.partidasJogadas ?? 0);
      if(fatorDeAjusteList.indexOf(fatorDeAjuste) == 0) {
        if(!(dataProvider.tournament!.categorias![0].players?.contains(player) ?? false)) {
          dataProvider.tournament!.categorias![0].players ??= [];
          dataProvider.tournament!.categorias![0].players!.add(player);
          final categoria = dataProvider.tournament!.categorias![0];
          final List<Categoria> otherCategorias = dataProvider.tournament!.categorias!.where((c) => c.nome != categoria.nome).toList();
          for(Categoria categoria in otherCategorias) {
            if(categoria.players?.contains(player) ?? false) {
              categoria.players!.remove(player);
            }
          }
          return;
        }
      }
      if(playerMedia >= fatorDeAjuste) {
        final index = fatorDeAjusteList.indexOf(fatorDeAjuste);
        if(!(dataProvider.tournament!.categorias![index].players?.contains(player) ?? false)) {
          dataProvider.tournament!.categorias![index].players ??= [];
          dataProvider.tournament!.categorias![index].players!.add(player);
          final categoria = dataProvider.tournament!.categorias![index];
          final List<Categoria> otherCategorias = dataProvider.tournament!.categorias!.where((c) => c.nome != categoria.nome).toList();
          for(Categoria categoria in otherCategorias) {
            if(categoria.players?.contains(player) ?? false) {
              categoria.players!.remove(player);
            }
          }
        }
        return;
      }
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dataProvider.carregarTorneio(widget.tournamentName).whenComplete(() {
        if(dataProvider.tournament == null) {
          GoRouter.of(context).go('/');
          return;
        }
        players = dataProvider.tournament!.jogadores ?? [];
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
          case 2: return setState(() => fatorDeAjusteList = [0.5, 1]);
          case 3: return setState(() => fatorDeAjusteList = [0.3, 0.4, 0.75]);
          case 4: return setState(() => fatorDeAjusteList = [0.3, 0.4, 0.7, 0.9]);
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Fase classificatória'),
        actions: [
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

          if(value.tournament == null || value.players.isEmpty) {
            return const SizedBox(
              child: Text('NAO FOI POSSIVEL INICIAR O TORNEIO'),
            );
          }

          return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      if(partidas.isNotEmpty && partidas.every((partida) => partida.finished ?? false))
                        ElevatedButton(
                            onPressed: () {
                              setState(() {
                                partidas = [];
                                listaDeDuplas = [];
                                currentRound++;
                                currentMatch = 0;
                                _controller.jumpToPage(0);
                              });
                              generate2x2game(misto: dataProvider.tournament?.misto ?? false);
                            },
                            child: const Text('+1 rodada')
                        ),
                      if(partidas.isEmpty)
                        Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(onPressed: () => generate2x2game(misto: dataProvider.tournament?.misto ?? false), child: const Text('Gerar times'))
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Spacer(),
                                Text('Rodada ${currentRound + 1}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                                Padding(
                                  padding: const EdgeInsets.only(left: 24.0, right: 8),
                                  child: Text('${partidas.where((p) => p.finished == true).length} jogos finalizados'),
                                )
                              ],
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
                            SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight * .9,
                              child: PageView.builder(
                                controller: _controller,
                                onPageChanged: (page) => setState(() => currentMatch = page),
                                itemCount: partidas.length,
                                itemBuilder: (context, index) {
                                  final team1 = partidas[index].team1;
                                  final team2 = partidas[index].team2;

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Column(
                                        children: [
                                          if(partidas[index].vencedor != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 24.0),
                                              child: Text(
                                                'Vencedor: ${partidas[index].vencedor == 0 ? 'TIME A' : 'TIME B'}',
                                                style: Theme.of(context).textTheme.titleLarge,
                                              ),
                                            )
                                        ],
                                      ),
                                      PartidaItem(team1: team1!, team2: team2!, partida: partidas[index]),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => SetWinnerMobileDialog(partida: partidas[index])).then((res) {
                                              _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                                                if(res is List) {
                                                  setState(() {
                                                    updatePlayerGames(team1);
                                                    updatePlayerGames(team2);
                                                    partidas[index].finished = true;
                                                    partidas[index].vencedor = res[0] ? 0 : 1;
                                                    if(res[1]) {
                                                      if(res[0]) {
                                                        for(var player in team1) {
                                                          player.pontosAtuais = (player.pontosAtuais ?? 0) + 1;
                                                          updatePlayerRank(player);
                                                        }
                                                        for(var player in team2) {
                                                          updatePlayerRank(player);
                                                        }
                                                      }else {
                                                        for(var player in team1) {
                                                          updatePlayerRank(player);
                                                        }
                                                        for(var player in team2) {
                                                          player.pontosAtuais = (player.pontosAtuais ?? 0) + 1;
                                                          updatePlayerRank(player);
                                                        }
                                                      }
                                                    }
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
                                          child: partidas[index].vencedor != null ? const Text('EDITAR') : const Text('MARCAR RESULTADO')
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
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
                                    Text(player.partidasJogadas!.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                    Text('${player.pontos}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10.0),
                                      child: Text(((player.pontosAtuais ?? 0) / (player.partidasJogadas ?? 0)).toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
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
                                Text('Categorias', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for(var i = 0; i < dataProvider.tournament!.categorias!.length; i++)
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Text(dataProvider.tournament!.categorias![i].nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
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
                                          )
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Histórico de jogos', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          for(var i = 0; i < partidasHistory.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                '${partidasHistory[i].team1![0].nome} e ${partidasHistory[i].team1![1].nome} x ${partidasHistory[i].team2![0].nome} e ${partidasHistory[i].team2![1].nome}'
                              ),
                            )
                        ],
                      )
                    ],
                  ),
                );
              }
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
  const PartidaItem({super.key, required this.team1, required this.team2, required this.partida});

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
        Transform.scale(
          scale: .9,
          child: ElevatedButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditPlayersDialog(team: widget.team1, otherTeam: widget.team2)
              ).then((players) {
                if(players != null && players is List) {
                  setState(() {
                    widget.team1[0] = players[0];
                    widget.team1[1] = players[1];
                  });
                }
              }),
              style: ElevatedButton.styleFrom(
                  fixedSize: const Size(150, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
              ),
              child: const Text('EDITAR TIME A')
          ),
        ),
        const SizedBox(height: 8),
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
                child: Icon(FontAwesome5Solid.medal, size: 24,),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
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
        const SizedBox(height: 8),
        Transform.scale(
          scale: .9,
          child: ElevatedButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditPlayersDialog(team: widget.team2, otherTeam: widget.team1)
              ).then((players) {
                if(players != null && players is List) {
                  setState(() {
                    widget.team2[0] = players[0];
                    widget.team2[1] = players[1];
                  });
                }
              }),
              style: ElevatedButton.styleFrom(
                  fixedSize: const Size(150, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
              ),
              child: const Text('EDITAR TIME B')
          ),
        ),
      ],
    );
  }
}