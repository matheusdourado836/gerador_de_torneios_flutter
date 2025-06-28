import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 250, height: 250,),
            const SizedBox(height: 40),
            ElevatedButton.icon(onPressed: () => GoRouter.of(context).go('/init_tournament'), label: const Text('Iniciar torneio'), icon: const Icon(Icons.sports_volleyball),),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const _CodeDialog()
              ).then((res) {
                if(res != null && res is Map<String, dynamic>) {
                  if(res["mode"] == 'Chaves') {
                    GoRouter.of(context).go('/tournament/${res["nome"]}/match?m=keys');
                  }else {
                    GoRouter.of(context).go('/tournament/${res["nome"]}/match');
                  }
                }
              }),
              label: const Text('Entrar em um torneio'),
              icon: const Icon(Icons.login_rounded)
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => GoRouter.of(context).go('/players'), label: const Text('Jogadores'), icon: const Icon(Icons.group),),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => GoRouter.of(context).go('/score'), label: const Text('Placar'), icon: const Icon(Icons.scoreboard_rounded),),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => GoRouter.of(context).go('/history'), label: const Text('Histórico'), icon: const Icon(Icons.history),),
          ],
        ),
      )
    );
  }
}


class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<String> _error = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insira o código do torneio'),
      content: ValueListenableBuilder(
          valueListenable: _error,
          builder: (context, value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                      hintText: 'Digite o código aqui...',
                  ),
                ),
                if(_error.value.isNotEmpty)
                  Text(_error.value, style: TextStyle(color: Colors.red))
              ],
            );
          }
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final dataProvider = Provider.of<DataController>(context, listen: false);
            final torneio = await dataProvider.getTorneioByCode(code: _controller.text);
            if(torneio != null) {
              if(torneio['ativo'] == false) {
                _error.value = 'Esse torneio não está ativo';
                return;
              }
              Navigator.pop(context, torneio);
            }else {
              _error.value = 'Torneio não encontrado';
            }
          },
          child: const Text('Entrar')
        )
      ],
    );
  }
}
