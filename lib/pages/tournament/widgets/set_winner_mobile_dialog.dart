import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../model/partida.dart';

class SetWinnerMobileDialog extends StatefulWidget {
  final Partida partida;
  const SetWinnerMobileDialog({super.key, required this.partida});

  @override
  State<SetWinnerMobileDialog> createState() => _SetWinnerMobileDialogState();
}

class _SetWinnerMobileDialogState extends State<SetWinnerMobileDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  bool _timeA = false;
  bool _setPoints = true;

  ButtonStyle selectedStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color.fromRGBO(42, 35, 42, 1),
      minimumSize: const Size(250, 100)
  );

  ButtonStyle unselectedStyle() => ElevatedButton.styleFrom(
    backgroundColor: Colors.black38,
    minimumSize: const Size(240, 90),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
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
            ),
          ),
          if(_setPoints)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PLACAR (opcional)'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 40,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(hintText: '0'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('X'),
                    ),
                    SizedBox(
                      width: 30,
                      height: 40,
                      child: TextField(
                        controller: _controller2,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(hintText: '0'),
                      ),
                    ),
                  ],
                ),
              ],
            )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, [_timeA, _setPoints, '${_controller.text} X ${_controller2.text}']),
          child: const Text('Salvar')
        ),
      ],
    );
  }
}
