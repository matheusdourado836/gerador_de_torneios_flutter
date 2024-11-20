import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'package:volleyball_tournament_app/pages/tournament/knockout_stage/knockout_match_mobile_page.dart';
import '../../../model/partida.dart';

class KnockoutStagePage extends StatefulWidget {
  final String nomeTorneio;
  final bool admin;
  const KnockoutStagePage({super.key, required this.nomeTorneio, required this.admin});

  @override
  State<KnockoutStagePage> createState() => _KnockoutStagePageState();
}

class _KnockoutStagePageState extends State<KnockoutStagePage> {
  late final DataController _dataController = Provider.of<DataController>(context, listen: false);
  List<Partida> partidas = [];
  List<List<Player>> playersFake = [
    [
      Player(nome: 'Marcos', pontos: 8, sex: 0),
      Player(nome: 'Flavia', pontos: 7, sex: 1),
      Player(nome: 'Pedro', pontos: 8, sex: 0),
      Player(nome: 'Celia', pontos: 7, sex: 1),
      Player(nome: 'Allan', pontos: 8, sex: 0),
    ],
    [
      Player(nome: 'Ulisses', pontos: 8, sex: 0),
      Player(nome: 'Clara', pontos: 7, sex: 1),
      Player(nome: 'Sabrina', pontos: 8, sex: 0),
      Player(nome: 'Dani', pontos: 7, sex: 1),
      Player(nome: 'Gabs', pontos: 8, sex: 0),
    ],
    [
      Player(nome: 'Matheus', pontos: 8, sex: 0),
      Player(nome: 'Anna', pontos: 7, sex: 1),
      Player(nome: 'Joao', pontos: 8, sex: 0),
      Player(nome: 'Bia', pontos: 7, sex: 1),
      Player(nome: 'Babe', pontos: 8, sex: 0),
    ]
  ];
  bool _start = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_dataController.tournament == null) {
        _dataController.carregarTorneio(widget.nomeTorneio).whenComplete(() {
          _dataController.tournament!.categorias ??= [];
          for(var categoria in _dataController.tournament!.categorias!) {
            categoria.players ??= [];
            //categoria.players = playersFake[index];
            for(var player in categoria.players!) {
              player.pontosAtuais = 0;
            }
          }
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Fase eliminatória'),
      ),
      body: Consumer<DataController>(
        builder: (context, value, _) {
          if(value.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if(_start) {
            return KnockoutMatchMobilePage(admin: widget.admin);
          }

          final categorias = value.tournament?.categorias?.where((c) => c.players?.isNotEmpty ?? false).toList() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categorias.map((categoria) => _BuildCategoria(categoria: categoria)).toList(),
                ),
                ElevatedButton(onPressed: () => setState(() => _start = true), child: const Text('INICIAR JOGOS'))
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BuildCategoria extends StatelessWidget {
  final Categoria categoria;
  const _BuildCategoria({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${categoria.nome}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categoria.players?.map((player) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(player.nome ?? ''),
            )).toList() ?? [],
          )
        ],
      ),
    );
  }
}
