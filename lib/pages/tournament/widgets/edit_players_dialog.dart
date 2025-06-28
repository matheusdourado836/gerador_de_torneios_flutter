import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/data_controller.dart';
import '../../../model/player.dart';

class EditPlayersDialog extends StatefulWidget {
  final List<Player> team;
  final List<Player> otherTeam;
  final int playersPerTeam;

  const EditPlayersDialog({
    super.key,
    required this.team,
    required this.otherTeam,
    required this.playersPerTeam,
  });

  @override
  State<EditPlayersDialog> createState() => _EditPlayersDialogState();
}

class _EditPlayersDialogState extends State<EditPlayersDialog> {
  late DataController dataProvider;
  late List<Player> allPlayers;
  late List<Player> availablePlayers;
  late List<Player?> selectedPlayers;
  late List<Player> originalTeam;

  @override
  void initState() {
    super.initState();
    dataProvider = Provider.of<DataController>(context, listen: false);
    allPlayers = dataProvider.tournament!.jogadores!;

    // Remove jogadores do outro time
    availablePlayers = allPlayers
        .where((p) => !widget.otherTeam.any((o) => o.nome == p.nome))
        .toSet()
        .toList();

    // Lista original para comparação
    originalTeam = List.from(widget.team);

    // Preenche com jogadores já no time, ou null
    selectedPlayers = List<Player?>.generate(widget.playersPerTeam, (index) {
      if (index < widget.team.length) {
        final nome = widget.team[index].nome;
        return availablePlayers.firstWhere(
          (p) => p.nome == nome,
        );
      } else {
        return null;
      }
    });
  }

  void _onSave() {
    widget.team.clear();
    widget.team.addAll(selectedPlayers.whereType<Player>());

    for (Player player in originalTeam) {
      if (!widget.team.contains(player)) {
        player.totalJogos = (player.totalJogos ?? 1) - 1;
      }
    }

    for (Player player in widget.team) {
      if (!originalTeam.contains(player)) {
        player.totalJogos = (player.totalJogos ?? 0) + 1;
      }
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar jogadores da partida'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.playersPerTeam, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: DropdownButtonFormField<Player>(
              isExpanded: true,
              value: selectedPlayers[index],
              decoration: InputDecoration(
                labelText: 'Jogador ${index + 1}',
                border: OutlineInputBorder(),
              ),
              items: availablePlayers
                  .map((player) => DropdownMenuItem<Player>(
                value: player,
                child: Text('${player.nome!} - ${player.totalJogos ?? 0} jogos'),
              ))
                  .toList(),
              onChanged: (Player? newValue) {
                setState(() {
                  selectedPlayers[index] = newValue;
                });
              },
            ),
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: _onSave,
          child: const Text('Salvar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}