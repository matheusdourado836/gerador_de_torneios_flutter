import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/tournament.dart';
import 'package:volleyball_tournament_app/pages/tournament/edit_players_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/set_winner_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/set_winner_mobile_dialog.dart';
import '../../controller/data_controller.dart';
import '../../model/partida.dart';
import '../../model/player.dart';

class TesteMobile extends StatefulWidget {
  const TesteMobile({super.key});

  @override
  State<TesteMobile> createState() => _TesteMobileState();
}

class _TesteMobileState extends State<TesteMobile> {
  final PageController _controller = PageController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  //List<Player> players = [];
  List<List<Player>> listaDeDuplas = [];
  List<Partida> partidas = [];
  List<List<Partida>> partidasDivided = [];
  int playersBySide = 0;
  int qtdRounds = 0;
  int currentRound = 0;
  List<double> fatorDeAjusteList = [];

  void generate2x2game({bool misto = false}) {
    List<Partida> innerPartidas = [];
    combinations(2, misto: misto);
    Set<String> duplasUsadas = {};

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
      partidas.shuffle();
      //partidasDivided = dividirPartidasEmRodadas();
      partidasDivided[currentRound].shuffle();
    });
  }

  void combinations(int r, {bool misto = false}) {
    listaDeDuplas = [];

    if (misto) {
      // Separar jogadores por sexo
      List<Player> homens = players.where((p) => p.sex == null || p.sex == 0).toList();
      List<Player> mulheres = players.where((p) => p.sex == 1).toList();

      // Criar combinações entre homens e mulheres
      for (var homem in homens) {
        for (var mulher in mulheres) {
          listaDeDuplas.add([homem, mulher]);
        }
      }
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


  List<List<Partida>> dividirPartidasEmRodadas() {
    List<List<Partida>> rodadas = [];
    int totalPartidas = partidas.length;

    // Calcular o número de rodadas
    int numeroDeRodadas = (totalPartidas / 10).ceil();

    // Dividir as partidas entre as rodadas
    int indexPartida = 0;
    for (int i = 0; i < numeroDeRodadas; i++) {
      int partidasNestaRodada = (i < totalPartidas % numeroDeRodadas)
          ? (totalPartidas ~/ numeroDeRodadas) + 1
          : totalPartidas ~/ numeroDeRodadas;

      List<Partida> rodadaAtual = [];
      for (int j = 0; j < partidasNestaRodada && indexPartida < totalPartidas; j++) {
        rodadaAtual.add(partidas[indexPartida]);
        indexPartida++;
      }
      rodadas.add(rodadaAtual);
    }


    return rodadas;
  }

  void updatePlayerGames(List<Player> team) {
    for (var player in team) {
      final playerFromList = players.firstWhere((p) => p.nome == player.nome);
      playerFromList.partidasJogadas = (playerFromList.partidasJogadas ?? 0) + 1;
    }
    setState(() => players);
  }

  @override
  void initState() {
    //playersBySide = int.parse(dataProvider.tournament?.qtdJogadoresEmCampo!.split('x')[0] ?? '0');
    // partidasDivided.add([
    //   Partida(
    //     team1: [players[0], players[2]],
    //     team2: [players[1], players[3]],
    //   ),
    //   Partida(
    //     team1: [players[4], players[5]],
    //     team2: [players[6], players[7]],
    //   ),
    //   Partida(
    //     team1: [players[8], players[9]],
    //     team2: [players[0], players[2]],
    //   ),
    //   Partida(
    //     team1: [players[1], players[4]],
    //     team2: [players[6], players[2]],
    //   ),
    //   Partida(
    //     team1: [players[7], players[4]],
    //     team2: [players[8], players[5]],
    //   ),
    // ],);
    dataProvider.tournament = Tournament(
      categorias: [
        Categoria(
          nome: 'Amador',
          nivelCategoria: 'Iniciante',
          players: []
        ),
        Categoria(
            nome: 'Profissional',
            nivelCategoria: 'Profissional',
          players: []
        ),
        Categoria(
            nome: 'Mediano',
            nivelCategoria: 'Amador',
          players: []
        ),
      ],
      jogadores: players
    );
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
      case 3: return setState(() => fatorDeAjusteList = [0.3, 0.4, 0.8]);
      case 4: return setState(() => fatorDeAjusteList = [0.3, 0.4, 0.7, 0.9]);
    }
    super.initState();
  }

  void updatePlayerRank(Player player) {
    for(double fatorDeAjuste in fatorDeAjusteList) {
      final playerMedia = (player.pontos ?? 0) / (player.partidasJogadas ?? 0);
      if(playerMedia >= fatorDeAjuste) {
        final index = fatorDeAjusteList.indexOf(fatorDeAjuste);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    partidasDivided.add([
      Partida(
        team1: [players[0], players[2]],
        team2: [players[1], players[3]],
      ),
      Partida(
        team1: [players[4], players[5]],
        team2: [players[6], players[7]],
      ),
      Partida(
        team1: [players[8], players[9]],
        team2: [players[0], players[2]],
      ),
      Partida(
        team1: [players[1], players[4]],
        team2: [players[6], players[2]],
      ),
      Partida(
        team1: [players[7], players[4]],
        team2: [players[8], players[5]],
      ),
    ],);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Fase classificatória'),
      ),
      body: Consumer<DataController>(
        builder: (context, value, _) {
          if(value.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    if(partidasDivided.isNotEmpty && partidasDivided[currentRound].every((partida) => partida.finished ?? false))
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              partidas = [];
                              listaDeDuplas = [];
                              currentRound++;
                              partidasDivided[currentRound].shuffle();
                            });
                          },
                          child: const Text('Próxima rodada')
                      ),
                    if(partidasDivided.isEmpty)
                      Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(onPressed: () => generate2x2game(misto: dataProvider.tournament?.misto ?? false), child: const Text('Gerar times'))
                      )else
                        SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: partidasDivided[currentRound].length,
                            itemBuilder: (context, index) {
                              final team1 = partidasDivided[currentRound][index].team1;
                              final team2 = partidasDivided[currentRound][index].team2;

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'Jogo ${index + 1} de ${partidasDivided[currentRound].length}',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.titleLarge
                                      ),
                                      if(partidasDivided[currentRound][index].vencedor != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 24.0),
                                          child: Text(
                                            'Vencedor: ${partidasDivided[currentRound][index].vencedor == 0 ? 'TIME A' : 'TIME B'}',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                        )
                                    ],
                                  ),
                                  PartidaItem(team1: team1!, team2: team2!, partida: partidasDivided[currentRound][index]),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) => SetWinnerMobileDialog(partida: partidasDivided[currentRound][index])).then((res) {
                                            if(res is List) {
                                              setState(() {
                                                updatePlayerGames(team1);
                                                updatePlayerGames(team2);
                                                partidasDivided[currentRound][index].finished = true;
                                                partidasDivided[currentRound][index].vencedor = res[0] ? 0 : 1;
                                                if(res[1]) {
                                                  if(res[0]) {
                                                    for(var player in team1) {
                                                      player.pontos = (player.pontos ?? 0) + 1;
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
                                                      player.pontos = (player.pontos ?? 0) + 1;
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
                                            backgroundColor: partidasDivided[currentRound][index].vencedor != null ? Colors.blue : const Color.fromRGBO(42, 35, 42, 1)
                                        ),
                                        child: partidasDivided[currentRound][index].vencedor != null ? const Text('EDITAR') : const Text('FINALIZAR')
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                        child: Column(
                          children: [
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 190,
                                  child: Text('Nome', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16))
                                ),
                                Text('Jogos', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16), textAlign: TextAlign.center,),
                                Text('Pontos', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16))
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
                                        width: 165,
                                        child: Text(player.nome!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)
                                    ),
                                    Text(player.partidasJogadas!.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 18.0),
                                      child: Text('${player.pontos}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                    )
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
                                          Text(dataProvider.tournament!.categorias![i].nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: 100,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: dataProvider.tournament?.categorias?[i].players?.length ?? 0,
                                              itemBuilder: (context, index) {
                                                final player = dataProvider.tournament?.categorias?[i].players![index];
                                                //final player = Player(nome: 'MatheusComBumBum');
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 16.0),
                                                  child: Text(player!.nome!, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,),
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
                    )
                  ],
                ),
              );
            }
          );
        },
      ),
      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          fixedSize: const Size(150, 30)
        ),
          onPressed: () {},
          child: const Text('Próxima fase')
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
            child: const Text('EDITAR TIME A')
          ),
        ),
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
            child: const Text('EDITAR TIME B')
          ),
        ),
      ],
    );
  }
}

List<Player> players = [
  Player.withName('MatheusComBumBum', 0),
  Player.withName('MatheusSemBumBum', 0),
  Player.withName('Pedro', 1),
  Player.withName('Joao', 0),
  Player.withName('Ricardo', 1),
  Player.withName('Victor', 0),
  Player.withName('Diego', 1),
  Player.withName('Luis', 0),
  Player.withName('Marcos', 1),
  Player.withName('Andre', 0),
  Player.withName('Daniel', 1),
];