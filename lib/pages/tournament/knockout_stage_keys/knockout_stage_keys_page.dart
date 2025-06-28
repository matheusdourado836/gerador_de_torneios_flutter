import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/model/etapas.dart';
import 'package:volleyball_tournament_app/model/tournament.dart';
import 'package:volleyball_tournament_app/pages/tournament/matches_categoria/matches_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/set_winner_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/set_winner_mobile_dialog.dart';
import '../../../controller/data_controller.dart';
import '../../../model/categoria.dart';
import '../../../model/partida.dart';
import '../../../model/player.dart';
import 'package:collection/collection.dart';

class KnockoutStageKeysPage extends StatefulWidget {
  const KnockoutStageKeysPage({super.key});

  @override
  State<KnockoutStageKeysPage> createState() => _KnockoutStageKeysPageState();
}

class _KnockoutStageKeysPageState extends State<KnockoutStageKeysPage> {
  final PageController _controller = PageController(initialPage: 0);
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  List<List<Player>> jogadoresClassificados = [];
  List<List<Player>> jogadoresDesclassificados = [];
  List<String> models = ['Oitavas', 'Quartas', 'Semifinal'];
  String selectedModel = '';
  Fase selectedStage = Fase(nome: 'Oitavas', partidas: List.generate(15, (i) => Partida(), growable: false));
  Fase oitavas = Fase(nome: 'Oitavas', partidas: List.generate(8, (i) => Partida(), growable: false));
  Fase quartas = Fase(nome: 'Quartas', partidas: List.generate(4, (i) => Partida(), growable: false));
  Fase semi = Fase(nome: 'Semi', partidas: List.generate(2, (i) => Partida(), growable: false));
  Fase finalMatch = Fase(nome: 'Final', partidas: List.generate(1, (i) => Partida(), growable: false));
  int currentPage = 0;
  bool loadedFromBd = false;
  bool? _admin;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(dataProvider.tournament!.selectedStage != null) {
        loadedFromBd = true;
        dataProvider.getClassifiedPlayers().whenComplete(() {
          if(dataProvider.tournament!.selectedStage!.fases.keys.length == 4) {
            selectedModel = 'Oitavas';
            currentPage = 0;
            oitavas = Fase.fromJson(dataProvider.tournament!.selectedStage!.fases["Oitavas de final"]);
            quartas = Fase.fromJson(dataProvider.tournament!.selectedStage!.fases["Quartas de final"]);
          }else if(dataProvider.tournament!.selectedStage!.fases.keys.length == 3) {
            currentPage = 1;
            selectedModel = 'Quartas';
            quartas = Fase.fromJson(dataProvider.tournament!.selectedStage!.fases["Quartas de final"]);
          }else {
            currentPage = 2;
            selectedModel = 'Semifinal';
          }
          semi = Fase.fromJson(dataProvider.tournament!.selectedStage!.fases["Semifinal"]);
          finalMatch = Fase.fromJson(dataProvider.tournament!.selectedStage!.fases["Final"]);
          jogadoresClassificados = dataProvider.tournament!.timesClassificados?.map((t) => t.players).toList() ?? [];
          setState(() {});
        });
      }else {
        selectedStage = Fase(nome: models[currentPage], partidas: List.generate(15, (i) => Partida(), growable: false));
        _controller.jumpToPage(0);
      }
    });
    // for(var player in players) {
    //   int randomPoints = Random().nextInt(4) + 1;
    //   int randomjogos = Random().nextInt(4) + 1;
    //   player.totalJogos ??= 0;
    //   player.pontosAtuais ??= 0;
    //   player.totalJogos = randomjogos;
    //   player.pontosAtuais = randomPoints;
    // }
    // dataProvider.tournament = Tournament(
    //   chaves: [
    //     Chave(
    //         nome: 'Chave A',
    //         times: {
    //           "time1": [
    //             players[0],
    //             players[1]
    //           ],
    //           "time2": [
    //             players[2],
    //             players[3]
    //           ],
    //           "time3": [
    //             players[4],
    //             players[5]
    //           ]
    //         }
    //     ),
    //     Chave(
    //         nome: 'Chave b',
    //         times: {
    //           "time1": [
    //             players[6],
    //             players[7]
    //           ],
    //           "time2": [
    //             players[8],
    //             players[9]
    //           ],
    //           "time3": [
    //             players[10],
    //             players[11]
    //           ]
    //         }
    //     ),
    //   ]
    // );
    super.initState();
  }

  void updateBdData() {
    Map<String, dynamic> stageMap = {};
    if(selectedModel == 'Oitavas') {
      stageMap = {
        "Oitavas de final" : oitavas.toJson(),
        "Quartas de final": quartas.toJson(),
        "Semifinal": semi.toJson(),
        "Final": finalMatch.toJson()
      };
    }else if(selectedModel == 'Quartas') {
      stageMap = {
        "Quartas de final": quartas.toJson(),
        "Semifinal": semi.toJson(),
        "Final": finalMatch.toJson()
      };
    }else {
      stageMap = {
        "Semifinal": semi.toJson(),
        "Final": finalMatch.toJson()
      };
    }
    dataProvider.updateTorneioData({"selectedStage": stageMap}, dataProvider.tournament!.id!);
  }

  bool classificarJogadoresProximaFase({required List<Player> team, required Fase proximaFase}) {
    final tempTeamList = List<Player>.from(team);
    for (var partida in proximaFase.partidas) {
      if (partida.team1?.isEmpty ?? true) {
        partida.team1 = tempTeamList;
        updateBdData();
        return true;
      } else if (partida.team2?.isEmpty ?? true) {
        partida.team2 = tempTeamList;
        updateBdData();
        return true;
      }
    }

    return false;
  }

  void desclassificarUmTime(List<Player> team) {
    final tempTeamList = List<Player>.from(team);
    dataProvider.disqualifyTeam(players: team);
    final List<Fase> fases = [
      oitavas,
      quartas,
      semi,
      finalMatch
    ];

    for(Fase fase in fases) {
      for(var partida in fase.partidas) {
        final tempJson = tempTeamList.map((p) => p.toJson()).toList();
        final t1Json = partida.team1?.map((p) => p.toJson()).toList() ?? [];
        final t2Json = partida.team2?.map((p) => p.toJson()).toList() ?? [];
        if(partida.team1 != null && const DeepCollectionEquality().equals(t1Json, tempJson)) {
          partida.team1!.clear();
          updateBdData();
        }else if(partida.team2 != null && const DeepCollectionEquality().equals(t2Json, tempJson)) {
          partida.team2!.clear();
          updateBdData();
        }
      }
    }
  }

  void reset() {
    setState(() {
      loadedFromBd = false;
      selectedModel = '';
      jogadoresClassificados = [];
      jogadoresDesclassificados = [];
      oitavas = Fase(nome: 'Oitavas', partidas: List.generate(8, (i) => Partida(), growable: false));
      quartas = Fase(nome: 'Quartas', partidas: List.generate(4, (i) => Partida(), growable: false));
      semi = Fase(nome: 'Semi', partidas: List.generate(2, (i) => Partida(), growable: false));
      finalMatch = Fase(nome: 'Final', partidas: List.generate(1, (i) => Partida(), growable: false));
      updateBdData();
    });
  }

  Widget stageByType() {
    if(selectedModel == 'Oitavas') {
      return _oitavasWidget();
    }else if(selectedModel == 'Quartas') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: _quartasWidget(showDecoration: true),
      );
    }else {
      return _semiWidget(showDecoration: true);
    }
  }

  Widget teamRow(List<Player>? team) {
    if(team?.isEmpty ?? true) {
      return const Text(
          'N/A',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white)
      );
    }else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: team!.map((p) => Text(
            p.nome!,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white)
        )).toList(),
      );
    }
  }

  Widget gameBlock(Partida partida, {required Fase proximaFase, double height = 140, double width = 160}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(border: Border.all()),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: partida.vencedor == null
              ? 1
              : partida.vencedor! == 0 ? 1 : .4,
          child: Container(
            width: width,
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(8),
            child: teamRow(partida.team1),
          ),
        ),
        if((partida.team1?.isNotEmpty ?? false) && (partida.team2?.isNotEmpty ?? false))
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(partida.vencedor == null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(fixedSize: const Size(100, 40)),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => SetWinnerDialog(partida: partida)
                  ).then((res) {
                    if(res is List) {
                      if(res[0] ?? false) {
                        final team1 = partida.team1!;
                        partida.vencedor = 0;
                        classificarJogadoresProximaFase(team: team1, proximaFase: proximaFase);
                      }else {
                        final team2 = partida.team2!;
                        partida.vencedor = 1;
                        classificarJogadoresProximaFase(team: team2, proximaFase: proximaFase);
                      }
                      setState(() {});
                    }
                  }),
                  child: const Text('FINALIZAR', style: TextStyle(fontSize: 10))
                )
              else
                const Text('FINALIZADO')
            ],
          ),
        Opacity(
          opacity: partida.vencedor == null
            ? 1
            : partida.vencedor! == 0 ? .4 : 1,
          child: Container(
            width: width,
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(8),
            child: teamRow(partida.team2)
          ),
        ),
      ],
    ),
  );

  Widget _oitavasWidget() {
    const width = 120.0;
    return Container(
     padding: const EdgeInsets.only(left: 12.0),
     margin: const EdgeInsets.all(16.0),
     decoration: BoxDecoration(border: Border.all()),
     child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Padding(
           padding: const EdgeInsets.only(bottom: 12.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 children: [
                   const Text('Oitavas', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   gameBlock(oitavas.partidas[0], width: width, proximaFase: quartas),
                   const SizedBox(height: 24),
                   gameBlock(oitavas.partidas[1], width: width, proximaFase: quartas)
                 ],
               ),
               Column(
                 children: [
                   gameBlock(oitavas.partidas[2], width: width, proximaFase: quartas),
                   const SizedBox(height: 24),
                   gameBlock(oitavas.partidas[3], width: width, proximaFase: quartas)
                 ],
               ),
             ],
           ),
         ),
         _quartasWidget(width: width),
         Padding(
           padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 children: [
                   const Text('Oitavas', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   gameBlock(oitavas.partidas[4], width: width, proximaFase: quartas),
                   const SizedBox(height: 24),
                   gameBlock(oitavas.partidas[5], width: width, proximaFase: quartas)
                 ],
               ),
               Column(
                 children: [
                   gameBlock(oitavas.partidas[6], width: width, proximaFase: quartas),
                   const SizedBox(height: 24),
                   gameBlock(oitavas.partidas[7], width: width, proximaFase: quartas)
                 ],
               ),
             ],
           ),
         )
       ],
     ),
   );
  }

  Widget _quartasWidget({double height = 140, double width = 160, bool showDecoration = false}) {
    BoxDecoration? decoration = !showDecoration ? null : BoxDecoration(
        border: Border.all()
    );
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text('Quartas', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    gameBlock(quartas.partidas[0], height: height, width: width, proximaFase: semi)
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: gameBlock(quartas.partidas[1], height: height, width: width, proximaFase: semi),
                ),
              ],
            ),
            _semiWidget(height: height, width: width),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text('Quartas', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    gameBlock(quartas.partidas[2], height: height, width: width, proximaFase: semi)
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: gameBlock(quartas.partidas[3], height: height, width: width, proximaFase: semi),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _semiWidget({double height = 140, double width = 160, bool showDecoration = false}) {
    BoxDecoration? decoration = !showDecoration
      ? null
      : BoxDecoration(border: Border.all());
    int lastIndex = semi.partidas.length - 1;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: decoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Semifinal', style: TextStyle(fontWeight: FontWeight.bold)),
              gameBlock(semi.partidas[0], height: 210, width: width, proximaFase: finalMatch),
              const SizedBox.shrink()
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Final', style: TextStyle(fontWeight: FontWeight.bold)),
                gameBlock(finalMatch.partidas[0], height: height, width: width, proximaFase: finalMatch),
                const SizedBox.shrink()
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Semifinal', style: TextStyle(fontWeight: FontWeight.bold)),
              gameBlock(semi.partidas[1], height: 210, width: width, proximaFase: finalMatch),
              const SizedBox.shrink()
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificar jogadores'),
        actions: [
          TextButton(
              onPressed: () {
                context.go(context.namedLocation('podium', pathParameters: {"nomeDoTorneio": dataProvider.tournament!.nomeTorneio!}));
              },
              child: const Text('ACTION')
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

          return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                  onPressed: selectedModel.isNotEmpty ? null : () => _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded)
                              ),
                              Text(models[currentPage]),
                              IconButton(
                                  onPressed: selectedModel.isNotEmpty ? null : () => _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                                  icon: const Icon(Icons.arrow_forward_ios_rounded)
                              ),
                            ],
                          ),
                          ChoiceChip(
                            label: const Text('Salvar'),
                            selected: selectedModel.isNotEmpty,
                            onSelected: (value) {
                              setState(() => selectedModel = models[currentPage]);
                              Map<String, dynamic> stageMap = {};
                              if(selectedModel == 'Oitavas') {
                                stageMap = {
                                  "Oitavas de final" : oitavas.toJson(),
                                  "Quartas de final": quartas.toJson(),
                                  "Semifinal": semi.toJson(),
                                  "Final": finalMatch.toJson()
                                };
                              }else if(selectedModel == 'Quartas') {
                                stageMap = {
                                  "Quartas de final": quartas.toJson(),
                                  "Semifinal": semi.toJson(),
                                  "Final": finalMatch.toJson()
                                };
                              }else {
                                stageMap = {
                                  "Semifinal": semi.toJson(),
                                  "Final": finalMatch.toJson()
                                };
                              }
                              dataProvider.updateTorneioData(
                                  {"selectedStage": stageMap},
                                  dataProvider.tournament!.id!
                              );
                              setState(() {});
                            },
                          ),
                          if(selectedModel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ActionChip(
                                  onPressed: () => reset(),
                                  backgroundColor: Colors.red,
                                  label: const Text('Resetar', style: TextStyle(color: Colors.white),)
                              ),
                            )
                        ],
                      ),
                      if(selectedStage.partidas.last.vencedor != null)
                        _ThirdPlaceMatch(
                          semiFinal: [
                            selectedStage.partidas[selectedStage.partidas.length - 2],
                            selectedStage.partidas[selectedStage.partidas.length - 3]
                          ],
                          admin: _admin,
                        )
                      else
                        SizedBox(
                          height: constraints.maxHeight,
                          width: constraints.maxWidth,
                          child: (loadedFromBd) ? stageByType() : PageView(
                            controller: _controller,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (page) => setState(() => currentPage = page),
                            children: [
                              _oitavasWidget(),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: _quartasWidget(showDecoration: true),
                              ),
                              _semiWidget(showDecoration: true)
                            ],
                          ),
                        ),
                      if(selectedModel.isNotEmpty)
                        SizedBox(
                          height: constraints.maxHeight,
                          width: constraints.maxWidth * .9,
                          child: ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dataProvider.tournament!.chaves!.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final chave = dataProvider.tournament!.chaves![index];
                                return Column(
                                  children: [
                                    Text(chave.nome!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Column(
                                      children: [
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            SizedBox(
                                                width: 150,
                                                child: Text('Nome', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))
                                            ),
                                            SizedBox(
                                                width: 80,
                                                child: Text(
                                                    'Pontos',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(fontWeight: FontWeight.bold)
                                                )
                                            ),
                                            Text('Media', style: TextStyle(fontWeight: FontWeight.bold)),
                                            SizedBox(width: 245)
                                          ],
                                        ),
                                        Column(
                                          children: chave.times.values.map((time) {
                                            // Obtenha os IDs do time atual
                                            final timeId = time.map((p) => p.id!).toList();

                                            // Obtenha os IDs dos times classificados
                                            final classifiedsId = jogadoresClassificados
                                                .map((t) => t.map((p) => p.id!).toList())
                                                .toList();

                                            final teamIsClassified = classifiedsId.any((classifiedTeam) =>
                                                classifiedTeam.toSet().containsAll(timeId.toSet()));

                                            final teamIsDisqualified = !classifiedsId.any((classifiedTeam) =>
                                                classifiedTeam.toSet().containsAll(timeId.toSet()));

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 16.0),
                                              child: Opacity(
                                                opacity: teamIsClassified ? .4 : 1,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    // Exibição dos jogadores do time
                                                    SizedBox(
                                                      width: 180,
                                                      child: Column(
                                                        children: time
                                                            .map((p) => Text(
                                                          p.nome!,
                                                          overflow: TextOverflow.ellipsis,
                                                          textAlign: TextAlign.center,
                                                        ))
                                                            .toList(),
                                                      ),
                                                    ),
                                                    // Pontuação e cálculo
                                                    SizedBox(
                                                      width: 100,
                                                      child: Text(
                                                        '(${time.first.pontosAtuais ?? 0}) ',
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                    Text(
                                                      '(${((time.first.pontosAtuais ?? 0) / (time.first.totalJogos ?? 1)).toStringAsFixed(2)}) ',
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    // Ações com ChoiceChips
                                                    SizedBox(
                                                      width: 265,
                                                      child: Row(
                                                        children: [
                                                          // Classificar
                                                          ChoiceChip(
                                                            onSelected: (value) {
                                                              if (!teamIsClassified) {
                                                                final proximaFase = selectedModel == 'Oitavas' ? oitavas : selectedModel == 'Quartas' ? quartas : semi;
                                                                final res = classificarJogadoresProximaFase(team: time, proximaFase: proximaFase);
                                                                if (!res) {
                                                                  showDialog(
                                                                    context: context,
                                                                    builder: (context) => AlertDialog(
                                                                      title: const Text('Alerta'),
                                                                      content: const Text(
                                                                          'Não é possível fazer mais classificações'),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(context),
                                                                          child: const Text('OK'),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  );
                                                                  return;
                                                                }
                                                                dataProvider.addToClassifiedTeams(players: time);
                                                                jogadoresClassificados.add(time);
                                                              }
                                                              if (teamIsDisqualified) {
                                                                jogadoresDesclassificados.remove(time);
                                                              }
                                                              setState(() {});
                                                            },
                                                            label: const Text('Classificar'),
                                                            selected: teamIsClassified,
                                                          ),
                                                          const SizedBox(width: 16),
                                                          // Desclassificar
                                                          ChoiceChip(
                                                            onSelected: (value) {
                                                              if (!teamIsDisqualified) {
                                                                jogadoresDesclassificados.add(time);
                                                              }
                                                              if (teamIsClassified) {
                                                                desclassificarUmTime(time);
                                                                jogadoresClassificados.remove(time);
                                                              }
                                                              setState(() {});
                                                            },
                                                            label: const Text('Desclassificar'),
                                                            selected: teamIsDisqualified,
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      ],
                                    ),
                                  ],
                                );
                              }
                          ),
                        )
                    ],
                  ),
                );
              }
          );
        },
      )
    );
  }
}

class _ThirdPlaceMatch extends StatefulWidget {
  final List<Partida> semiFinal;
  final bool? admin;
  const _ThirdPlaceMatch({required this.semiFinal, required this.admin});

  @override
  State<_ThirdPlaceMatch> createState() => _ThirdPlaceMatchState();
}

class _ThirdPlaceMatchState extends State<_ThirdPlaceMatch> {
  final partidaSemi = Partida();

  @override
  void initState() {
    final firstMatch = widget.semiFinal.first;
    final secondMatch = widget.semiFinal[1];
    if(firstMatch.vencedor == 0) {
      partidaSemi.team1 = firstMatch.team2;
    }else {
      partidaSemi.team1 = firstMatch.team1;
    }
    if(secondMatch.vencedor == 0) {
      partidaSemi.team2 = secondMatch.team2;
    }else {
      partidaSemi.team2 = secondMatch.team1;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    late final dataProvider = Provider.of<DataController>(context, listen: false);
    int playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
    return Column(
      children: [
        const Text('Disputa de 3º lugar', style: TextStyle(fontWeight: FontWeight.bold)),
        if(partidaSemi.finished == true)
          ElevatedButton(
            style: ElevatedButton.styleFrom(fixedSize: const Size(150, 40)),
            onPressed: () => showDialog(context: context, builder: (ctx) => const AlertDialog(
              title: Text('ACABOOOOOOOOU'),
            )),
            child: const Text('Finalizar torneio')
          ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all()
          ),
          child: PartidaItem(
            team1: partidaSemi.team1!,
            team2: partidaSemi.team2!,
            partida: partidaSemi,
            admin: widget.admin,
            playersBySide: playersBySide,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => SetWinnerMobileDialog(partida: partidaSemi)
            ).then((res) {
              if(res is List) {
                partidaSemi.finished = true;
                partidaSemi.vencedor = res[0] ? 0 : 1;
                partidaSemi.pontos = res[2];
                setState(() {});
              }
            });
          },
          child: const Text('MARCAR RESULTADO')
        )
      ],
    );
  }
}


// List<Player> players = [
//   Player(nome: 'MatheusComBumBum', sex: 0),
//   //Player.withName('Maria', 1),
//   Player(nome: 'Joao', sex: 0),
//   //Player.withName('Bia', 1),
//   Player(nome: 'Victor', sex: 0),
//   //Player.withName('Anna', 1),
//   Player(nome: 'Luis', sex: 0),
//   Player(nome: 'Dani', sex: 1),
//   //Player.withName('Andre', 0),
//   //Player.withName('Clara', 1),
//   //Player.withName('Fernando', 0),
//   Player(nome: 'Juliana', sex: 1),
//   //Player.withName('Carlos', 0),
//   Player(nome: 'Roberta', sex: 1),
//   //Player.withName('Gustavo', 0),
//   Player(nome: 'Sofia', sex: 1),
//   //Player.withName('Rafael', 0),
//   //Player.withName('Larissa', 1),
//   //Player.withName('Thiago', 0),
//   Player(nome: 'Patricia', sex: 1),
//   //Player.withName('Bruno', 0),
//   Player(nome: 'Jéssica', sex: 1),
//   Player(nome: 'Diego', sex: 0),
//   Player(nome: 'Fernanda', sex: 1),
//   Player(nome: 'Eduardo', sex: 0),
//   Player(nome: 'Vanessa', sex: 1),
//   Player(nome: 'Marcelo', sex: 0),
//   Player(nome: 'Priscila', sex: 1),
//   Player(nome: 'Alan', sex: 0),
//   Player(nome: 'Natalia', sex: 1),
//   Player(nome: 'Leandro', sex: 0),
//   Player(nome: 'Rafaela', sex: 1),
// ];