import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import '../../../model/categoria.dart';
import '../../../model/player.dart';

class EditKeysDialog extends StatefulWidget {
  final Chave? chave;
  const EditKeysDialog({super.key, required this.chave});

  @override
  State<EditKeysDialog> createState() => _EditKeysDialogState();
}

class _EditKeysDialogState extends State<EditKeysDialog> {

  Future<List<Player>?> showSelectTeamDialog(List<Player> jogadores, int playersPerTeam) {
    return showDialog<List<Player>>(
      context: context,
      builder: (context) {
        return _SelectTeamDialog(jogadores: jogadores, playersPerTeam: playersPerTeam);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar chave ${widget.chave?.nome}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Transform.scale(
              scale: .75,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final dataProvider = Provider.of<DataController>(context, listen: false);
                  final listaDeJogadores = dataProvider.players;
                  final playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
                  final timeSelecionado = await showSelectTeamDialog(listaDeJogadores, playersBySide);

                  if (timeSelecionado != null) {
                    setState(() {
                      final lastTeam = widget.chave?.times.keys.lastOrNull;
                      if(lastTeam == null) {
                        widget.chave!.times['time1'] = timeSelecionado;
                      }
                      final lastTeamIndex = int.tryParse(lastTeam?.split('time')[1] ?? '');
                      if(lastTeamIndex != null) {
                        widget.chave!.times['time${lastTeamIndex + 1}'] = timeSelecionado;
                      }
                    });
                  }
                },
                label: const Text('Adicionar time'),
                icon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 16),
            if(widget.chave?.times.isNotEmpty ?? false)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.chave!.times.values.map((t) {
                  final teamNames = t.map((p) => p.nome).toList();
                  return ListTile(
                      title: Text(teamNames.join(',')),
                      trailing: IconButton(
                        onPressed: () {
                          final teamNames = t.map((p) => p.nome).toList();
                          setState(() {
                            widget.chave!.times.removeWhere((time, players) => players.every((p) => teamNames.contains(p.nome)));
                          });
                        },
                        icon: const Icon(Icons.delete),
                      )
                  );
                }).toList(),
              )
          ],
        ),
      )
    );
  }
}

class _SelectTeamDialog extends StatefulWidget {
  final List<Player> jogadores;
  final int playersPerTeam;

  const _SelectTeamDialog({required this.jogadores, required this.playersPerTeam});

  @override
  State<_SelectTeamDialog> createState() => _SelectTeamDialogState();
}

class _SelectTeamDialogState extends State<_SelectTeamDialog> {
  List<Player?> selectedPlayers = [];

  @override
  void initState() {
    super.initState();
    selectedPlayers = List<Player?>.filled(widget.playersPerTeam, null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher jogadores'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.playersPerTeam, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<Player>(
                initialValue: selectedPlayers[index],
                decoration: InputDecoration(
                  labelText: 'Jogador ${index + 1}',
                  border: OutlineInputBorder(),
                ),
                items: widget.jogadores
                    .where((jogador) => !selectedPlayers.contains(jogador) || selectedPlayers[index] == jogador)
                    .map((jogador) => DropdownMenuItem(
                  value: jogador,
                  child: Text(jogador.nome ?? 'Sem nome'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPlayers[index] = value;
                  });
                },
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