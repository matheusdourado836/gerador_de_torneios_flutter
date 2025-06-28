import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/model/partida.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import '../controller/data_controller.dart';

class ScoreWidget extends StatefulWidget {
  final Partida? partida;
  const ScoreWidget({super.key, this.partida});

  @override
  State<ScoreWidget> createState() => _ScoreWidgetState();
}

class _ScoreWidgetState extends State<ScoreWidget> with TickerProviderStateMixin {
  late final dataController = Provider.of<DataController>(context, listen: false);
  Partida? partida;
  List<Player> jogadoresSelecionados = [];
  AnimationController? _controllerA;
  AnimationController? _controllerB;
  int _teamA = 0;
  int _teamB = 0;
  int teamSize = 6;
  String previousPoint = '';
  final List<String> _points = [''];
  bool _reversed = false;

  void _startARotation() {
    _controllerA!.forward(from: 0);
  }

  void _startBRotation() {
    _controllerB!.forward(from: 0);
  }

  void setMatchPoints() {
    if(partida != null) {
      partida!.pontos = '$_teamA X $_teamB';
    }
  }

  Widget _teamAWidget(double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
            animation: _controllerA!,
            builder: (context, child) {
              return Transform.rotate(
                angle: (_controllerA?.value ?? 0) * 2 * 3.1416 * 3,
                child: SizedBox(
                  width: width * .35,
                  child: InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                        if(_points.last == 'teamB') {
                          _startARotation();
                        }
                        _points.add('teamA');
                        setState(() => _teamA++);
                        setMatchPoints();
                      },
                      child: Text(_teamA.toString(), style: TextStyle(fontSize: width * .28), textAlign: TextAlign.center,)
                  ),
                ),
              );
            }
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(fixedSize: Size(170, 40)),
          onPressed: () {
            if(_teamA > 0) {
              setState(() {
                _teamA--;
                _points.removeLast();
              });
              setMatchPoints();
            }
          },
          child: const Text('CANCELAR PONTO')
        )
      ],
    );
  }

  Widget _teamBWidget(double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
            animation: _controllerB!,
            builder: (context, child) {
              return Transform.rotate(
                angle: (_controllerB?.value ?? 0) * 2 * 3.1416 * 3,
                  child: SizedBox(
                  width: width * .35,
                  child: InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                        if(_points.last == 'teamA') {
                          _startBRotation();
                        }
                        _points.add('teamB');
                        setState(() => _teamB++);
                        setMatchPoints();
                      },
                      child: Text(_teamB.toString(), style: TextStyle(fontSize: width * .28), textAlign: TextAlign.center,)
                  ),
                ),
              );
            }
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(fixedSize: const Size(170, 40)),
          onPressed: () {
            if(_teamB > 0) {
              setState(() {
                _teamB--;
                _points.removeLast();
              });
              setMatchPoints();
            }
          },
          child: const Text('CANCELAR PONTO')
        )
      ],
    );
  }

  Widget _teamListWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            const Text('TIMES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
            if(widget.partida == null)
              DropdownButton<int>(
                value: teamSize,
                items: List.generate(5, (index) {
                  int size = index + 2;
                  return DropdownMenuItem(
                    value: size,
                    child: Text('$size jogadores'),
                  );
                }),
                onChanged: (value) => setState(() => teamSize = value!),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if(partida?.team1?.isNotEmpty ?? false)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text('TIME A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                      const SizedBox(width: 16),
                      if(widget.partida == null)
                        IconButton(onPressed: () => setState(() => partida?.team1?.clear()), icon: const Icon(Icons.delete))
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: ListView.separated(
                      itemCount: partida!.team1!.length,
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final player = partida!.team1![index];
                        return Text(player.nome ?? 'N/A', style: const TextStyle(fontSize: 18));
                      },
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => TeamDialog(timesDisponiveis: [], teamSize: teamSize),
                      ).then((res) {
                        if(res is Map) {
                          setState(() {
                            if(res["tipo"] == 'time') {
                              partida?.team1 = (res["valor"] as ExistingTeam).players;
                            }else {
                              partida?.team1 = res["valor"] as List<Player>;
                            }
                          });
                        }
                      });
                    },
                    child: const Text('ADICIONAR TIME A')
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () {
                        final teamB = partida?.team2?.map((p) => p.id).toList();
                        final availablePlayers = jogadoresSelecionados
                            .where((p) => !(teamB?.contains(p.id) ?? false))
                            .toList();

                        availablePlayers.shuffle();

                        if (availablePlayers.length >= teamSize) {
                          setState(() {
                            partida?.team1 = availablePlayers.take(teamSize).toList();
                          });
                        }
                      },
                      child: const Text('GERAR TIME')
                  ),
                ],
              ),
            if(partida?.team2?.isNotEmpty ?? false)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text('TIME B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                      const SizedBox(width: 16),
                      if(widget.partida == null)
                        IconButton(onPressed: () => setState(() => partida?.team2?.clear()), icon: const Icon(Icons.delete))
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: ListView.separated(
                      itemCount: partida!.team2!.length,
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final player = partida!.team2![index];
                        return Text(player.nome ?? 'N/A', style: const TextStyle(fontSize: 18));
                      },
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => TeamDialog(timesDisponiveis: [], teamSize: teamSize),
                      ).then((res) {
                        if(res is Map) {
                          setState(() {
                            if(res["tipo"] == 'time') {
                              partida?.team2 = (res["valor"] as ExistingTeam).players;
                            }else {
                              partida?.team2 = res["valor"] as List<Player>;
                            }
                          });
                        }
                      });
                    },
                    child: const Text('ADICIONAR TIME B ')
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final teamA = partida?.team1?.map((p) => p.id).toList();
                      final availablePlayers = jogadoresSelecionados
                          .where((p) => !(teamA?.contains(p.id) ?? false))
                          .toList();

                      availablePlayers.shuffle();

                      if (availablePlayers.length >= teamSize) {
                        setState(() {
                          partida?.team2 = availablePlayers.take(teamSize).toList();
                        });
                      }
                    },
                    child: const Text('GERAR TIME')
                  ),
                ],
              ),
          ]
        ),
        const SizedBox.shrink()
      ],
    );
  }

  @override
  void initState() {
    partida = widget.partida ?? Partida();
    if(partida != null) {
      final parts = partida?.pontos?.split(' X ');
      if(parts != null) {
        _teamA = int.parse(parts[0]);
        _teamB = int.parse(parts[1]);
      }
      teamSize = partida!.team1?.length ?? 6;
    }
    _controllerA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _controllerB = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(dataController.players.isEmpty) {
        dataController.getPlayers();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controllerA?.dispose();
    _controllerB?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: width,
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if(_reversed)
                          _teamBWidget(width)
                        else
                          _teamAWidget(width),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('X', style: TextStyle(fontSize: width * .1)),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(fixedSize: const Size(160, 40)),
                                  onPressed: () => setState(() => _reversed = !_reversed),
                                  child: const Text('TROCAR LADOS')
                              ),
                            ],
                          ),
                        ),
                        if(_reversed)
                          _teamAWidget(width)
                        else
                          _teamBWidget(width),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(fixedSize: const Size(160, 40)),
                    onPressed: () => context.pop(),
                    child: const Text('FINALIZAR')
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
            const Divider(),
            SizedBox(
              width: width,
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: _teamListWidget(),
              ),
            ),
            const Divider(),
            if(widget.partida == null)
              SizedBox(
                width: width,
                child: CheckInOutWidget(
                  players: dataController.players,
                  jogadoresSelecionados: jogadoresSelecionados,
                ),
              )
          ],
        ),
      ),
    );
  }
}

class TeamDialog extends StatefulWidget {
  final List<ExistingTeam> timesDisponiveis;
  final int teamSize;

  const TeamDialog({super.key, required this.timesDisponiveis, required this.teamSize});

  @override
  State<TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends State<TeamDialog> {
  late final DataController dataController = Provider.of<DataController>(context, listen: false);
  String? modoSelecionado;
  ExistingTeam? timeSelecionado;
  List<Player?> jogadoresSelecionados = [];

  @override
  void initState() {
    jogadoresSelecionados = List.filled(widget.teamSize, null);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Selecionar ou Montar Time"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seleção de modo
            DropdownButtonFormField<String>(
              value: modoSelecionado,
              items: const [
                DropdownMenuItem(value: 'time', child: Text('Selecionar Time Existente')),
                DropdownMenuItem(value: 'montar', child: Text('Montar Time com Jogadores')),
              ],
              onChanged: (value) {
                setState(() {
                  modoSelecionado = value;
                  jogadoresSelecionados = List.filled(widget.teamSize, null);
                });
              },
              decoration: const InputDecoration(labelText: 'Modo de seleção'),
            ),
            const SizedBox(height: 16),

            if (modoSelecionado == 'time')
              DropdownButtonFormField<ExistingTeam>(
                value: timeSelecionado,
                items: widget.timesDisponiveis.map((team) {
                  return DropdownMenuItem(value: team, child: Text(team.nome ?? 'Sem nome'));
                }).toList(),
                onChanged: (value) => setState(() => timeSelecionado = value),
                decoration: const InputDecoration(labelText: 'Time'),
              ),

            if (modoSelecionado == 'montar') ...[
              for (int i = 0; i < widget.teamSize; i++)
                DropdownButtonFormField<Player>(
                  value: jogadoresSelecionados[i],
                  items: dataController.players
                    .where((j) => !jogadoresSelecionados.contains(j) || jogadoresSelecionados[i] == j)
                    .map((jogador) => DropdownMenuItem(value: jogador, child: Text(jogador.nome ?? 'N/A')))
                    .toList(),
                  onChanged: (value) => setState(() => jogadoresSelecionados[i] = value),
                  decoration: InputDecoration(labelText: 'Jogador ${i + 1}'),
                ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (modoSelecionado == 'time' && timeSelecionado != null) {
              Navigator.pop(context, {'tipo': 'time', 'valor': timeSelecionado});
            } else if (modoSelecionado == 'montar' &&
                jogadoresSelecionados.every((j) => j != null)) {
              Navigator.pop(context, {
                'tipo': 'jogadores',
                'valor': jogadoresSelecionados.whereType<Player>().toList()
              });
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class CheckInOutWidget extends StatefulWidget {
  final List<Player> players;
  final List<Player> jogadoresSelecionados;

  const CheckInOutWidget({
    super.key,
    required this.players,
    required this.jogadoresSelecionados,
  });

  @override
  State<CheckInOutWidget> createState() => _CheckInOutWidgetState();
}

class _CheckInOutWidgetState extends State<CheckInOutWidget> {
  String searchQuery = '';

  List<Player> get filteredPlayers {
    if (searchQuery.isEmpty) return widget.players;
    return widget.players
        .where((player) =>
    player.nome?.toLowerCase().contains(searchQuery.toLowerCase()) ??
        false)
        .toList();
  }

  void toggleSelecionado(Player player) {
    setState(() {
      if (widget.jogadoresSelecionados.contains(player)) {
        widget.jogadoresSelecionados.remove(player);
      } else {
        widget.jogadoresSelecionados.add(player);
      }
    });
  }

  void selecionarTodos() {
    setState(() {
      for (var player in filteredPlayers) {
        if (!widget.jogadoresSelecionados.contains(player)) {
          widget.jogadoresSelecionados.add(player);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de pesquisa
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Pesquisar jogador',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ),

        // Botão "Adicionar Todos"
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: selecionarTodos,
            icon: const Icon(Icons.group_add),
            label: const Text('Adicionar Todos'),
          ),
        ),

        // Lista de jogadores
        ListView.builder(
          shrinkWrap: true,
          itemCount: filteredPlayers.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final player = filteredPlayers[index];
            final selecionado =
            widget.jogadoresSelecionados.contains(player);

            return ListTile(
              title: Text(player.nome ?? 'Jogador sem nome'),
              trailing: IconButton(
                icon: Icon(
                  selecionado
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: selecionado ? Colors.green : null,
                ),
                onPressed: () => toggleSelecionado(player),
              ),
            );
          },
        ),
      ],
    );
  }
}