import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/model/partida.dart';
import 'package:volleyball_tournament_app/model/player.dart';

import '../../../controller/data_controller.dart';

class SetWinnerDialog extends StatefulWidget {
  final Partida partida;
  final List<Player>? players;
  const SetWinnerDialog({super.key, required this.partida, this.players});

  @override
  State<SetWinnerDialog> createState() => _SetWinnerDialogState();
}

class _SetWinnerDialogState extends State<SetWinnerDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
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

  Player getMatchPlayer(Player player) {
    final dataProvider = Provider.of<DataController>(context, listen: false);
    Player? matchPlayer = widget.players?.firstWhere((p) => p.id == player.id, orElse: () => Player());
    if(matchPlayer?.id == null) {
      matchPlayer = dataProvider.tournament!.jogadores!.firstWhere((p) => p.id == player.id, orElse: () => Player());
    }

    return matchPlayer?.id != null ? matchPlayer! : player;
  }

  void cancelMatch() {
    widget.partida.finished = null;
    widget.partida.pontos = null;
    final vencedor = widget.partida.vencedor == 0 ? widget.partida.team1 : widget.partida.team2;
    for(Player player in vencedor ?? []) {
      final playerInList = getMatchPlayer(player);
      playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) - 1;
      playerInList.pontos = (playerInList.pontos ?? 0) - 1;
    }
    for(Player player in [...widget.partida.team1 ?? [], ...widget.partida.team2 ?? []]) {
      final playerInList = getMatchPlayer(player);
      playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) - 1;
    }
    widget.partida.vencedor = null;
  }

  @override
  void initState() {
    _controller.text = widget.partida.pontos?.split('X')[0] ?? '';
    _controller2.text = widget.partida.pontos?.split('X')[1] ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller2.dispose();
    super.dispose();
  }

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
                  children: widget.partida.team1!.map((team) => Text(
                    team.nome!,
                    textAlign: TextAlign.center,
                    style: _timeA ? selectedTextStyle() : unselectedTextStyle()
                  )).toList(),
                )
              ),
              const SizedBox(width: 32),
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
              Switch(
                value: _setPoints,
                onChanged: (value) {
                  setState(() => _setPoints = !_setPoints);
                }
              )
            ],
          ),
          if(_setPoints)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PLACAR'),
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
        if(widget.partida.finished == true)
          TextButton(
            onPressed: () {
              cancelMatch();
              Navigator.pop(context, true);
            },
            child: const Text('Cancelar partida')
          ),
        TextButton(
          onPressed: () {
            if(widget.partida.finished == true) {
              cancelMatch();
            }
            widget.partida.finished = true;
            widget.partida.vencedor = _timeA ? 0 : 1;
            if(_setPoints) {
              widget.partida.pontos = '${_controller.text} X ${_controller2.text}';
              final vencedor = widget.partida.vencedor == 0 ? widget.partida.team1 : widget.partida.team2;
              for(Player player in vencedor ?? []) {
                final playerInList = getMatchPlayer(player);
                playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
                playerInList.pontos = (playerInList.pontos ?? 0) + 1;
              }
            }
            for(Player player in [...widget.partida.team1 ?? [], ...widget.partida.team2 ?? []]) {
              final playerInList = getMatchPlayer(player);
              playerInList.jogosFinalizados = (playerInList.jogosFinalizados ?? 0) + 1;
            }
            Navigator.pop(context, true);
          },
          child: const Text('Salvar')
        ),
      ],
    );
  }
}
