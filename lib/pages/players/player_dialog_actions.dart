import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/data_controller.dart';
import '../../model/player.dart';

class AddPlayerDialog extends StatefulWidget {
  const AddPlayerDialog({super.key});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final GlobalKey<FormState> _key = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  late final dataProvider = Provider.of<DataController>(context, listen: false);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  String? selectedGender;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar jogador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _key,
            child: TextFormField(
              controller: _controller,
              validator: (value) {
                if(value != null) {
                  if(value.isEmpty) {
                    return 'este campo é obrigatório';
                  }
                }
                return null;
              },
              decoration: const InputDecoration(
                  hintText: 'Nome do jogador'
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: selectedGender,
            hint: const Text('Selecione o gênero'),
            items: <String>['Masculino', 'Feminino']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedGender = newValue;
              });
            },
          ),
          if(_error.isNotEmpty)
            Text(_error, style: const TextStyle(color: Colors.red))
        ],
      ),
      actions: [
        ValueListenableBuilder(valueListenable: _loading, builder: (context, value, _) {
          if(_loading.value) {
            return const CircularProgressIndicator(strokeWidth: 1.5,);
          }

          return TextButton(
              onPressed: () {
                _loading.value = true;
                if(_key.currentState!.validate()) {
                  final sex = selectedGender == 'Masculino' ? 0 : 1;
                  final Player player = Player.withName(_controller.text, sex);
                  dataProvider.addPlayer(player: player).then((res) {
                    _loading.value = false;
                    if(res is String) {
                      setState(() => _error = res);
                    }else {
                      Navigator.pop(context, player);
                    }
                  });
                }
              },
              child: const Text('Salvar')
          );
        }),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
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
