import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';

class CheckAdminDialog extends StatefulWidget {
  final String tournamentName;
  const CheckAdminDialog({super.key, required this.tournamentName});

  @override
  State<CheckAdminDialog> createState() => _CheckAdminDialogState();
}

class _CheckAdminDialogState extends State<CheckAdminDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entrar como'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(onPressed: () => showDialog(
              context: context,
              builder: (context) => AdminDialog(tournamentName: widget.tournamentName)).then((res) => Navigator.pop(context, res)),
            child: const Text('Admin')
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Jogador')),
        ],
      ),
    );
  }
}

class AdminDialog extends StatefulWidget {
  final String tournamentName;
  const AdminDialog({super.key, required this.tournamentName});

  @override
  State<AdminDialog> createState() => _AdminDialogState();
}

class _AdminDialogState extends State<AdminDialog> {
  final GlobalKey<FormState> _key = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  late final DataController _dataController = Provider.of<DataController>(context, listen: false);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<bool> _error = ValueNotifier(false);

  Future<void> setAdminPersistence() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin', _controller.text);
    Navigator.pop(context, true);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _error,
        builder: (context, value, _) {
          return AlertDialog(
            title: const Text('Digite a senha'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _key,
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Digite a senha do torneio...'
                    ),
                  ),
                ),
                if(value)
                  const Text('Senha incorreta inserida', style: TextStyle(color: Colors.red))
              ],
            ),
            actions: [
              ValueListenableBuilder(
                  valueListenable: _loading,
                  builder: (context, value, _) {
                    if(value) {
                      return const CircularProgressIndicator();
                    }else {
                      return TextButton(
                          onPressed: () async {
                            _error.value = false;
                            _loading.value = true;
                            bool res = await _dataController.checkPass(nomeDoTorneio: widget.tournamentName, userPass: _controller.text);
                            _loading.value = false;
                            if(res) {
                              setAdminPersistence();
                            }else {
                              _error.value = true;
                            }
                          },
                          child: const Text('Entrar')
                      );
                    }
                  }
              )
            ],
          );
        }
    );
  }
}
