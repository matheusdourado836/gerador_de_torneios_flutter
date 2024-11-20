import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import '../../../model/partida.dart';
import '../../../model/player.dart';
import '../matches_mobile_page.dart';
import '../widgets/set_winner_mobile_dialog.dart';

class KnockoutMatchMobilePage extends StatefulWidget {
  final bool admin;
  const KnockoutMatchMobilePage({super.key, required this.admin});

  @override
  State<KnockoutMatchMobilePage> createState() => _KnockoutMatchMobilePageState();
}

class _KnockoutMatchMobilePageState extends State<KnockoutMatchMobilePage> {
  final PageController _controller = PageController();
  late final DataController _dataController;
  int categoriaAtual = 0;
  List<Categoria> categorias = [];

  @override
  void initState() {
    _dataController = Provider.of<DataController>(context, listen: false);
    categorias = _dataController.tournament!.categorias!.where((c) => c.players?.isNotEmpty ?? false).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                    icon: const Icon(Icons.arrow_back_ios)
                ),
                Text(
                    '${categorias[categoriaAtual].nome}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                ),
                IconButton(
                    onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                    icon: const Icon(Icons.arrow_forward_ios)
                ),
              ],
            ),
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight * .9,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (page) => setState(() => categoriaAtual = page),
                itemCount: categorias.length,
                itemBuilder: (context, index) {
                  final players = categorias[index].players;
                  return _MatchWidget(
                    categoria: categorias[index],
                    constraints: constraints,
                    admin: widget.admin,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MatchWidget extends StatefulWidget {
  final Categoria categoria;
  final BoxConstraints constraints;
  final bool admin;
  const _MatchWidget({required this.categoria, required this.constraints, required this.admin});

  @override
  State<_MatchWidget> createState() => _MatchWidgetState();
}

class _MatchWidgetState extends State<_MatchWidget> {
  late final DataController _dataController = Provider.of<DataController>(context, listen: false);
  final PageController _controller = PageController();
  List<List<Player>> listaDeDuplas = [];
  List<Partida> partidas = [];
  List<Partida> partidasHistory = [];
  Set<String> duplasUsadas = {};
  int playersBySide = 0;
  int qtdRounds = 0;
  int currentRound = 0;
  int currentMatch = 0;

  void generate2x2game({bool misto = false}) {
    List<Partida> innerPartidas = [];
    combinations(2, misto: misto);

    for (int i = 0; i < listaDeDuplas.length; i++) {
      for (int j = i + 1; j < listaDeDuplas.length; j++) {
        List<String> time1 = listaDeDuplas[i].map((dupla) => dupla.nome!).toList();
        List<String> time2 = listaDeDuplas[j].map((dupla) => dupla.nome!).toList();

        if (time1.toSet().intersection(time2.toSet()).isEmpty) {
          String chaveTime1 = time1.join(',');
          String chaveTime2 = time2.join(',');

          if (!duplasUsadas.contains(chaveTime1) && !duplasUsadas.contains(chaveTime2)) {
            innerPartidas.add(Partida(team1: listaDeDuplas[i], team2: listaDeDuplas[j]));
            duplasUsadas.add(chaveTime1);
            duplasUsadas.add(chaveTime2);
          }
        }
      }
    }

    setState(() {
      partidas = innerPartidas;
      partidasHistory.addAll(partidas);
      partidas.shuffle();
    });
  }

  void combinations(int r, {bool misto = false}) {
    listaDeDuplas = [];
    widget.categoria.players ??= [];
    if (misto) {
      // Separar jogadores por sexo
      List<Player> homens = widget.categoria.players!.where((p) => p.sex == null || p.sex == 0).toList();
      List<Player> mulheres = widget.categoria.players!.where((p) => p.sex == 1).toList();

      homens.sort((a, b) {
        a.totalJogos ??= 0;
        b.totalJogos ??= 0;
        return a.totalJogos!.compareTo(b.totalJogos!);
      });
      mulheres.sort((a, b) {
        a.totalJogos ??= 0;
        b.totalJogos ??= 0;
        return a.totalJogos!.compareTo(b.totalJogos!);
      });

      // Criar combinações entre homens e mulheres
      for (var homem in homens) {
        for (var mulher in mulheres) {
          listaDeDuplas.add([homem, mulher]);
        }
      }
      setState(() => listaDeDuplas);
    } else {
      // Caso misto seja falso, cria todas as combinações normalmente
      void combine(List<Player> combo, int start) {
        if (combo.length == r) {
          listaDeDuplas.add(List.from(combo));
          return;
        }

        for (int i = start; i < widget.categoria.players!.length; i++) {
          combo.add(widget.categoria.players![i]);
          combine(combo, i + 1);
          combo.removeLast();
        }
      }

      combine([], 0);
    }
  }

  void updatePlayerGames(List<Player> team) {
    for (var player in team) {
      final playerFromList = widget.categoria.players!.firstWhere((p) => p.nome == player.nome);
      playerFromList.totalJogos = (playerFromList.totalJogos ?? 0) + 1;
    }
    setState(() => widget.categoria.players);
  }

  @override
  void initState() {
    playersBySide = int.parse(_dataController.tournament!.qtdJogadoresEmCampo?.split('X')[0] ?? '');
    generate2x2game(misto: _dataController.tournament!.misto ?? false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: partidas.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                Text('Rodada ${currentRound + 1}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 8),
                  child: Text('${partidas.where((p) => p.finished == true).length} jogos finalizados'),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                    icon: const Icon(Icons.arrow_back_ios)
                ),
                Text(
                    'Jogo ${currentMatch + 1} de ${partidas.length}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                ),
                IconButton(
                    onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                    icon: const Icon(Icons.arrow_forward_ios)
                ),
              ],
            ),
            SizedBox(
              width: widget.constraints.maxWidth,
              height: widget.constraints.maxHeight * .8,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (page) => setState(() => currentMatch = page),
                itemCount: partidas.length,
                itemBuilder: (context, index) {
                  final team1 = partidas[index].team1;
                  final team2 = partidas[index].team2;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          if(partidas[index].vencedor != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: Text(
                                'Vencedor: ${partidas[index].vencedor == 0 ? 'TIME A' : 'TIME B'}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            )
                        ],
                      ),
                      PartidaItem(
                        team1: team1!,
                        team2: team2!,
                        partida: partidas[index],
                        admin: widget.admin,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => SetWinnerMobileDialog(partida: partidas[index])).then((res) {
                                _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                                if(res is List) {
                                  setState(() {
                                    updatePlayerGames(team1);
                                    updatePlayerGames(team2);
                                    partidas[index].finished = true;
                                    partidas[index].vencedor = res[0] ? 0 : 1;
                                    if(res[1]) {
                                      if(res[0]) {
                                        for(var player in team1) {
                                          player.pontosAtuais = (player.pontosAtuais ?? 0) + 1;
                                        }
                                      }else {
                                        for(var player in team2) {
                                          player.pontosAtuais = (player.pontosAtuais ?? 0) + 1;
                                        }
                                      }
                                    }
                                  });
                                }
                              }
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                fixedSize: const Size(118, 30),
                                backgroundColor: partidas[index].vencedor != null ? Colors.blue : const Color.fromRGBO(42, 35, 42, 1)
                            ),
                            child: partidas[index].vencedor != null ? const Text('EDITAR') : const Text('MARCAR RESULTADO')
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
