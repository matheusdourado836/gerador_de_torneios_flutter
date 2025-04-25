import 'package:flutter/material.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';

class AddCategoriaDialog extends StatefulWidget {
  const AddCategoriaDialog({super.key});

  @override
  State<AddCategoriaDialog> createState() => _AddCategoriaDialogState();
}

class _AddCategoriaDialogState extends State<AddCategoriaDialog> {
  final TextEditingController _nomeController = TextEditingController();
  String _selectedLevel = 'Iniciante';
  final List<String> _options = [
    'Iniciante',
    'Amador',
    'Avançado',
    'Profissional',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar categoria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nomeController,
            decoration: const InputDecoration(
              hintText: 'Nome da categoria'
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: DropdownButton<String>(
              value: _selectedLevel,
              items: _options.map((option) => DropdownMenuItem<String>(value: option, child: Text(option))).toList(),
              onChanged: (value) {
                setState(() => _selectedLevel = value!);
              }
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final Categoria categoria = Categoria(
              nome: _nomeController.text,
              nivelCategoria: _selectedLevel.split(' ')[0],
            );
            Navigator.pop(context, categoria);
          }, 
          child: const Text('Salvar')
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
