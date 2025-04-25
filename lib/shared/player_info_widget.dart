import 'package:flutter/material.dart';
import 'package:volleyball_tournament_app/model/player.dart';

class PlayerInfoWidget extends StatelessWidget {
  final Player player;
  final Widget trailing;
  const PlayerInfoWidget({super.key, required this.player, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(player.nome ?? ''),
          const SizedBox(width: 8),
          Icon((player.sex == 0) ? Icons.man : Icons.woman)
        ],
      ),
      subtitle: Row(
        children: [
          Text('${player.vitorias ?? 0}V', style: const TextStyle(color: Colors.green, fontSize: 12),),
          const SizedBox(width: 8),
          Text('${player.derrotas ?? 0}D', style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
      trailing: trailing,
    );
  }
}
