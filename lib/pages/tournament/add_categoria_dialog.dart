import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';

class AddCategoriaDialog extends StatefulWidget {
  const AddCategoriaDialog({super.key});

  @override
  State<AddCategoriaDialog> createState() => _AddCategoriaDialogState();
}

class _AddCategoriaDialogState extends State<AddCategoriaDialog> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _pontosController = TextEditingController();
  String _selectedCriterio = '> (maior que)';
  final List<String> _options = [
    '> (maior que)',
    '>= (maior ou igual à)',
    '< (menor que)',
    '<= (menor ou igual à)',
    '= (igual à)'
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
              value: _selectedCriterio,
              items: _options.map((option) => DropdownMenuItem<String>(value: option, child: Text(option))).toList(),
              onChanged: (value) {
                setState(() => _selectedCriterio = value!);
              }
            ),
          ),
          TextFormField(
            controller: _pontosController,
            keyboardType: const TextInputType.numberWithOptions(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Qtd. pontos'
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final Categoria categoria = Categoria(
              nome: _nomeController.text,
              criterio: _selectedCriterio.split(' ')[0],
              pontos: int.parse(_pontosController.text)
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
