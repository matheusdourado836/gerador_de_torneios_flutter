import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:volleyball_tournament_app/pages/tournament/edit_players_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/set_winner_dialog.dart';
import 'model/partida.dart';
import 'model/player.dart';

class Teste extends StatefulWidget {
  const Teste({super.key});

  @override
  State<Teste> createState() => _TesteState();
}

class _TesteState extends State<Teste> {
  final PageController _controller = PageController();
  List<Partida> partidas = [];
  List<List<Player>> listaDeDuplas = [];
  int playersBySide = 0;
  int qtdRounds = 0;
  int currentRound = 1;

  void generate2x2game() {
    List<Partida> innerPartidas = [];
    combinations(2);
    Set<String> duplasUsadas = {};

    for (int i = 0; i < listaDeDuplas.length; i++) {
      for (int j = i + 1; j < listaDeDuplas.length; j++) {
        List<String> time1 = listaDeDuplas[i].map((dupla) => dupla.nome!).toList();
        List<String> time2 = listaDeDuplas[j].map((dupla) => dupla.nome!).toList();

        if (time1.toSet().intersection(time2.toSet()).isEmpty) {
          // Cria chaves para as duplas
          String chaveTime1 = time1.join(',');
          String chaveTime2 = time2.join(',');

          // Verifica se as duplas já jogaram
          if (!duplasUsadas.contains(chaveTime1) && !duplasUsadas.contains(chaveTime2)) {
            innerPartidas.add(Partida(team1: listaDeDuplas[i], team2: listaDeDuplas[j]));
            updatePlayerGames(listaDeDuplas[i]);
            updatePlayerGames(listaDeDuplas[j]);
            duplasUsadas.add(chaveTime1);
            duplasUsadas.add(chaveTime2);
          }
        }
      }
    }

    setState(() {
      partidas = innerPartidas;
      partidas.shuffle();
    });
  }

  void combinations(int r) {
    List<List<Player>> innerListaDeDuplas = [];
    listaDeDuplas = [];
    void combine(List<Player> combo, int start) {
      if (combo.length == r) {
        innerListaDeDuplas.add(List.from(combo));
        return;
      }

      for (int i = start; i < players.length; i++) {
        combo.add(players[i]);
        combine(combo, i + 1);
        combo.removeLast();
      }
    }
    combine([], 0);
    setState(() => listaDeDuplas = innerListaDeDuplas);
  }

  void updatePlayerGames(List<Player> team) {
    for (var player in team) {
      player.partidasJogadas = (player.partidasJogadas ?? 0) + 1;
    }
    setState(() => team);
  }

  @override
  void initState() {
    generate2x2game();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: PageView(
        controller: _controller,
        children: [
          Center(
            child: Container(
              color: Colors.deepPurple,
              child: SizedBox(
                width: 600,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: partidas.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final team1 = partidas[index].team1;
                    final team2 = partidas[index].team2;

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Partida ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              PartidaItem(
                                  team1: team1!,
                                  team2: team2!,
                                  partida: partidas[index]
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => SetWinnerDialog(partida: partidas[index])).then((res) {
                                if(res is List) {
                                  setState(() {
                                    partidas[index].finished = true;
                                    partidas[index].vencedor = res[0] ? 0 : 1;
                                    if(res[1]) {
                                      if(res[0]) {
                                        for(var player in team1) {
                                          player.pontos = (player.pontos ?? 0) + 1;
                                        }
                                      }else {
                                        for(var player in team2) {
                                          player.pontos = (player.pontos ?? 0) + 1;
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
                                fixedSize: const Size(118, 40),
                                backgroundColor: partidas[index].vencedor != null ? Colors.blue : const Color.fromRGBO(42, 35, 42, 1)
                            ),
                            child: partidas[index].vencedor != null ? const Text('EDITAR') : const Text('FINALIZAR')
                        )
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .7,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 210, child: Text('Nome', style: Theme.of(context).textTheme.titleLarge)),
                      SizedBox(
                        width: 200,
                          child: Text('Partidas jogadas', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,)
                      ),
                      Text('Pontos', style: Theme.of(context).textTheme.titleLarge)
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
                              width: 150,
                              child: Text(player.nome!)
                          ),
                          SizedBox(width: 200, child: Text(player.partidasJogadas!.toString(), textAlign: TextAlign.center,)),
                          Text('${player.pontos}', style: const TextStyle(fontWeight: FontWeight.bold),)
                        ],),
                    )
                    ).toList(),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          if(_controller.page == 0) {
            _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
          }else {
            _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
          }
        },
        child: const Text('Jogadores')
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
      return const TextStyle(color: Colors.black54, fontSize: 16);
    }

    return const TextStyle(color: Colors.black, fontSize: 18);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            IconButton(
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
                icon: const Icon(Icons.edit)
            ),
            SizedBox(
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
                    )
                ],
              ),
            ),
          ],
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
          height: 60,
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.team2.map((p) => Text(p.nome ?? '', style: style())).toList(),
              ),
              if(widget.partida.vencedor == 1)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Icon(FontAwesome5Solid.medal),
                )
            ],
          ),
        ),
      ],
    );
  }
}

List<Player> players = [
  Player.withName('MatheusComBumBum', 0),
  Player.withName('Pedro', 0),
  Player.withName('Joao', 0),
  Player.withName('Ricardo', 0),
  Player.withName('Victor', 0),
  Player.withName('Diego', 0),
  Player.withName('Luis', 0),
  Player.withName('Marcos', 0),
  Player.withName('Andre', 0),
  Player.withName('Daniel', 0),
];