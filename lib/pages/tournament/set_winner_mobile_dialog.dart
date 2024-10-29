import 'package:flutter/material.dart';
import '../../model/partida.dart';

class SetWinnerMobileDialog extends StatefulWidget {
  final Partida partida;
  const SetWinnerMobileDialog({super.key, required this.partida});

  @override
  State<SetWinnerMobileDialog> createState() => _SetWinnerMobileDialogState();
}

class _SetWinnerMobileDialogState extends State<SetWinnerMobileDialog> {
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

  TextStyle selectedTextStyle() => const TextStyle(
      color: Colors.white,
  );

  TextStyle unselectedTextStyle() => const TextStyle(
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quem venceu?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                  onPressed: () => setState(() => _timeA = true),
                  style: _timeA ? selectedStyle() : unselectedStyle(),
                  child: Column(
                    children: widget.partida.team1!.map((team) => Text(
                      team.nome!,
                      textAlign: TextAlign.center,
                      style: _timeA ? selectedTextStyle() : unselectedTextStyle()
                    )).toList(),
                  )
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => setState(() => _timeA = false),
                  style: !_timeA ? selectedStyle() : unselectedStyle(),
                  child: Column(
                    children: widget.partida.team2!.map((team) => Text(
                      team.nome!,
                      textAlign: TextAlign.center,
                      style: !_timeA ? selectedTextStyle() : unselectedTextStyle()
                    )).toList(),
                  )
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Pontuou?'),
              Transform.scale(
                scale: .7,
                child: Switch(
                    value: _setPoints,
                    onChanged: (value) {
                      setState(() => _setPoints = !_setPoints);
                    }
                ),
              )
            ],
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, [_timeA, _setPoints]), child: const Text('Salvar')),
      ],
    );
  }
}
