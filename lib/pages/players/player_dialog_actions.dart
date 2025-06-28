import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/data_controller.dart';
import '../../helpers/remover_acentos.dart';
import '../../model/player.dart';
import '../../shared/player_info_widget.dart';


//TODO ARRUMAR OS LUGARES QUE USAM DESSE DIALOG PARA ADAPTAR O NOVO RETURN
class AddPlayerDialog extends StatefulWidget {
  final bool isTournament;
  const AddPlayerDialog({super.key, this.isTournament = false});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _key = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<List<Player>> searchList = ValueNotifier([]);
  List<Player> filteredPlayers = [];
  List<Player> selectedPlayers = [];
  String selectedGender = 'Masculino';
  String _error = '';
  late TabController _tabController;

  Widget playersList(List<Player> players) => Expanded(
    child: ListView.separated(
      itemCount: players.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final player = players[index];
        final isSelected = selectedPlayers.contains(player);

        return PlayerInfoWidget(
          player: player,
          trailing: Transform.scale(
            scale: .7,
            child: ChoiceChip(
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selectedPlayers.add(player);
                  } else {
                    selectedPlayers.remove(player);
                  }
                });
              },
              label: const Text('CHECK-IN', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color.fromRGBO(42, 35, 42, 1),
            ),
          ),
        );
      },
    ),
  );

  void loadPlayers() {
    if (!widget.isTournament) {
      filteredPlayers = dataProvider.players;
    } else {
      final tournamentPlayers = dataProvider.tournament!.jogadores!.map((p) => p.nome!).toList();
      filteredPlayers = dataProvider.players
          .where((player) => !tournamentPlayers.contains(player.nome!))
          .toList();
    }
    searchList.value = filteredPlayers;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dataProvider.players.isEmpty) {
        dataProvider.getPlayers().whenComplete(loadPlayers);
      } else {
        loadPlayers();
      }
    });
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _controller.clear();
        setState(() => _error = '');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    _loading.value = true;

    List<Player> result = List.from(selectedPlayers);

    if (_tabController.index == 1) {
      if (_key.currentState!.validate()) {
        final sex = selectedGender == 'Masculino' ? 0 : 1;
        final newPlayer = Player.withName(_controller.text, sex);
        final res = await dataProvider.addPlayer(player: newPlayer);
        _loading.value = false;

        if (res is String) {
          setState(() => _error = res);
          return;
        } else {
          result.add(res);
        }
      } else {
        _loading.value = false;
        return;
      }
    } else {
      _loading.value = false;
    }

    if (result.isNotEmpty) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar jogador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Existente'),
              Tab(text: 'Novo'),
            ],
          ),
          SizedBox(
            width: 360,
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: _controller,
                        onChanged: (newValue) {
                          if (newValue.isEmpty) {
                            searchList.value = filteredPlayers;
                          } else {
                            final query = removerAcentos(newValue.toLowerCase());
                            searchList.value = filteredPlayers.where(
                                  (p) => removerAcentos(p.nome!.toLowerCase()).contains(query),
                            ).toList();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Pesquisar jogador...',
                          suffixIcon: IconButton(
                            onPressed: () {
                              _controller.clear();
                              searchList.value = filteredPlayers;
                            },
                            icon: const Icon(Icons.close),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<List<Player>>(
                      valueListenable: searchList,
                      builder: (context, value, _) {
                        final listToShow = value.isEmpty ? filteredPlayers : value;
                        return playersList(listToShow);
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Form(
                        key: _key,
                        child: TextFormField(
                          controller: _controller,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo é obrigatório';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(hintText: 'Nome do jogador'),
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedGender,
                      items: ['Masculino', 'Feminino']
                          .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedGender = value!),
                    ),
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: _loading,
          builder: (context, loading, _) {
            if (loading) {
              return const CircularProgressIndicator(strokeWidth: 1.5);
            }
            return TextButton(onPressed: _handleSave, child: const Text('Salvar'));
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class RemovePlayerDialog extends StatefulWidget {
  final Player player;
  const RemovePlayerDialog({super.key, required this.player});

  @override
  State<RemovePlayerDialog> createState() => _RemovePlayerDialogState();
}

class _RemovePlayerDialogState extends State<RemovePlayerDialog> {
  late final dataProvider = Provider.of<DataController>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remover jogador?'),
      content: Text.rich(TextSpan(
        text: 'Tem certeza que deseja remover o jogador: ',
        children: [
          TextSpan(
            text: widget.player.nome,
            style: const TextStyle(fontWeight: FontWeight.bold)
          )
        ]
      )),
      actions: [
        TextButton.icon(
          onPressed: () => dataProvider.removePlayer(playerId: widget.player.id!).whenComplete(() => Navigator.pop(context, true)),
          label: const Text('Sim')
        ),
        TextButton.icon(onPressed: () => Navigator.pop(context), label: const Text('Cancelar', style: TextStyle(color: Colors.red),)),
      ],
    );
  }
}
