import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/helpers/extensions.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/etapas.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/set_winner_dialog.dart';
import 'package:collection/collection.dart';
import '../../../../controller/data_controller.dart';
import '../../../../model/partida.dart';
import '../../../../model/player.dart';
import '../matches_chaves_page.dart';

class FinalsWidget extends StatefulWidget {
  final Chave chave;
  final BoxConstraints constraints;
  final bool admin;
  const FinalsWidget({super.key, required this.constraints, required this.chave, required this.admin});

  @override
  State<FinalsWidget> createState() => _FinalsWidgetState();
}

class _FinalsWidgetState extends State<FinalsWidget> {
  final PageController _controller = PageController(initialPage: 0);
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  List<List<Player>> jogadoresClassificados = [];
  List<List<Player>> jogadoresDesclassificados = [];
  List<String> models = ['Oitavas', 'Quartas', 'Semifinal'];
  String selectedModel = '';
  Fase oitavas = Fase(nome: 'Oitavas', partidas: List.generate(8, (i) => Partida(), growable: false));
  Fase quartas = Fase(nome: 'Quartas', partidas: List.generate(4, (i) => Partida(), growable: false));
  Fase semi = Fase(nome: 'Semi', partidas: List.generate(2, (i) => Partida(), growable: false));
  Fase finalMatch = Fase(nome: 'Final', partidas: List.generate(1, (i) => Partida(), growable: false));
  int currentPage = 0;

  Future<void> loadFromBd() async {
    if(widget.chave.selectedStage?.fases.isNotEmpty ?? false) {
      if(dataProvider.tournament!.timesClassificados?.isEmpty ?? true) {
        _loading.value = true;
        await dataProvider.getClassifiedPlayers();
        _loading.value = false;
      }
      if(widget.chave.selectedStage!.fases.keys.length == 4) {
        selectedModel = 'Oitavas';
        currentPage = 0;
        oitavas = Fase.fromJson(widget.chave.selectedStage!.fases["Oitavas de final"]);
        quartas = Fase.fromJson(widget.chave.selectedStage!.fases["Quartas de final"]);
      }else if(widget.chave.selectedStage!.fases.keys.length == 3) {
        currentPage = 1;
        selectedModel = 'Quartas';
        quartas = Fase.fromJson(widget.chave.selectedStage!.fases["Quartas de final"]);
      }else {
        currentPage = 2;
        selectedModel = 'Semifinal';
      }
      semi = Fase.fromJson(widget.chave.selectedStage!.fases["Semifinal"]);
      finalMatch = Fase.fromJson(widget.chave.selectedStage!.fases["Final"]);
      jogadoresClassificados = dataProvider.tournament!.timesClassificados?.map((t) => t.players).toList() ?? [];
      setState(() {});
    }else {
      _controller.jumpToPage(0);
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadFromBd());
    super.initState();
  }

  Map<String, dynamic> _generateStageMap() {
    final map = <String, dynamic>{};
    if (selectedModel == 'Oitavas') map["Oitavas de final"] = oitavas.toJson();
    if (selectedModel == 'Oitavas' || selectedModel == 'Quartas') map["Quartas de final"] = quartas.toJson();
    map["Semifinal"] = semi.toJson();
    map["Final"] = finalMatch.toJson();
    return map;
  }

  void updateBdData() {
    final stageMap = _generateStageMap();
    final chave = dataProvider.tournament!.chaves!.firstWhere((c) => c.nome == widget.chave.nome);
    chave.selectedStage = AllFases.fromJson(stageMap);
    final keysJson = dataProvider.tournament!.chaves?.map((key) => key.toJson()).toList();
    dataProvider.updateTorneioData({"chaves": keysJson}, dataProvider.tournament!.id!);
  }

  bool classificarJogadoresProximaFase({required List<Player> team, required Fase proximaFase}) {
    final tempTeamList = List<Player>.from(team);
    if(proximaFase.partidas.every((p) => (p.team1?.isNotEmpty ?? false) && (p.team2?.isNotEmpty ?? false))) {
      return false;
    }
    for (var partida in proximaFase.partidas) {
      if ((partida.team1?.isEmpty ?? true)) {
        partida.team1 = tempTeamList;
        break;
      } else if ((partida.team2?.isEmpty ?? true)) {
        partida.team2 = tempTeamList;
        break;
      }
    }
    updateBdData();
    return true;
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
      selectedModel = '';
      currentPage = 0;
      jogadoresClassificados = [];
      jogadoresDesclassificados = [];
      oitavas = Fase(nome: 'Oitavas', partidas: List.generate(8, (i) => Partida(), growable: false));
      quartas = Fase(nome: 'Quartas', partidas: List.generate(4, (i) => Partida(), growable: false));
      semi = Fase(nome: 'Semi', partidas: List.generate(2, (i) => Partida(), growable: false));
      finalMatch = Fase(nome: 'Final', partidas: List.generate(1, (i) => Partida(), growable: false));
      dataProvider.resetClassifiedTeams(torneioId: dataProvider.tournament!.id!);
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
    return team?.isEmpty ?? true
        ? const Text('N/A', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: team!.map((p) => Text(
        p.nome ?? '',
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white)
      )).toList(),
    );
  }

  Widget gameBlock(
  Partida partida, {
    required Fase? proximaFase,
    double height = 140,
    double width = 160,
    double fontSize = 20
  }) {
    final isFinalizado = partida.vencedor != null;

    Widget buildTeamContainer(List<Player>? team, bool isVencedor) {
      return Opacity(
        opacity: isFinalizado
            ? (isVencedor ? 1 : 0.4)
            : 1,
        child: Container(
          width: width,
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.all(8),
          child: teamRow(team),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(border: Border.all()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildTeamContainer(partida.team1, partida.vencedor == 0),
          if ((partida.team1?.isNotEmpty ?? false) &&
              (partida.team2?.isNotEmpty ?? false))
            if(isFinalizado)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (partida.pontos?.split('X')[0] ?? '').trim(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)
                      ),
                      const Text('FINALIZADO'),
                      Text(
                        (partida.pontos?.trim().split('X')[1] ?? '').trim(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)
                      ),
                    ],
                  ),
                ),
              )
              else
                if(widget.admin)
                  SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(fixedSize: const Size(100, 40)),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => SetWinnerDialog(partida: partida),
                    ).then((res) {
                      if(res != null) {
                        final vencedor = partida.vencedor == 0 ? partida.team1 ?? [] : partida.team2 ?? [];
                        if(proximaFase == null) {
                          updateBdData();
                          setState(() {});
                          return;
                        }
                        classificarJogadoresProximaFase(
                          team: vencedor,
                          proximaFase: proximaFase,
                        );
                        setState(() {});
                      }
                    }),
                    child: const Text('FINALIZAR', style: TextStyle(fontSize: 10)),
                  ),
                ),
          buildTeamContainer(partida.team2, partida.vencedor == 1),
        ],
      ),
    );
  }

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
    BoxDecoration? decoration = !showDecoration ? null : BoxDecoration(border: Border.all());
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
                gameBlock(finalMatch.partidas[0], height: 154, width: width, fontSize: 14, proximaFase: null),
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

  Widget buildFaseWidget({
    required Fase faseAtual,
    Fase? proximaFase,
    double altura = 140,
    double largura = 160,
    bool showDecoration = false,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: faseAtual.partidas.map((partida) {
        return gameBlock(
          partida,
          proximaFase: proximaFase ?? Fase(nome: 'Nova fase', partidas: []),
          height: altura,
          width: largura,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _loading,
      builder: (context, value, _) {
        if(value) {
          return const Center(child: CircularProgressIndicator());
        }

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
                  if(widget.admin)
                    ChoiceChip(
                      label: const Text('Salvar'),
                      selected: selectedModel.isNotEmpty,
                      onSelected: (value) {
                        setState(() => selectedModel = models[currentPage]);
                        updateBdData();
                      },
                    ),
                  if(selectedModel.isNotEmpty && widget.admin)
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
              SizedBox(
                height: widget.constraints.maxHeight,
                width: widget.constraints.maxWidth,
                child: (selectedModel.isNotEmpty) ? stageByType() : PageView(
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
              if(finalMatch.partidas.first.vencedor != null)
                Column(
                  children: [
                    const Text('Disputa de 3º lugar', style: TextStyle(fontWeight: FontWeight.bold)),
                    _ThirdPlaceMatch(
                      chave: widget.chave,
                      semiFinal: semi.partidas,
                      admin: widget.admin,
                    ),
                  ],
                ),
              const SizedBox(height: 60),
              if(selectedModel.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 3,
                            child: Text('Nome', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Pontos', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Média', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text('Ações', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1.5),
                    // Lista de times
                    Column(
                      children: widget.chave.times.values.map((time) {
                        final timeId = time.map((p) => p.id!).toList();
                        final classifiedsId = jogadoresClassificados.map((t) => t.map((p) => p.id!).toList()).toList();

                        final teamIsClassified = classifiedsId.any((ids) => ids.toSet().containsAll(timeId.toSet()));
                        final teamIsDisqualified = !classifiedsId.any((classifiedTeam) => classifiedTeam.toSet().containsAll(timeId.toSet()));
                        final matchTeam = dataProvider.tournament!.jogadores!.where((p) => timeId.contains(p.id)).toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Opacity(
                            opacity: teamIsClassified ? 0.4 : 1,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Nome dos jogadores
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: matchTeam.map((p) => Text(
                                      p.nome!,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    )).toList(),
                                  ),
                                ),
                                // Pontos
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${matchTeam.first.pontosAtuais ?? 0}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Média
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    ((matchTeam.first.pontosAtuais ?? 0) / (matchTeam.first.jogosFinalizados ?? 1)).toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Ações
                                Expanded(
                                  flex: 5,
                                  child: widget.admin
                                      ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Classificar'),
                                        selected: teamIsClassified,
                                        onSelected: (_) {
                                          if (!teamIsClassified) {
                                            final proximaFase = selectedModel == 'Oitavas'
                                                ? oitavas
                                                : selectedModel == 'Quartas'
                                                ? quartas
                                                : semi;

                                            final res = classificarJogadoresProximaFase(
                                              team: matchTeam,
                                              proximaFase: proximaFase,
                                            );
                                            if (!res) {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Alerta'),
                                                  content: const Text('Não é possível fazer mais classificações'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('OK'),
                                                    )
                                                  ],
                                                ),
                                              );
                                              return;
                                            }
                                            dataProvider.addToClassifiedTeams(players: matchTeam);
                                            jogadoresClassificados.add(matchTeam);
                                          }
                                          if (teamIsDisqualified) {
                                            jogadoresDesclassificados.remove(matchTeam);
                                          }
                                          setState(() {});
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('Desclassificar'),
                                        selected: teamIsDisqualified,
                                        onSelected: (_) {
                                          if (!teamIsDisqualified) {
                                            jogadoresDesclassificados.add(matchTeam);
                                          }
                                          if (teamIsClassified) {
                                            desclassificarUmTime(matchTeam);
                                            jogadoresClassificados.removeWhere((team) {
                                              final teamIds = team.map((p) => p.id!).toList();
                                              return teamIds.toSet().containsAll(timeId.toSet());
                                            });
                                          }
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )
            ],
          ),
        );
      }
    );
  }
}

class _ThirdPlaceMatch extends StatefulWidget {
  final Chave chave;
  final List<Partida> semiFinal;
  final bool? admin;
  const _ThirdPlaceMatch({required this.chave, required this.semiFinal, required this.admin});

  @override
  State<_ThirdPlaceMatch> createState() => _ThirdPlaceMatchState();
}

class _ThirdPlaceMatchState extends State<_ThirdPlaceMatch> {
  Partida partidaSemi = Partida();

  @override
  void initState() {
    if(widget.chave.thirdPlaceMatch != null) {
      partidaSemi = widget.chave.thirdPlaceMatch!;
    }else {
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
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    late final dataProvider = Provider.of<DataController>(context, listen: false);
    int playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
    return Column(
      children: [
        PartidaItem(
          team1: partidaSemi.team1!,
          team2: partidaSemi.team2!,
          partida: partidaSemi,
          playersPerTeam: playersBySide,
          admin: widget.admin,
          onSave: () {},
        ),
        const SizedBox(height: 16),
        if(partidaSemi.finished == true)
          ElevatedButton(
              style: ElevatedButton.styleFrom(fixedSize: const Size(150, 40)),
              onPressed: () => GoRouter.of(context).clearStackAndNavigate(context, '/tournament/${dataProvider.tournament!.nomeTorneio}/podium'),
              child: const Text('🏆  Pódio')
          ),
        if(widget.admin == true & (partidaSemi.finished == null || partidaSemi.finished == false))
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SetWinnerDialog(partida: partidaSemi)
              ).then((res) {
                if(res != null) {
                  final chave = dataProvider.tournament!.chaves!.firstWhere((c) => c.nome == widget.chave.nome);
                  chave.thirdPlaceMatch = partidaSemi;
                  final keysJson = dataProvider.tournament!.chaves?.map((key) => key.toJson()).toList();
                  dataProvider.updateTorneioData({"chaves": keysJson}, dataProvider.tournament!.id!);
                  setState(() {});
                }
              });
            },
            child: const Text('MARCAR RESULTADO')
          ),
        const Divider()
      ],
    );
  }
}