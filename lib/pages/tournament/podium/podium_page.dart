import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/partida.dart';
import '../../../model/player.dart';

class PodiumPage extends StatefulWidget {
  final String tournamentName;
  const PodiumPage({super.key, required this.tournamentName});

  @override
  State<PodiumPage> createState() => _PodiumPageState();
}

class _PodiumPageState extends State<PodiumPage> {
  late final DataController _dataController = Provider.of<DataController>(context, listen: false);

  Future<void> loadTournament() async {
    if(_dataController.tournament == null) {
      await _dataController.carregarTorneio(widget.tournamentName);
    }
    _dataController.tournament?.categorias ??= [];
    setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadTournament());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado do torneio'),
        actions: [
          IconButton(
            onPressed: () => GoRouter.of(context).go('/'),
            icon: const Icon(Icons.home)
          )
        ],
      ),
      body: Consumer<DataController>(
        builder: (context, value, _) {
          if(value.tournament == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if(value.tournament!.modelo == 'Chaves') {
            return const _KeyWidget();
          }else {
            return _CategoriaWidget(categorias: value.tournament!.categorias ?? []);
          }
        },
      ),
    );
  }
}


class _CategoriaWidget extends StatefulWidget {
  final List<Categoria> categorias;
  const _CategoriaWidget({required this.categorias});

  @override
  State<_CategoriaWidget> createState() => _CategoriaWidgetState();
}

class _CategoriaWidgetState extends State<_CategoriaWidget> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: widget.categorias.length, vsync: this);
  List<List<Player>> _teams = [];
  List<List<Player>> _noPodiumTeams = [];
  final Map<String, List<List<Player>>> _teamsByCategory = {};
  final Map<String, List<List<Player>>> _noPodiumTeamsByCategory = {};

  Widget _podiumWidget({required String label, required List<String> players, required String asset, double height = 80,  double fontSize = 40}) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      SizedBox(
        width: 100,
        child: Text(players.join(', '), overflow: TextOverflow.clip, textAlign: TextAlign.center,),
      ),
      Container(
        height: height,
        width: 90,
        color: Colors.black,
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize
          )
        ),
      ),
      Image.asset(
          width: asset == 'gold' ? 50 : 50,
          height: asset == 'gold' ? 50 : 50,
          'assets/images/$asset-medal.png'
      )
    ],
  );

  void getTeams(List<Partida> partidas, List<Player> players) {
    Set<String> timesSet = {};
    List<List<Player>> timesUnicos = [];

    for (var partida in partidas) {
      List<List<Player>?> timesDaPartida = [partida.team1, partida.team2];

      for (var time in timesDaPartida) {
        if (time != null) {
          // Gera uma "assinatura" do time (nomes ordenados)
          var nomesOrdenados = time.map((j) => j.nome).toList()..sort();
          var assinatura = nomesOrdenados.join(',');

          // Se ainda não foi adicionado
          if (!timesSet.contains(assinatura)) {
            // Pega os objetos reais da lista original
            List<Player> timeOriginal = nomesOrdenados.map((nomeJogador) {
              return players.firstWhere((p) => p.nome == nomeJogador);
            }).toList();

            timesUnicos.add(timeOriginal);
            timesSet.add(assinatura);
          }
        }
      }
    }

    setState(() {
      _teams = timesUnicos;
      if(_teams.length > 3) {
        _noPodiumTeams = _teams.sublist(3);
      }
    });
  }

  double calculateMedia(Player jogador, List<Partida> partidas) {
    int jogos = 0;
    int vitorias = 0;
    int saldo = 0;

    for (var partida in partidas) {
      if (partida.team1 == null || partida.team2 == null || partida.pontos == null) continue;

      bool jogouTime1 = partida.team1!.any((p) => p.nome == jogador.nome);
      bool jogouTime2 = partida.team2!.any((p) => p.nome == jogador.nome);

      if (!jogouTime1 && !jogouTime2) continue;

      jogos++;

      final pontos = partida.pontos!.split('X').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (pontos.length != 2) continue;

      int pontosFeitos = jogouTime1 ? pontos[0] : pontos[1];
      int pontosSofridos = jogouTime1 ? pontos[1] : pontos[0];

      // Vitória
      if ((jogouTime1 && partida.vencedor == 0) || (jogouTime2 && partida.vencedor == 1)) {
        vitorias++;
      }

      saldo += (pontosFeitos - pontosSofridos);
    }

    if (jogos == 0) return 0;

    return (vitorias + saldo) / jogos;
  }

  @override
  void initState() {
    for(Categoria categoria in widget.categorias) {
      _teams = [];
      _noPodiumTeams = [];
      getTeams(categoria.partidas ?? [], categoria.players ?? []);
      _teamsByCategory[categoria.nome ?? ''] = _teams;
      _noPodiumTeamsByCategory[categoria.nome ?? ''] = _noPodiumTeams;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: widget.categorias.map((c) => Tab(text: c.nome)).toList(),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
            child: TabBarView(
              controller: _tabController,
              children: widget.categorias.map((c) {
                final times = _teamsByCategory[c.nome] ?? [];
                final noPodiumTimes = _noPodiumTeamsByCategory[c.nome] ?? [];
                times.sort((a, b) {
                  final mediaA = calculateMedia(a.first, c.partidas ?? []);
                  final mediaB = calculateMedia(b.first, c.partidas ?? []);
                  return mediaB.compareTo(mediaA);
                });
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 320,
                        height: 300,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if(times.length > 1)
                              _podiumWidget(
                                label: '2',
                                players: times[1].map((p) => p.nome!).toList(),
                                asset: 'silver'
                              ),
                            if(times.isNotEmpty)
                              _podiumWidget(
                                label: '1',
                                players: times[0].map((p) => p.nome!).toList(),
                                asset: 'gold',
                                height: 110,
                                fontSize: 48
                              ),
                            if(times.length > 2)
                              _podiumWidget(
                                label: '3',
                                asset: 'bronze',
                                players: times[2].map((p) => p.nome!).toList(),
                              ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'Outras classificações',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18
                          ),
                        ),
                      ),
                      if(noPodiumTimes.isNotEmpty && times.length > 3)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: noPodiumTimes.length,
                          itemBuilder: (context, index) {
                            final players = noPodiumTimes[index].map((p) => p.nome!).toList();
                            return ListTile(
                              leading: Text('${index + 4}º'),
                              title: Text(players.join(', ')),
                            );
                          },
                        )
                    ],
                  ),
                );
              }).toList()
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyWidget extends StatefulWidget {
  const _KeyWidget();

  @override
  State<_KeyWidget> createState() => _KeyWidgetState();
}

class _KeyWidgetState extends State<_KeyWidget> {
  late final DataController _dataController = Provider.of<DataController>(context, listen: false);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, List<Player>> topPlayers = {};

  Widget _podiumWidget({
    required String label,
    required List<Player>? players,
    required String asset,
    double height = 80,
    double fontSize = 40,
  }) {
    final playerNames = players?.map((p) => p.nome).toList() ?? [];
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${players?.first.pontosAtuais} pts', style: TextStyle(fontSize: 12),),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: Text(
            playerNames.join(', '),
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center
          ),
        ),
        Container(
          height: height,
          width: 90,
          color: Colors.black,
          margin: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: fontSize)),
        ),
        Image.asset('assets/images/$asset-medal.png', width: 50, height: 50),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chaves = _dataController.tournament?.chaves ?? [];
    final jogadoresOriginais = _dataController.tournament?.jogadores ?? [];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
              icon: const Icon(Icons.arrow_back_ios_new_rounded)
            ),
            Text(chaves[_currentPage].nome ?? 'N/A'),
            IconButton(
              onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
              icon: const Icon(Icons.arrow_forward_ios_rounded)
            ),
          ],
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: chaves.length,
            itemBuilder: (context, index) {
              final chave = chaves[index];
              final fases = chave.selectedStage?.fases;
              if (fases?.isEmpty ?? true) return const Center(child: Text("Sem dados das fases"));

              if(chave.thirdPlaceMatch?.vencedor != null) {
                final vencedor = chave.thirdPlaceMatch!.vencedor == 0 ? chave.thirdPlaceMatch?.team1 : chave.thirdPlaceMatch?.team2;
                final ids = vencedor?.map((p) => p.id!).toList() ?? [];
                topPlayers["terceiro"] = jogadoresOriginais.where((p) => ids.contains(p.id)).toList();
              }

              // Final: define 1º e 2º lugares
              final finalFase = fases!['Final'];
              if (finalFase != null && finalFase['partidas'] is List && finalFase['partidas'].isNotEmpty) {
                final partidaFinal = Partida.fromJson(finalFase['partidas'].first);
                final team1Ids = partidaFinal.team1?.map((p) => p.id!).toList() ?? [];
                final team2Ids = partidaFinal.team2?.map((p) => p.id!).toList() ?? [];

                topPlayers["primeiro"] = jogadoresOriginais.where((p) => team1Ids.contains(p.id)).toList();
                topPlayers["segundo"] = jogadoresOriginais.where((p) => team2Ids.contains(p.id)).toList();
              }

              final outrosJogadores = chave.times.entries
                  .where((entry) => !entry.value.any((j) => topPlayers.values.map((p) => p.map((j) => j.id).toList()).expand((i) => i).contains(j.id)))
                  .toList();

              outrosJogadores.sort((a, b) {
                final matchPlayerA = jogadoresOriginais.firstWhere((p) => p.id == a.value.first.id);
                final matchPlayerB = jogadoresOriginais.firstWhere((p) => p.id == b.value.first.id);
                return (matchPlayerB.pontosAtuais ?? 0).compareTo(matchPlayerA.pontosAtuais ?? 0);
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: 320,
                      height: 300,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (topPlayers.containsKey('segundo'))
                            _podiumWidget(label: '2', players: topPlayers["segundo"], asset: 'silver'),
                          if (topPlayers.containsKey('primeiro'))
                            _podiumWidget(label: '1', players: topPlayers["primeiro"], asset: 'gold', height: 110, fontSize: 48),
                          if (topPlayers.containsKey('terceiro'))
                            _podiumWidget(label: '3', players: topPlayers["terceiro"], asset: 'bronze'),
                        ],
                      ),
                    ),
                    if (outrosJogadores.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text('Outras classificações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    if (outrosJogadores.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: outrosJogadores.length,
                        itemBuilder: (context, i) {
                          final jogadores = outrosJogadores[i].value.toList();
                          final jogador = jogadoresOriginais.firstWhere((j) => j.id == jogadores.first.id);
                          return ListTile(
                            leading: Text('${i + 4}º'),
                            title: Text(jogadores.map((p) => p.nome).join(', ')),
                            trailing: Text('${jogador.pontosAtuais ?? 0} pts'),
                          );
                        },
                      )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
