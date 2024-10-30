import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'package:volleyball_tournament_app/model/tournament.dart';
import 'package:volleyball_tournament_app/pages/tournament/init_tournament_dialog.dart';
import '../players/player_dialog_actions.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  late final DataController _dataController;
  ValueNotifier<bool> updateList = ValueNotifier(false);
  Tournament? _tournament;
  List<Player> playersList = [];
  List<Player> readyPlayers = [];
  int addedPlayers = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const InitTournamentDialog())
      .then((res) async {
        if(res is Tournament) {
          _dataController = Provider.of<DataController>(context, listen: false);
          if(_dataController.players.isEmpty) {
            await _dataController.getPlayers();
          }
          setState(() {
            _tournament = res;
            playersList = _dataController.players;
          });
        }else if(!res) {
          Navigator.pop(context);
        }
      });
    });
    super.initState();
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
        title: _tournament == null ? Container() : const Text('Adicionar jogadores'),
        actions: [
          TextButton.icon(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const AddPlayerDialog()
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
      body: _tournament == null ? Container()
        : Consumer<DataController>(
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
          
          return Center(
            child: SizedBox(
              width: 700,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16.0),
                itemCount: playersList.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final player = playersList[index];

                  return ListTile(
                    title: Text(player.nome ?? ''),
                    subtitle: Row(
                      children: [
                        Text('Vitórias ${player.vitorias} - ', style: const TextStyle(color: Colors.green, fontSize: 12),),
                        Text('Derrotas ${player.derrotas} - ', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        Text('Total - ${player.partidasJogadas} jogadas', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${player.pontos} pontos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 180,
                          child: ChoiceChip(
                            selected: readyPlayers.contains(player),
                            onSelected: (value) {
                              if(!readyPlayers.contains(player)) {
                                setState(() {
                                  addedPlayers++;
                                  readyPlayers.add(player);
                                });
                              }
                            },
                            label: const Text('CHECK-IN', style: TextStyle(color: Colors.white)),
                            backgroundColor: const Color.fromRGBO(42, 35, 42, 1),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: addedPlayers == 0 ? null
        : InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: ValueListenableBuilder(
                valueListenable: updateList,
                builder: (context, value, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: readyPlayers.map((player) => _playerRow(player)).toList(),
                      ),
                      const SizedBox(height: 24,),
                      ElevatedButton.icon(
                          onPressed: () {
                            if(readyPlayers.isNotEmpty) {
                              _tournament!.jogadores = readyPlayers;
                              _dataController.tournament = _tournament;
                              _dataController.salvarTorneio(tournament: _dataController.tournament!);
                              GoRouter.of(context).go('/tournament/${_tournament!.nomeTorneio!}/match');
                            }
                          },
                          label: const Text('Iniciar torneio'),
                          icon: const Icon(Icons.play_arrow_rounded)
                      )
                    ],
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
    );
  }
}