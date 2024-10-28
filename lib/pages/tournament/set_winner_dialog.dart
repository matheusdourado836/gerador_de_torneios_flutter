import 'package:flutter/material.dart';
import 'package:volleyball_tournament_app/model/partida.dart';

class SetWinnerDialog extends StatefulWidget {
  final Partida partida;
  const SetWinnerDialog({super.key, required this.partida});

  @override
  State<SetWinnerDialog> createState() => _SetWinnerDialogState();
}

class _SetWinnerDialogState extends State<SetWinnerDialog> {
  bool _timeA = false;
  bool _setPoints = true;

  ButtonStyle selectedStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color.fromRGBO(42, 35, 42, 1),
      fixedSize: const Size(250, 50)
  );

  ButtonStyle unselectedStyle() => ElevatedButton.styleFrom(
      backgroundColor: Colors.black38,
      fixedSize: const Size(240, 45),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quem venceu?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _timeA = true),
                style: _timeA ? selectedStyle() : unselectedStyle(),
                child: Column(
                  children: widget.partida.team1!.map((team) => Text(team.nome!, textAlign: TextAlign.center,)).toList(),
                )
              ),
              const SizedBox(width: 32),
              ElevatedButton(
                onPressed: () => setState(() => _timeA = false),
                style: !_timeA ? selectedStyle() : unselectedStyle(),
                child: Column(
                  children: widget.partida.team2!.map((team) => Text(team.nome!, textAlign: TextAlign.center,)).toList(),
                )
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Pontuou?'),
              Switch(
                value: _setPoints,
                onChanged: (value) {
                  setState(() => _setPoints = !_setPoints);
                }
              )
            ],
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, [_timeA, _setPoints, widget.partida.team1, widget.partida.team2]), child: const Text('Salvar')),
      ],
    );
  }
}
