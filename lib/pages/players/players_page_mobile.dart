import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/pages/players/player_dialog_actions.dart';
import '../../helpers/remover_acentos.dart';
import '../../model/player.dart';

class PlayersPageMobile extends StatefulWidget {
  const PlayersPageMobile({super.key});

  @override
  State<PlayersPageMobile> createState() => _PlayersPageMobileState();
}

class _PlayersPageMobileState extends State<PlayersPageMobile> {
  late final dataProvider = Provider.of<DataController>(context, listen: false);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => dataProvider.getPlayers());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Lista de jogadores'),
        actions: [
          TextButton.icon(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const AddPlayerDialog()
              ).then((res) {
                if(res is Player) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        elevation: 4,
                        margin: EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: EdgeInsets.only(top: 16, bottom: 16, left: 16),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                        content: Text(' Jogador adicionado com sucesso!', style: TextStyle(color: Colors.white),),
                      )
                  );
                }
              }),
              label: const Text('Adicionar jogador'), icon: const Icon(Icons.add)
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

          if(value.players.isEmpty) {
            return const Center(
              child: Text('Nenhum jogador adicionado ainda...'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 16, 12, 0),
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
                  padding: const EdgeInsets.all(16.0),
                  itemCount: value.players.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final player = value.players[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      title: Row(
                        children: [
                          Text(player.nome ?? ''),
                          const SizedBox(width: 8),
                          Icon((player.sex == 0) ? Icons.man : Icons.woman)
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text('Vitórias ${player.vitorias}  ', style: const TextStyle(color: Colors.green, fontSize: 12),),
                          Text('Derrotas ${player.derrotas}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${player.pontos} pontos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => showDialog(
                                context: context,
                                builder: (context) => RemovePlayerDialog(player: player)
                            ).then((res) {
                              if(res ?? false) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      elevation: 4,
                                      margin: EdgeInsets.fromLTRB(12, 0, 12, 8),
                                      padding: EdgeInsets.only(top: 16, bottom: 16, left: 16),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.green,
                                      content: Text(' Jogador removido com sucesso!', style: TextStyle(color: Colors.white),),
                                    )
                                );
                              }
                            }),
                            child: Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.red
                              ),
                              child: const Icon(Icons.delete, color: Colors.white, size: 20,),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
