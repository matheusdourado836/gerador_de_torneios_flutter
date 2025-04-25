import 'package:flutter/material.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';

class AddChaveDialog extends StatefulWidget {
  const AddChaveDialog({super.key});

  @override
  State<AddChaveDialog> createState() => _AddChaveDialogState();
}

class _AddChaveDialogState extends State<AddChaveDialog> {
  final TextEditingController _nomeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar chave'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nomeController,
            decoration: const InputDecoration(
                hintText: 'Nome da chave'
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              final Chave chave = Chave(
                nome: _nomeController.text,
                times: {}
              );
              Navigator.pop(context, chave);
            },
            child: const Text('Salvar')
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
