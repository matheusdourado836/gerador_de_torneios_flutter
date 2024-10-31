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
                builder: (context) => const AddPlayerDialog()
            ).then((res) {
              if(res is Player) {
                dataProvider.tournament!.jogadores!.add(res);
                context.pop(res);
              }
            }),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: const Text('Adicionar jogador'),
            trailing: const Icon(Icons.add, size: 22),
          ),
          ListTile(
            onTap: () => context.go(context.namedLocation('fase2', pathParameters: {"nomeDoTorneio": dataProvider.tournament!.nomeTorneio!})),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: const Text('Ir para a próxima fase'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18,),
          ),
          ListTile(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => const _EncerrarTorneioDialog()
            ).then((res) {
              if(res ?? false) {
                dataProvider.cancelarTorneio(nomeDoTorneio: dataProvider.tournament!.nomeTorneio!).whenComplete(() => Navigator.pop(context));
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
