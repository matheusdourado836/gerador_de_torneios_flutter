import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/player.dart';

class EditPlayerDialog extends StatefulWidget {
  final Player player;
  const EditPlayerDialog({super.key, required this.player});

  @override
  State<EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<EditPlayerDialog> {
  late final DataController _dataController = Provider.of<DataController>(context, listen: false);
  List<Player> _players = [];
  Player? _selectedPlayer;

  @override
  void initState() {
    getPlayers();
    _selectedPlayer = widget.player;
    _selectedPlayer!.pontosAtuais ??= 0;
    _selectedPlayer!.jogosFinalizados ??= 0;
    super.initState();
  }

  void getPlayers() {
    _players = _dataController.players;
    if(!_players.contains(widget.player)) {
      _players.add(widget.player);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editando jogador ${widget.player.nome}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<Player>(
            hint: Text('Selecione um jogador'),
            value: _selectedPlayer,
            onChanged: (Player? newValue) {
              setState(() {
                _selectedPlayer = newValue;
                _selectedPlayer!.pontosAtuais = 0;
              });
            },
            items: _players.map((Player player) {
              return DropdownMenuItem<Player>(
                value: player,
                child: Text(player.nome ?? ''),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Row(
              children: [
                const Text('Pontos:'),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if(_selectedPlayer!.pontosAtuais! > 0) {
                      setState(() => _selectedPlayer!.pontosAtuais = _selectedPlayer!.pontosAtuais! - 1);
                    }
                  },
                  icon: const Icon(Icons.remove)
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text((_selectedPlayer!.pontosAtuais ?? 0).toString()),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _selectedPlayer!.pontosAtuais = _selectedPlayer!.pontosAtuais! + 1);
                  },
                  icon: const Icon(Icons.add)
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Text('Partidas jogadas:'),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: () {
                    if(_selectedPlayer!.jogosFinalizados! > 0) {
                      setState(() => _selectedPlayer!.jogosFinalizados = _selectedPlayer!.jogosFinalizados! - 1);
                    }
                  },
                  icon: const Icon(Icons.remove)
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text((_selectedPlayer!.jogosFinalizados ?? 0).toString()),
              ),
              IconButton(
                  onPressed: () {
                    setState(() => _selectedPlayer!.jogosFinalizados = _selectedPlayer!.jogosFinalizados! + 1);
                  },
                  icon: const Icon(Icons.add)
              ),
            ],
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, _selectedPlayer), child: const Text('Salvar')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
