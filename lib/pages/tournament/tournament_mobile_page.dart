import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controller/data_controller.dart';
import '../../helpers/remover_acentos.dart';
import '../../model/player.dart';
import '../../model/tournament.dart';
import '../players/player_dialog_actions.dart';
import 'init_tournament_dialog.dart';

class TournamentMobilePage extends StatefulWidget {
  const TournamentMobilePage({super.key});

  @override
  State<TournamentMobilePage> createState() => _TournamentMobilePageState();
}

class _TournamentMobilePageState extends State<TournamentMobilePage> {
  late final DataController _dataController;
  ValueNotifier<bool> updateList = ValueNotifier(false);
  Tournament? _tournament;
  List<Player> readyPlayers = [];
  int addedPlayers = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const InitTournamentDialogMobile())
          .then((res) async {
        if(res is Tournament) {
          _dataController = Provider.of<DataController>(context, listen: false);
          if(_dataController.players.isEmpty) {
            await _dataController.getPlayers();
            _dataController.players.sort((a, b) => a.nome!.compareTo(b.nome!));
          }
          setState(() => _tournament = res);
        }else if(!(res ?? false)) {
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

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        onChanged: (newValue) {
                          if(newValue.isEmpty) {
                            setState(() => value.players.sort((a, b) => a.nome!.compareTo(b.nome!)));
                          }else {
                            final querySemAcento = removerAcentos(newValue.toLowerCase());
                            setState(() {
                              value.players.sort(
                                (a, b) => a.nome!.toLowerCase().startsWith(querySemAcento)
                                  || a.nome!.toLowerCase().contains(querySemAcento) ? 0 : 1
                              );
                            });
                          }
                        },
                        decoration: InputDecoration(
                            hintText: 'Pesquisar jogador...',
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
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100),
                        itemCount: value.players.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final player = value.players[index];

                          return ListTile(
                            title: Text(player.nome ?? ''),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            subtitle: Row(
                              children: [
                                Text('Vitórias ${player.vitorias}', style: const TextStyle(color: Colors.green, fontSize: 12),),
                                const SizedBox(width: 8,),
                                Text('Derrotas ${player.derrotas}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                            trailing: Transform.scale(
                              scale: .7,
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
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                    final homensList = readyPlayers.where((player) => player.sex == 0).length;
                    final mulheresList = readyPlayers.where((player) => player.sex == 1).length;

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: readyPlayers.map((player) => _playerRow(player)).toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('$homensList Homens | $mulheresList Mulheres'),
                          ),
                          ElevatedButton.icon(
                              onPressed: () {
                                if(readyPlayers.isNotEmpty) {
                                  _tournament!.jogadores = readyPlayers;
                                  _tournament!.partidas ??= [];
                                  _dataController.tournament = _tournament;
                                  _dataController.salvarTorneio().whenComplete(() {
                                    GoRouter.of(context).go('/tournament/${_tournament!.nomeTorneio!}/match');
                                  });
                                }
                              },
                              label: const Text('Iniciar torneio'),
                              icon: const Icon(Icons.play_arrow_rounded)
                          )
                        ],
                      ),
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
