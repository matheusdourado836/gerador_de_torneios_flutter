import 'package:flutter/material.dart';
import 'package:volleyball_tournament_app/model/player.dart';

class RemovePlayerTournamentDialog extends StatelessWidget {
  final Player player;
  const RemovePlayerTournamentDialog({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar ação'),
      content: Text('Tem certeza que deseja remover o jogador ${player.nome} do torneio?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Não')),
      ],
    );
  }
}
