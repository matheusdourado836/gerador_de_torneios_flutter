import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'package:volleyball_tournament_app/pages/tournament/edit_players_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/set_winner_dialog.dart';
import '../../model/partida.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final PageController _controller = PageController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  List<Player> players = [];
  List<List<Player>> listaDeDuplas = [];
  List<Partida> partidas = [];
  List<List<Partida>> partidasDivided = [];
  int playersBySide = 0;
  int qtdRounds = 0;
  int currentRound = 0;

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
      partidasDivided = dividirPartidasEmRodadas();
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
    players = dataProvider.tournament!.jogadores ?? [];
    playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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

          return PageView(
            controller: _controller,
            children: [
              SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      Text('${currentRound + 1}ª Rodada', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold),),
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
                        )
                      else
                        SizedBox(
                        width: MediaQuery.sizeOf(context).width * .6,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: partidasDivided[currentRound].length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final team1 = partidasDivided[currentRound][index].team1;
                            final team2 = partidasDivided[currentRound][index].team2;
                
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('Partida ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      PartidaItem(team1: team1!, team2: team2!, partida: partidasDivided[currentRound][index])
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) => SetWinnerDialog(partida: partidasDivided[currentRound][index])).then((res) {
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
                                        backgroundColor: partidasDivided[currentRound][index].vencedor != null ? Colors.blue : const Color.fromRGBO(42, 35, 42, 1)
                                    ),
                                    child: partidasDivided[currentRound][index].vencedor != null ? const Text('EDITAR') : const Text('FINALIZAR')
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
              Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * .6,
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
          );
        },
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
              IconButton(
                  padding: const EdgeInsets.only(left: 16),
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
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            'X',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.partida.finished ?? false ? 18 : 20,
              color: widget.partida.finished ?? false ? Colors.black54 : Colors.black
            )
          ),
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
              IconButton(
                  padding: const EdgeInsets.only(left: 16),
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
                  icon: const Icon(Icons.edit)
              ),
            ],
          ),
        ),
      ],
    );
  }
}
