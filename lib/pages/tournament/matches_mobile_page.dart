import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/check_admin_dialog.dart';
import 'package:volleyball_tournament_app/pages/tournament/widgets/save_teams_dialog.dart';
import '../../controller/data_controller.dart';
import '../../model/partida.dart';
import '../../model/player.dart';
import 'widgets/edit_players_dialog.dart';
import 'widgets/set_winner_mobile_dialog.dart';

class MatchesMobilePage extends StatefulWidget {
  final String tournamentName;
  const MatchesMobilePage({super.key, required this.tournamentName});

  @override
  State<MatchesMobilePage> createState() => _MatchesMobilePageState();
}

class _MatchesMobilePageState extends State<MatchesMobilePage> {
  final PageController _controller = PageController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  List<Player> players = [];
  List<List<Player>> listaDeCombinacoes = [];
  List<Partida> partidas = [];
  List<Partida> partidasHistory = [];
  Map<String, int> jogadoresUsados = {};
  int playersBySide = 0;
  int currentRound = 0;
  int currentMatch = 0;
  List<double> fatorDeAjusteList = [];
  bool? _admin;

  void generateTeams({int minGames = 3}) {
    listaDeCombinacoes = [];
    // Separar os jogadores por gênero
    List<Player> males = players.where((p) => p.sex == 0).toList();
    List<Player> females = players.where((p) => p.sex == 1).toList();

    if (females.length > males.length * 2) {
      throw Exception("Impossível formar times com no máximo 2 mulheres por time.");
    }

    for(Player player in players) {
      player.totalJogos = 0;
    }

    // Rotacionar jogadores para formar times
    while (players.any((p) => (p.totalJogos ?? 0) < minGames)) {
      males.shuffle(Random());
      females.shuffle(Random());

      List<Player> team = [];

      // Selecionar até 2 mulheres
      if (females.length >= 2) {
        team.addAll(females.take(2));
      } else if (females.isNotEmpty) {
        team.addAll(females);
      }

      // Completar com homens
      team.addAll(males.take(4 - team.length));

      // Garantir que o time tenha exatamente 4 jogadores
      if (team.length == 4) {
        // Verificar se todos no time ainda precisam jogar
        if (team.every((player) => (player.totalJogos ?? 0) < minGames)) {
          // Atualizar a contagem de jogos dos jogadores
          for (var player in team) {
            player.totalJogos = (player.totalJogos ?? 0) + 1;
          }
          listaDeCombinacoes.add(team);

          // Remover os jogadores do time atual temporariamente para próxima rotação
          males.removeWhere((p) => team.contains(p));
          females.removeWhere((p) => team.contains(p));
        }
      }

      // Reabastecer as listas quando necessário
      if (males.isEmpty && females.isEmpty) {
        males = players.where((p) => p.sex == 0).toList();
        females = players.where((p) => p.sex == 1).toList();
      }
    }

    for(Player player in players) {
      player.totalJogos = 0;
    }
  }

  List<Partida> generateMatches() {
    List<Partida> matches = [];
    Map<String, int> playerAppearances = {};

    // Inicializa o contador de participações
    for (var team in listaDeCombinacoes) {
      for (var player in team) {
        playerAppearances[player.nome!] = 0;
      }
    }

    for (int i = 0; i < listaDeCombinacoes.length; i++) {
      for (int j = i + 1; j < listaDeCombinacoes.length; j++) {
        List<Player> team1 = listaDeCombinacoes[i];
        List<Player> team2 = listaDeCombinacoes[j];

        bool hasCommonPlayers = team1.any((player1) =>
            team2.any((player2) => player1.nome == player2.nome));

        if (hasCommonPlayers) continue;

        bool exceedsLimit = false;

        for (var player in [...team1, ...team2]) {
          if (playerAppearances[player.nome]! >= 5) {
            exceedsLimit = true;
            break;
          }
        }

        if (!exceedsLimit) {
          matches.add(Partida(team1: team1, team2: team2));

          for (var player in [...team1, ...team2]) {
            playerAppearances[player.nome!] = (playerAppearances[player.nome!] ?? 0) + 1;
          }
        }
      }
    }

    return matches;
  }

  void startGames() {
    generateTeams(minGames: 3);
    partidas = generateMatches();
    balancePlayerGames(2);
    setState(() {
      listaDeCombinacoes;
      partidas.shuffle();
    });

    for(Partida partida in partidas) {
      partida.vencedor = Random().nextInt(2);
      partida.finished = true;
      for(Player player in [...partida.team1!, ...partida.team2!]) {
        player.totalJogos = (player.totalJogos ?? 0) + 1;
      }
    }
  }

  void balancePlayerGames(int maxDifference) {
    Map<String, int> playerAppearances = {};
    for (Player player in players) {
      playerAppearances[player.nome!] = player.totalJogos ?? 0;
    }

    bool adjusted = true;

    // Continua ajustando enquanto houver diferenças maiores que o permitido
    while (adjusted) {
      int maxGames = playerAppearances.values.reduce((a, b) => a > b ? a : b);
      int minGames = playerAppearances.values.reduce((a, b) => a < b ? a : b);

      // Se a diferença máxima já estiver dentro do permitido, encerra o ajuste
      if (maxGames - minGames <= maxDifference) break;

      // Lista de jogadores que têm menos jogos
      List<String> underplayedPlayers = playerAppearances.entries
          .where((entry) => entry.value == minGames)
          .map((entry) => entry.key)
          .toList();

      // Lista de jogadores que têm mais jogos
      List<String> overplayedPlayers = playerAppearances.entries
          .where((entry) => entry.value == maxGames)
          .map((entry) => entry.key)
          .toList();

      adjusted = false; // Assume que não haverá ajustes

      for (var underplayed in underplayedPlayers) {
        for (var match in partidas) {
          // Tenta ajustar jogadores em cada partida
          for (int teamIndex = 0; teamIndex < 2; teamIndex++) {
            List<Player> team = teamIndex == 0 ? match.team1! : match.team2!;
            List<Player> otherTeam = teamIndex == 0 ? match.team2! : match.team1!;

            for (int i = 0; i < team.length; i++) {
              Player playerToReplace = team[i];

              // Verifica se o jogador a ser substituído tem jogos excedentes
              if (!overplayedPlayers.contains(playerToReplace.nome!)) continue;

              // Regras de substituição
              if (underplayed == playerToReplace.nome) continue;
              if (playerToReplace.sex == 1 && team.where((p) => p.sex == 1).length == 2) continue;
              if (otherTeam.any((p) => p.nome == underplayed)) continue;

              // Substitui o jogador e atualiza os contadores
              team[i] = players.firstWhere((p) => p.nome == underplayed);
              playerToReplace.totalJogos = playerToReplace.totalJogos! - 1;
              playerAppearances[playerToReplace.nome!] = playerAppearances[playerToReplace.nome!]! - 1;
              playerAppearances[underplayed] = playerAppearances[underplayed]! + 1;
              final playerUnderplayed = players.firstWhere((p) => p.nome == underplayed);
              playerUnderplayed.totalJogos = playerUnderplayed.totalJogos ?? 0 + 1;
              adjusted = true;
              break; // Sai do loop do time
            }

            if (adjusted) break; // Sai do loop de times
          }

          if (adjusted) break; // Sai do loop de partidas
        }

        if (adjusted) break; // Sai do loop de jogadores com menos jogos
      }
    }
  }

  void updatePlayerGames(List<Player> team) {
    for (var player in team) {
      final playerFromList = players.firstWhere((p) => p.nome == player.nome);
      playerFromList.jogosFinalizados = (playerFromList.jogosFinalizados ?? 0) + 1;
    }
    final playersJson = players.map((jogador) => jogador.toJson());
    setState(() => players);
    dataProvider.updateTorneioData({"jogadores": playersJson}, dataProvider.tournament!.id!);
  }

  void updatePlayerRank(Player player) {
    final categorias = dataProvider.tournament!.categorias!;
    final playerMedia = (player.pontosAtuais ?? 0) / (player.jogosFinalizados ?? 0);

    // Função auxiliar para adicionar o jogador à categoria e removê-lo das outras.
    void updateCategoria(int index) {
      final categoria = categorias[index];
      if (categoria.players?.contains(player) ?? false) return;

      categoria.players ??= [];
      categoria.players!.add(player);

      for (var otherCategoria in categorias.where((c) => c != categoria)) {
        otherCategoria.players?.remove(player);
      }
      final playersJson = players.map((jogador) => jogador.toJson());
      final categoriasJson = dataProvider.tournament!.categorias?.map((categoria) => categoria.toJson());
      Future.wait([
        dataProvider.updateTorneioData({"categorias": categoriasJson}, dataProvider.tournament!.id!),
        dataProvider.updateTorneioData({"jogadores": playersJson}, dataProvider.tournament!.id!)
      ]);
    }

    for (int i = fatorDeAjusteList.length - 1; i >= 0; i--) {
      final fatorDeAjuste = fatorDeAjusteList[i];
      if (i == 0) {
        updateCategoria(0);
        return;
      } else if (playerMedia >= fatorDeAjuste) {
        updateCategoria(i);
        return;
      }
    }
  }

  Partida createRandomMatch() {
    // Ordenar jogadores por quantidade de jogos (priorizando os que jogaram menos)
    List<Player> sortedPlayers = players.toList()
      ..sort((a, b) => a.totalJogos!.compareTo(b.totalJogos!));

    // Selecionar os times
    List<Player> team1 = [];
    List<Player> team2 = [];
    List<Player> remainingPlayers = sortedPlayers.toList();

    // Função auxiliar para adicionar jogadores ao time com as regras
    void addPlayerToTeam(List<Player> team, Player player) {
      team.add(player);
      remainingPlayers.remove(player);
    }

    // Adicionar mulheres a ambos os times
    List<Player> women = remainingPlayers.where((p) => p.sex == 1).toList();
    if (women.length >= 2) {
      addPlayerToTeam(team1, women.removeAt(0));
      addPlayerToTeam(team2, women.removeAt(0));
    } else {
      throw Exception("Não há mulheres suficientes para formar dois times.");
    }

    // Completar os times com jogadores restantes, respeitando o limite de duas mulheres
    while (team1.length < 4) {
      Player nextPlayer = remainingPlayers.firstWhere(
        (p) => !team1.contains(p) && team1.where((t) => t.sex == 1).length < 2,
        orElse: () => remainingPlayers.first,
      );
      addPlayerToTeam(team1, nextPlayer);
    }

    while (team2.length < 4) {
      Player nextPlayer = remainingPlayers.firstWhere(
            (p) =>
        !team2.contains(p) && team2.where((t) => t.sex == 1).length < 2,
        orElse: () => remainingPlayers.first,
      );
      addPlayerToTeam(team2, nextPlayer);
    }

    for(Player player in [...team1, ...team2]) {
      player.totalJogos = player.totalJogos! + 1;
    }

    return Partida(team1: team1, team2: team2);
  }

  void addRoundManually() => showDialog(
    context: context,
    builder: (context) {
      ValueNotifier<bool> flag = ValueNotifier(false);
      List<String> playersNames = dataProvider.tournament!.jogadores!.map((player) => player.nome!).toList();
      final partida = Partida();
      List<String?> team1Selection = List<String?>.filled(players.length, null);
      List<String?> team2Selection = List<String?>.filled(players.length, null);
      return AlertDialog(
        title: const Text('Adicionar Partida'),
        content: ValueListenableBuilder(valueListenable: flag, builder: (context, val, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('TIME A'),
              for(var i = 0; i < playersBySide; i++)
                DropdownButton<String>(
                  value: team1Selection[i],
                  items: playersNames.map((player) {
                    final playerFromList = players.firstWhere((p) => p.nome! == player);
                    return DropdownMenuItem(
                        value: player,
                        child: Text('$player - ${playerFromList.totalJogos} jogos')
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    team1Selection[i] = newValue;
                    flag.value = !flag.value;
                  }
                ),
              const SizedBox(height: 16),
              const Text('TIME B'),
              for(var j = 0; j < playersBySide; j++)
                DropdownButton<String>(
                  value: team2Selection[j],
                  items: playersNames.map((player) {
                    final playerFromList = players.firstWhere((p) => p.nome == player);
                    return DropdownMenuItem(
                        value: player,
                        child: Text('$player - ${playerFromList.totalJogos} jogos')
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    team2Selection[j] = newValue;
                    flag.value = !flag.value;
                  }
                ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () {
              if(team1Selection.nonNulls.length == 4 && team2Selection.nonNulls.length == 4) {
                partida.team1 ??= [];
                partida.team2 ??= [];
                for(var player in team1Selection.nonNulls.toList()) {
                  partida.team1!.add(dataProvider.tournament!.jogadores!.firstWhere((p) => p.nome == player));
                }
                for(var player in team2Selection.nonNulls.toList()) {
                  partida.team2!.add(dataProvider.tournament!.jogadores!.firstWhere((p) => p.nome == player));
                }
                setState(() {
                  partidas.insert(partidas.length, partida);
                });
                final partidasJson = partidas.map((partida) => partida.toJson()).toList();
                dataProvider.updateTorneioData({"partidas": partidasJson}, dataProvider.tournament!.id!);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar')
          ),
          TextButton(
            onPressed: () {
              setState(() => partidas.add(createRandomMatch()));
              Navigator.pop(context);
            },
            child: const Text('Gerar partida aleatória')
          )
        ],
      );
    }
  );

  Future<bool> checkIfUserIsAlreadyLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString('admin')?.isEmpty ?? true) {
      return false;
    }

    return await dataProvider.checkPass(nomeDoTorneio: widget.tournamentName, userPass: prefs.getString('admin')!);
  }

  Future<void> loadTournamentFromBd() async {
    dataProvider.carregarTorneio(widget.tournamentName).whenComplete(() {
      if(dataProvider.tournament == null) {
        GoRouter.of(context).go('/');
        return;
      }
      players = dataProvider.tournament!.jogadores ?? [];
      partidas = dataProvider.tournament!.partidas ?? [];
      partidasHistory = dataProvider.tournament!.partidas?.where((partida) => partida.finished == true).toList() ?? [];
      playersBySide = int.parse(dataProvider.tournament!.qtdJogadoresEmCampo!.split('x')[0]);
      dataProvider.tournament!.categorias!.sort((a, b) {
        if(a.nivelCategoria! == 'Iniciante') {
          return 0;
        }else if(a.nivelCategoria == 'Amador') {
          return 0;
        }else {
          return 1;
        }
      });
      switch(dataProvider.tournament!.categorias!.length) {
        case 2: return setState(() => fatorDeAjusteList = [0.5, 1]);
        case 3: return setState(() => fatorDeAjusteList = [0.3, 0.4, 0.75]);
        case 4: return setState(() => fatorDeAjusteList = [0.3, 0.4, 0.7, 0.9]);
      }
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkIfUserIsAlreadyLoggedIn().then((res) {
        if(res) {
          _admin = true;
          loadTournamentFromBd();
        }else {
          showDialog(context: context, barrierDismissible: false, builder: (context) => CheckAdminDialog(tournamentName: widget.tournamentName,)).then((res) {
            _admin = res;
            loadTournamentFromBd();
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Fase classificatória'),
        actions: [
          IconButton(
            onPressed: () => context.go(context.namedLocation('settings', pathParameters: {"nomeDoTorneio": widget.tournamentName})),
            icon: const Icon(Icons.settings)
          )
        ],
      ),
      body: Consumer<DataController>(
        builder: (context, value, _) {
          if(value.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if(value.tournament == null || value.players.isEmpty || _admin == null) {
            return const Center(
              child: SizedBox(
                child: Text('AGUARDANDO ADMINISTRADOR INICIAR O TORNEIO'),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    if(partidas.isEmpty)
                      if(_admin ?? false)
                        SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  startGames();
                                  showDialog(
                                      context: context,
                                      builder: (context) => SaveTeamsDialog(
                                          jogadores: players,
                                          partidas: partidas,
                                          remakeTeam: startGames
                                      )
                                  ).whenComplete(() {
                                    setState(() {partidas; players;});
                                    final Map<String, int> playerGames = {};
                                    for(Partida partida in partidas) {
                                      for(Player player in [...partida.team1!, ...partida.team2!]) {
                                        playerGames[player.nome!] = (playerGames[player.nome!] ?? 0) + 1;
                                      }
                                    }

                                    playerGames.forEach((k, v) {
                                      print('O JOGADOR $k JOGOU $v PARTIDAS');
                                    });
                                  });
                                },
                                child: const Text('Gerar times')
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => addRoundManually(),
                                child: const Text('Adicionar manualmente')
                              )
                            ],
                          ),
                        )
                        else const Center(
                          child: Text('Aguarde o administrador iniciar os jogos'),
                        )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              Text('Rodada ${currentRound + 1}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                              Padding(
                                padding: const EdgeInsets.only(left: 24.0, right: 8),
                                child: Text('Jogos finalizados: ${partidas.where((p) => p.finished == true).length}'),
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
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: PageView.builder(
                              controller: _controller,
                              onPageChanged: (page) => setState(() => currentMatch = page),
                              itemCount: partidas.length,
                              itemBuilder: (context, index) {
                                final team1 = partidas[index].team1;
                                final team2 = partidas[index].team2;

                                return Column(
                                  mainAxisAlignment: (_admin ?? false) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    PartidaItem(
                                      team1: team1!,
                                      team2: team2!,
                                      partida: partidas[index],
                                      admin: _admin ?? false,
                                    ),
                                    if(_admin ?? false)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            if(partidas[index].vencedor != null)
                                              ElevatedButton(
                                                onPressed: () {
                                                  final random = Random().nextInt(4);
                                                  final random2 = Random().nextInt(4);
                                                  final playerTeam1 = partidas[index].team1!.removeAt(random);
                                                  final playerTeam2 = partidas[index].team2!.removeAt(random2);
                                                  partidas[index].team1!.add(playerTeam2);
                                                  partidas[index].team2!.add(playerTeam1);
                                                  setState(() {});
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                  fixedSize: const Size(118, 30),
                                                ),
                                                child: const Text('TROCAR 1 JOGADOR DE CADA LADO')
                                              ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => SetWinnerMobileDialog(partida: partidas[index])).then((res) {
                                                    if(res is List) {
                                                      _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                                                      setState(() {
                                                        updatePlayerGames(team1);
                                                        updatePlayerGames(team2);
                                                        partidas[index].finished = true;
                                                        partidas[index].vencedor = res[0] ? 0 : 1;
                                                        partidas[index].pontos = res[2];
                                                        partidasHistory.add(partidas[index]);
                                                        if(res[1]) {
                                                          if(res[0]) {
                                                            for(var player in partidas[index].team1 ?? []) {
                                                              final playerInList = players.firstWhere((p) => p.nome == player.nome);
                                                              playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
                                                              updatePlayerRank(playerInList);
                                                            }
                                                            for(var player in partidas[index].team2 ?? []) {
                                                              final playerInList = players.firstWhere((p) => p.nome == player.nome);
                                                              updatePlayerRank(playerInList);
                                                            }
                                                          }else {
                                                            for(var player in partidas[index].team1 ?? []) {
                                                              final playerInList = players.firstWhere((p) => p.nome == player.nome);
                                                              updatePlayerRank(playerInList);
                                                            }
                                                            for(var player in partidas[index].team2 ?? []) {
                                                              final playerInList = players.firstWhere((p) => p.nome == player.nome);
                                                              playerInList.pontosAtuais = (playerInList.pontosAtuais ?? 0) + 1;
                                                              updatePlayerRank(playerInList);
                                                            }
                                                          }
                                                        }
                                                        final partidasJson = partidas.map((partida) => partida.toJson());
                                                        dataProvider.updateTorneioData({"partidas": partidasJson}, dataProvider.tournament!.id!);
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
                                              child: partidas[index].vencedor != null ? const Text('EDITAR PARTIDA') : const Text('MARCAR RESULTADO')
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text('Nome', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16))
                              ),
                              Text('Jogos', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16), textAlign: TextAlign.center,),
                              Text('Pontos', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)),
                              Text('Media', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: players.map((player) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(player.nome!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)
                                  ),
                                  Text(player.jogosFinalizados?.toString() ?? '0', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                  Text('${player.pontosAtuais ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Text(((player.pontosAtuais ?? 0) / (player.jogosFinalizados ?? 0)).toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                  ),
                                ],
                              ),
                            )
                            ).toList(),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Categorias', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for(var i = 0; i < dataProvider.tournament!.categorias!.length; i++)
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          children: [
                                            Text(dataProvider.tournament!.categorias![i].nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
                                            if(i == 0)
                                              Text('media < ${fatorDeAjusteList[i]}', style: const TextStyle(fontSize: 10))
                                            else
                                              Text('media >= ${fatorDeAjusteList[i]}', style: const TextStyle(fontSize: 10))
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: 100,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: dataProvider.tournament?.categorias?[i].players?.length ?? 0,
                                            itemBuilder: (context, index) {
                                              final player = dataProvider.tournament?.categorias?[i].players![index];
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 16.0),
                                                child: Text(player!.nome!, textAlign: TextAlign.center,),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text('Histórico de jogos', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        for(var i = 0; i < partidasHistory.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0, left: 12, right: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          children: partidasHistory[i].team1!.map((player) => Text(player.nome!, overflow: TextOverflow.clip,)).toList(),
                                        ),
                                        const SizedBox(width: 16),
                                        if(partidasHistory[i].vencedor == 0)
                                          const Icon(FontAwesome5Solid.medal)
                                      ],
                                    ),
                                    Text(
                                      '${partidasHistory[i].pontos?.split('X')[0].trim() ?? ''} X ${partidasHistory[i].pontos?.split('X')[1].trim() ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                    Row(
                                      children: [
                                        if(partidasHistory[i].vencedor == 1)
                                          const Icon(FontAwesome5Solid.medal),
                                        const SizedBox(width: 16),
                                        Column(
                                          children: partidasHistory[i].team2!.map((player) => Text(player.nome!, overflow: TextOverflow.clip)).toList(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider()
                              ],
                            ),
                          ),
                        const SizedBox(height: 100)
                      ],
                    )
                  ],
                ),
              );
            }
          );
        },
      ),
      floatingActionButton: (_admin ?? false)
        ? FloatingActionButton(onPressed: () => addRoundManually(), child: const Icon(Icons.add),)
        : null
    );
  }
}

class PartidaItem extends StatefulWidget {
  final List<Player> team1;
  final List<Player> team2;
  final Partida partida;
  final bool admin;
  const PartidaItem({super.key, required this.team1, required this.team2, required this.partida, required this.admin});

  @override
  State<PartidaItem> createState() => _PartidaItemState();
}

class _PartidaItemState extends State<PartidaItem> {
  TextStyle style() {
    if(widget.partida.finished ?? false) {
      return const TextStyle(color: Colors.black54, fontSize: 30, fontWeight: FontWeight.bold);
    }

    return const TextStyle(color: Colors.black, fontSize: 28);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(widget.admin)
          Transform.scale(
            scale: .9,
            child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditPlayersDialog(team: widget.team1, otherTeam: widget.team2)
                ).then((res) {
                  if(res ?? false) setState(() {});
                }),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(150, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                ),
                child: const Text('EDITAR TIME A')
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.team1.map((p) => Text(p.nome ?? '', style: style())).toList(),
            ),
            if(widget.partida.vencedor == 0)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(FontAwesome5Solid.medal, size: 24),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            'X',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.partida.finished ?? false ? 30 : 28,
              color: widget.partida.finished ?? false ? Colors.black54 : Colors.black
            )
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.team2.map((p) => Text(p.nome ?? '', style: style())).toList(),
            ),
            if(widget.partida.vencedor == 1)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(FontAwesome5Solid.medal, size: 24,),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if(widget.admin)
          Transform.scale(
            scale: .9,
            child: ElevatedButton(
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => EditPlayersDialog(team: widget.team2, otherTeam: widget.team1)
                ).then((players) {
                  if(players != null && players is List) {
                    setState(() {
                      widget.team2[0] = players[0];
                      widget.team2[1] = players[1];
                    });
                  }
                }),
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(150, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                ),
                child: const Text('EDITAR TIME B')
            ),
          ),
      ],
    );
  }
}