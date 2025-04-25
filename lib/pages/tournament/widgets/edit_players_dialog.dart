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
  List<Player> team1 = [];

  @override
  void initState() {
    super.initState();
    dataProvider = Provider.of<DataController>(context, listen: false);
    team1 = List<Player>.from(widget.team);
    innerList = dataProvider.tournament!.jogadores!;
    originalTeam = widget.team;

    availablePlayers = innerList.where((player) => !widget.otherTeam.contains(player)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar jogadores'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for(var i = 0; i < team1.length; i++)
            DropdownButton<String>(
              hint: Text(innerList.firstWhere((p) => p.nome == team1[i].nome).nome!),
              items: availablePlayers.map((player) => DropdownMenuItem<String>(
                value: player.nome,
                child: Text('${player.nome!} - ${player.totalJogos ?? 0} jogos'),
              )).toList(),
              onChanged: (value) {
                availablePlayers.add(innerList.firstWhere((p) => p.nome == team1[i].nome));
                final newPlayer = availablePlayers.firstWhere((p) => p.nome == value);
                team1.removeAt(i);
                team1.add(newPlayer);
                setState(() {});
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.team.clear();
            widget.team.addAll(team1);
            for(Player player in originalTeam) {
              if(!widget.team.contains(player)) {
                player.totalJogos = (player.totalJogos ?? 1) - 1;
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