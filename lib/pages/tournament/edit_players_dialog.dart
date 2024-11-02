import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import '../../controller/data_controller.dart';

class EditPlayersDialog extends StatefulWidget {
  final List<Player> team;
  final List<Player> otherTeam;
  const EditPlayersDialog({super.key, required this.team, required this.otherTeam});

  @override
  State<EditPlayersDialog> createState() => _EditPlayersDialogState();
}

class _EditPlayersDialogState extends State<EditPlayersDialog> {
  late DataController dataProvider;
  late Player _firstPlayer;
  late Player _secondPlayer;
  late String _firstPlayerName;
  late String _secondPlayerName;
  late List<Player> innerList;
  late List<Player> availablePlayers1;
  late List<Player> availablePlayers2;

  @override
  void initState() {
    super.initState();
    dataProvider = Provider.of<DataController>(context, listen: false);
    innerList = dataProvider.players;

    // Inicializar os jogadores
    _firstPlayer = widget.team.first;
    _secondPlayer = widget.team[1];
    _firstPlayerName = _firstPlayer.nome!;
    _secondPlayerName = _secondPlayer.nome!;

    // Filtrar jogadores disponíveis e adicionar o jogador atual, evitando duplicatas
    availablePlayers1 = dataProvider.tournament!.jogadores!
        .where((player) =>
    (widget.otherTeam.where((p) => p.nome == player.nome).isEmpty))
        .toList();
    availablePlayers2 = dataProvider.tournament!.jogadores!
        .where((player) =>
    (widget.team.where((p) => p.nome == player.nome).isEmpty && widget.otherTeam.where((p) => p.nome == player.nome).isEmpty))
        .toList();
    // availablePlayers1.add(_firstPlayer);
    // availablePlayers2.add(_secondPlayer);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar jogadores'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for(var i = 0; i < widget.team.length; i++)
            DropdownButton<String>(
              value: widget.team[i].nome,
              items: availablePlayers1.map((player) => DropdownMenuItem<String>(
                value: player.nome,
                child: Text(player.nome!),
              )).toList(),
              onChanged: (value) {
                widget.team[i].nome = value;
                setState(() {
                  
                });
                print('O JOGADOR ${widget.team[i].nome} AGORA É $value');
              },
            ),
          // DropdownButton<String>(
          //   value: _firstPlayerName,
          //   items: availablePlayers1
          //       .where((p) => p.nome != _secondPlayer.nome)
          //       .map((player) => DropdownMenuItem<String>(
          //     value: player.nome,
          //     child: Text(player.nome!),
          //   ))
          //       .toList(),
          //   onChanged: (value) {
          //     setState(() {
          //       _firstPlayer = availablePlayers1.firstWhere((p) => p.nome == value);
          //       _firstPlayerName = value!;
          //     });
          //   },
          // ),
          // const SizedBox(height: 24),
          // DropdownButton<String>(
          //   value: _secondPlayerName,
          //   items: availablePlayers2
          //       .where((p) => p.nome != _firstPlayer.nome)
          //       .map((player) => DropdownMenuItem<String>(
          //     value: player.nome,
          //     child: Text(player.nome!),
          //   ))
          //       .toList(),
          //   onChanged: (value) {
          //     setState(() {
          //       _secondPlayer = availablePlayers2.firstWhere((p) => p.nome == value);
          //       _secondPlayerName = value!;
          //     });
          //   },
          // ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, [_firstPlayer, _secondPlayer]), child: const Text('Salvar')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}