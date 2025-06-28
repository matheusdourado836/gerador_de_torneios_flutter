import 'package:flutter/material.dart';
import '../../../../model/player.dart';

class EditKeyTeamDialog extends StatefulWidget {
  final List<Player> jogadoresDisponiveis;
  final List<Player?> jogadoresAtuais;
  final int playersPerTeam;

  const EditKeyTeamDialog({
    super.key,
    required this.jogadoresDisponiveis,
    required this.jogadoresAtuais,
    required this.playersPerTeam,
  });

  @override
  State<EditKeyTeamDialog> createState() => _EditKeyTeamDialogState();
}

class _EditKeyTeamDialogState extends State<EditKeyTeamDialog> {
  late List<Player?> selectedPlayers;

  @override
  void initState() {
    super.initState();
    selectedPlayers = List<Player?>.generate(widget.playersPerTeam, (index) {
      if (index < widget.jogadoresAtuais.length) {
        final atual = widget.jogadoresAtuais[index];
        return widget.jogadoresDisponiveis.firstWhere((p) => p.nome == atual?.nome,
          orElse: () => atual!,
        );
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Time'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.playersPerTeam, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<Player>(
                value: selectedPlayers[index],
                decoration: InputDecoration(
                  labelText: 'Jogador ${index + 1}',
                  border: OutlineInputBorder(),
                ),
                items: widget.jogadoresDisponiveis
                    .where((jogador) => !selectedPlayers.contains(jogador) || selectedPlayers[index] == jogador)
                    .map((jogador) => DropdownMenuItem(
                  value: jogador,
                  child: Text(jogador.nome ?? 'Sem nome'),
                )).toList(),
                onChanged: (value) => setState(() => selectedPlayers[index] = value),
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: selectedPlayers.contains(null)
              ? null
              : () => Navigator.pop(context, selectedPlayers.cast<Player>()),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}