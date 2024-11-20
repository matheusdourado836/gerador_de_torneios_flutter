import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import '../../../model/partida.dart';
import '../../../model/player.dart';

class SaveTeamsDialog extends StatefulWidget {
  final List<Partida> partidas;
  final List<Player> jogadores;
  final Function() remakeTeam;
  const SaveTeamsDialog({super.key, required this.jogadores, required this.partidas, required this.remakeTeam});

  @override
  State<SaveTeamsDialog> createState() => _SaveTeamsDialogState();
}

class _SaveTeamsDialogState extends State<SaveTeamsDialog> {
  late final DataController dataController = Provider.of<DataController>(context, listen: false);
  final ValueNotifier<bool> _updateTeams = ValueNotifier(false);
  bool isGenderBalanced = true;

  void exchangePlayersInTeam(Partida partida, List<Partida> partidas) {
    // Função auxiliar para obter um número aleatório
    int getRandomIndex(int max) => Random().nextInt(max);

    // Função auxiliar para buscar times com mulheres disponíveis
    List<Player> getAvailableWomen() {
      // Filtra mulheres já presentes na partida para evitar duplicação
      List<Player> womenInMatch = [...partida.team1!, ...partida.team2!].where((p) => p.sex == 1).toList();

      // Filtra os times disponíveis, excluindo as mulheres já presentes na partida
      List<Player> availableWomen = widget.partidas
          .where((p) => p.team1!.where((player) => player.sex == 1 && !womenInMatch.contains(player)).isNotEmpty)
          .map((p) => p.team1!.where((player) => player.sex == 1 && !womenInMatch.contains(player)).toList())
          .expand((element) => element)
          .toList();

      if (availableWomen.isEmpty) {
        availableWomen = widget.partidas
            .where((p) => p.team2!.where((player) => player.sex == 1 && !womenInMatch.contains(player)).isNotEmpty)
            .map((p) => p.team2!.where((player) => player.sex == 1 && !womenInMatch.contains(player)).toList())
            .expand((element) => element)
            .toList();
      }

      return availableWomen;
    }

    // Função para realizar a troca entre os times
    void swapPlayers(List<Player> teamFrom, List<Player> teamTo) {
      final randomWoman = teamFrom.removeAt(getRandomIndex(teamFrom.length));
      final randomMan = teamTo.removeAt(getRandomIndex(teamTo.length));
      teamTo.add(randomWoman);
      teamFrom.add(randomMan);
    }

    final overusedMenT1 = partida.team1!.where((p) => p.sex == 0).toList();
    final overusedMenT2 = partida.team2!.where((p) => p.sex == 0).toList();
    final overusedWomenT1 = partida.team1!.where((p) => p.sex == 1).toList();
    final overusedWomenT2 = partida.team2!.where((p) => p.sex == 1).toList();

    if (overusedMenT1.length == 4) {
      // Troca direta entre time 1 e time 2
      if(overusedWomenT2.length == 2) {
        swapPlayers(partida.team2!, partida.team1!);
      }else if(overusedWomenT2.length == 1) {
        final availableTeam = getAvailableWomen();
        if (availableTeam.isNotEmpty) {
          swapPlayers(availableTeam, partida.team1!);
        }
      }
    }else if (overusedMenT2.length == 4) {
      // Troca direta entre time 2 e time 1
      if(overusedWomenT1.length == 2) {
        swapPlayers(partida.team1!, partida.team2!);
      }else if(overusedWomenT1.length == 1) {
        // Busca outro time para a troca
        final availableTeam = getAvailableWomen();
        if (availableTeam.isNotEmpty) {
          swapPlayers(availableTeam, partida.team2!);
        }
      }
    }

    checkForUnbalancedTeams(update: true);
  }

  void checkForUnbalancedTeams({bool update = false, bool exchange = false}) {
    for(Partida partida in widget.partidas) {
      final t1H = partida.team1!.where((p) => p.sex == 0).toList();
      final t1M = partida.team1!.where((p) => p.sex == 1).toList();
      final t2H = partida.team2!.where((p) => p.sex == 0).toList();
      final t2M = partida.team2!.where((p) => p.sex == 1).toList();
      if((t1H.length == 4 || t1H.length < 2 || t2H.length == 4 || t2H.length < 2)
          || (t1M.length >= 3 || t2M.length >= 3)) {
        if(update) {
          setState(() => isGenderBalanced = false);
        }else {
          isGenderBalanced = false;
        }
        if(exchange) {
          exchangePlayersInTeam(partida, widget.partidas);
        }
      }
    }
  }

  @override
  void initState() {
    checkForUnbalancedTeams(exchange: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verificar times'),
      content: ValueListenableBuilder(
        valueListenable: _updateTeams,
        builder: (context, value, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.jogadores.map((jogador) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text.rich(
                    TextSpan(
                      text: '${jogador.nome}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      children: [
                        const TextSpan(
                          text: ' vai jogar ',
                          style: TextStyle(fontWeight: FontWeight.normal)
                        ),
                        TextSpan(
                          text: '${jogador.totalJogos} jogos',
                          style: const TextStyle(fontWeight: FontWeight.w700)
                        )
                      ]
                    )
                ),
              )).toList(),
            ),
          );
        }
      ),
      actions: [
        TextButton(
          onPressed: () {
            final partidasJson = widget.partidas.map((partida) => partida.toJson()).toList();
            dataController.updateTorneioData({"partidas": partidasJson}, dataController.tournament!.id!);
            Navigator.pop(context);
          },
          child: const Text('Salvar')
        ),
        TextButton(
          onPressed: () {
            widget.remakeTeam();
            _updateTeams.value = !_updateTeams.value;
          },
          child: const Text('Balancear')
        ),
      ],
    );
  }
}
