import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import '../../../controller/data_controller.dart';

class EditPlayersDialog extends StatefulWidget {
  final List<Player> team;
  final List<Player> otherTeam;
  const EditPlayersDialog({super.key, required this.team, required this.otherTeam});

  @override
  State<EditPlayersDialog> createState() => _EditPlayersDialogState();
}

class _EditPlayersDialogState extends State<EditPlayersDialog> {
  late DataController dataProvider;
  List<Player> innerList = [];
  List<Player> availablePlayers = [];
  List<Player> originalTeam = [];

  @override
  void initState() {
    super.initState();
    dataProvider = Provider.of<DataController>(context, listen: false);
    innerList = dataProvider.tournament!.jogadores!;
    originalTeam = widget.team;

    // Filtrar jogadores disponíveis e adicionar o jogador atual, evitando duplicatas
    availablePlayers = innerList.where((player) =>
      !widget.otherTeam.contains(player)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar jogadores'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for(var i = 0; i < widget.team.length; i++)
            DropdownButton<String>(
              hint: Text(innerList.firstWhere((p) => p.nome == widget.team[i].nome).nome!),
              items: availablePlayers.map((player) => DropdownMenuItem<String>(
                value: player.nome,
                child: Text('${player.nome!} - ${player.totalJogos ?? 0} jogos'),
              )).toList(),
              onChanged: (value) {
                availablePlayers.add(innerList.firstWhere((p) => p.nome == widget.team[i].nome));
                final newPlayer = availablePlayers.firstWhere((p) => p.nome == value);
                widget.team.removeAt(i);
                widget.team.add(newPlayer);
                setState(() {});
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            for(Player player in originalTeam) {
              if(!widget.team.contains(player)) {
                player.totalJogos = (player.totalJogos ?? 0) - 1;
              }
            }

            for(Player player in widget.team) {
              if(!originalTeam.contains(player)) {
                player.totalJogos = (player.totalJogos ?? 0) + 1;
              }
            }
            Navigator.pop(context, true);
          },
          child: const Text('Salvar')
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}