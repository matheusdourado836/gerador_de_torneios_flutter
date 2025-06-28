import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import '../../../model/player.dart';
import '../../players/player_dialog_actions.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataController>(context, listen: false);
    String? mode = dataProvider.tournament!.modelo == 'Chaves' ? dataProvider.tournament!.modelo : '';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Configurações'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: () => showDialog(
                context: context,
                builder: (context) => const AddPlayerDialog(isTournament: true)
            ).then((res) {
              if(res is List<Player>) {
                dataProvider.tournament!.jogadores!.addAll(res);
                final playersJson = dataProvider.tournament!.jogadores?.map((player) => player.toJson()).toList();
                dataProvider.updateTorneioData({'jogadores': playersJson}, dataProvider.tournament!.id!);
                if(mode == 'Chaves') {
                  String? chaveSelecionada;
                  showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('Selecionar Chave'),
                            content: DropdownButton<String>(
                              isExpanded: true,
                              value: chaveSelecionada,
                              hint: const Text('Escolha uma chave'),
                              items: dataProvider.tournament!.chaves!.map((chave) {
                                return DropdownMenuItem<String>(
                                  value: chave.nome,
                                  child: Text(chave.nome ?? 'Sem nome'),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => chaveSelecionada = value),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (chaveSelecionada != null) {
                                    final chave = dataProvider.tournament!.chaves!.firstWhere((c) => c.nome == chaveSelecionada);
                                    final timesLength = chave.times.keys.length;
                                    chave.times["time${timesLength + 1}"] = res;
                                    final keysJson = dataProvider.tournament!.chaves?.map((key) => key.toJson()).toList();
                                    dataProvider.updateTorneioData({"chaves": keysJson}, dataProvider.tournament!.id!);
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('Confirmar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }
              }
            }),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: const Text('Adicionar jogador'),
            trailing: const Icon(Icons.add, size: 22),
          ),
          ListTile(
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                alignment: Alignment.center,
                title: const Text('Seu código', textAlign: TextAlign.center,),
                content: SizedBox(
                  height: 40,
                  width: 120,
                  child: Center(
                    child: SelectionArea(
                      child: Text(
                        dataProvider.tournament!.codigo!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 20),
                      ),
                    ),
                  ),
                ),
              )
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: const Text('Ver código do torneio'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18,),
          ),
          ListTile(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => const _EncerrarTorneioDialog()
            ).then((res) {
              if(res ?? false) {
                dataProvider.cancelarTorneio(nomeDoTorneio: dataProvider.tournament!.nomeTorneio!).whenComplete(() => Navigator.pop(context));
                context.go('/');
              }
            }),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: const Text('Encerrar torneio', style: TextStyle(color: Colors.red),),
            trailing: const Icon(Icons.close, color: Colors.red, size: 22),
          )
        ],
      ),
    );
  }
}

class _EncerrarTorneioDialog extends StatelessWidget {
  const _EncerrarTorneioDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deseja encerrar o torneio?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim', style: TextStyle(color: Colors.red),)),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Não')),
      ],
    );
  }
}
