import 'package:flutter/material.dart';

class RemoveMatchDialog extends StatelessWidget {
  const RemoveMatchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remover Partida?'),
      content: const Text('Tem certeza que deseja remover essa partida?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sim'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
