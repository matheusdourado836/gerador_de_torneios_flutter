import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import '../../../../controller/data_controller.dart';
import '../../../../model/player.dart';

class AddPlayerToKeyDialog extends StatefulWidget {
  final Chave selectedKey;
  final List<List<Player>> existingTeams;

  const AddPlayerToKeyDialog({
    super.key,
    required this.selectedKey,
    required this.existingTeams,
  });

  @override
  State<AddPlayerToKeyDialog> createState() => _AddPlayerToKeyDialogState();
}

class _AddPlayerToKeyDialogState extends State<AddPlayerToKeyDialog> {
  late DataController dataProvider;
  late List<Player> availablePlayers;
  Player? selectedPlayer;
  dynamic selectedTeam; // Pode ser List<Player> ou 'new_team'

  @override
  void initState() {
    super.initState();
    dataProvider = Provider.of<DataController>(context, listen: false);

    final allPlayers = dataProvider.tournament!.jogadores!;
    final otherKeys = dataProvider.tournament!.chaves!.where((key) => key.nome != widget.selectedKey.nome).toList();
    final otherKeysUserIds = otherKeys.expand((key) => key.times.values.toList()).expand((element) => element).toList().map((p) => p.id!).toSet();
    final usedIds = widget.selectedKey.times.values.toList().expand((element) => element).toList().map((p) => p.id!).toSet();

    availablePlayers = allPlayers.where((p) => usedIds.contains(p.id) || !otherKeysUserIds.contains(p.id)).toList();

    if (availablePlayers.isNotEmpty) {
      selectedPlayer = availablePlayers.first;
    }
    selectedTeam = widget.existingTeams.isNotEmpty ? widget.existingTeams.first : 'new_team';
  }

  void _onSave() {
    if (selectedPlayer != null && selectedTeam != null) {
      if(selectedTeam is List<Player>) {
        selectedPlayer!.teamId = selectedTeam.first.teamId;
      }
      Navigator.of(context).pop({
        'player': selectedPlayer,
        'team': selectedTeam,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar jogador à chave'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Player>(
            decoration: const InputDecoration(
              labelText: 'Jogador disponível',
              border: OutlineInputBorder(),
            ),
            value: selectedPlayer,
            isExpanded: true,
            items: availablePlayers.map((player) {
              return DropdownMenuItem<Player>(
                value: player,
                child: Text('${player.nome!} - ${player.jogosFinalizados ?? 0} jogos'),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedPlayer = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(
              labelText: 'Escolha um time',
              border: OutlineInputBorder(),
            ),
            value: selectedTeam,
            isExpanded: true,
            items: [
              ...widget.existingTeams.map((team) {
                final names = team.map((p) => p.nome).join(', ');
                return DropdownMenuItem(
                  value: team,
                  child: Text('Time: $names'),
                );
              }),
              const DropdownMenuItem(
                value: 'new_team',
                child: Text('Criar novo time'),
              )
            ],
            onChanged: (value) => setState(() => selectedTeam = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _onSave,
          child: const Text('Adicionar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}