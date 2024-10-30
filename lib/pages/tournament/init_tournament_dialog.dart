import 'package:flutter/material.dart';
import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/enums.dart';
import 'package:volleyball_tournament_app/pages/tournament/add_categoria_dialog.dart';
import '../../model/tournament.dart';

class InitTournamentDialog extends StatefulWidget {
  const InitTournamentDialog({super.key});

  @override
  State<InitTournamentDialog> createState() => _InitTournamentDialogState();
}

class _InitTournamentDialogState extends State<InitTournamentDialog> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _key = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  late final AnimationController _animationController;
  String? _selectedValue = '2x2';
  String? _selectedModel = 'Side-out';
  bool _beach = false;
  bool _misto = true;
  final List<Categoria> _categoriasPadrao = [
    Categoria(nome: 'Tio Paulo', nivelCategoria: 'Iniciante'),
    Categoria(nome: 'Amador', nivelCategoria: 'Amador'),
    Categoria(nome: 'Profissional', nivelCategoria: 'Profissional'),
  ];

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      value: _beach ? 0 : 1,
      duration: const Duration(milliseconds: 500),
    );
    super.initState();
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _key,
      child: AlertDialog(
        title: TextFormField(
          controller: _nameController,
          validator: (value) {
            if(value != null) {
              if(value.isEmpty) {
                return 'este campo é obrigatório';
              }
            }

            return null;
          },
          decoration: const InputDecoration(
            hintText: 'Nome do torneio'
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Selecione a modalidade'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _beach = false),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        width: 250,
                        height: _beach ? 140 : 150,
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('assets/images/quadra.jpg',),
                            fit: BoxFit.cover,
                            opacity: _beach ? .4 : 1
                          )
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => setState(() => _beach = true),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        width: 250,
                        height: _beach ? 150 : 140,
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('assets/images/areia.jpg'),
                            fit: BoxFit.cover,
                            opacity: _beach ? 1 : .4
                          )
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Modelo dos jogos'),
                const SizedBox(width: 16,),
                SizedBox(
                  width: 80,
                  child: DropdownButton<String>(
                    value: _selectedValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedValue = newValue;
                      });
                    },
                    items: ['2x2', '3x3', '4x4', '5x5', '6x6'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Misto?'),
                Transform.scale(
                  scale: .7,
                  child: Switch(value: _misto, onChanged: (value) => setState(() => _misto = value))
                )
              ],
            ),
            Row(
              children: [
                const Text('Classificação via:'),
                const SizedBox(width: 16,),
                DropdownButton<String>(
                  value: _selectedModel,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedModel = newValue!;
                    });
                  },
                  items: <String>[
                    'Side-out',
                    'Partida de 15 pontos',
                    'Partida de 21 pontos',
                    'Partida de 25 pontos'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('Categorias: (máx. 4)'),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(200, 30)
                        ),
                        onPressed: () {
                          if(_categoriasPadrao.length < 4) {
                            showDialog(
                                context: context,
                                builder: (context) => const AddCategoriaDialog()
                            ).then((categoria) {
                              if(categoria != null) {
                                setState(() => _categoriasPadrao.add(categoria));
                              }
                            });
                          }
                        },
                        label: const Text('Adicionar categoria'),
                        icon: const Icon(Icons.add)
                      )
                    ],
                  ),
                  if(_categoriasPadrao.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: Center(child: Text('Nenhuma categoria adicionada'),),
                    )
                  else
                    SizedBox(
                      height: 100,
                      width: 400,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categoriasPadrao.length,
                        itemBuilder: (context, index) {
                          final categoria = _categoriasPadrao[index];

                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Chip(
                              onDeleted: () => setState(() => _categoriasPadrao.removeAt(index)),
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(categoria.nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
                                  Row(
                                    children: [
                                      const Text('Pontos: '),
                                      Text('${categoria.nivelCategoria}')
                                    ],
                                  )
                                ],
                              )
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton.icon(
              onPressed: () {
                if(_key.currentState!.validate()) {
                  final Tournament tournament = Tournament(
                    nomeTorneio: _nameController.text,
                    campo: _beach ? 1 : 0,
                    modelo: TipoPartida.fromDescription(_selectedModel!),
                    categorias: _categoriasPadrao,
                    misto: _misto,
                    qtdJogadoresEmCampo: _selectedValue
                  );
                  Navigator.pop(context, tournament);
                }
              },
              label: const Text('Salvar')
          ),
          TextButton.icon(onPressed: () => Navigator.pop(context, false), label: const Text('Cancelar', style: TextStyle(color: Colors.red),)),
        ],
      ),
    );
  }
}

class InitTournamentDialogMobile extends StatefulWidget {
  const InitTournamentDialogMobile({super.key});

  @override
  State<InitTournamentDialogMobile> createState() => _InitTournamentDialogMobileState();
}

class _InitTournamentDialogMobileState extends State<InitTournamentDialogMobile> {
  final GlobalKey<FormState> _key = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  final PageController _pageController = PageController();
  String? _selectedValue = '2x2';
  String? _selectedModel = 'Side-out';
  bool _beach = true;
  bool _misto = true;
  final List<Categoria> _categoriasPadrao = [
    Categoria(nome: 'Tio Paulo', nivelCategoria: 'Iniciante'),
    Categoria(nome: 'Amador', nivelCategoria: 'Amador'),
    Categoria(nome: 'Profissional', nivelCategoria: 'Profissional'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Form(
        key: _key,
        child: TextFormField(
          controller: _nameController,
          validator: (value) {
            if(value != null) {
              if(value.isEmpty) {
                return 'este campo é obrigatório';
              }
            }

            return null;
          },
          decoration: const InputDecoration(
              hintText: 'Nome do torneio'
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Selecione a modalidade', textAlign: TextAlign.center,),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      if(page == 0) {
                        _beach = true;
                      }else {
                        _beach = false;
                      }
                      setState(() => _beach);
                    },
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/areia.jpg'),
                              fit: BoxFit.cover,
                            )
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/quadra.jpg',),
                              fit: BoxFit.cover,
                            )
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                        icon: const Icon(Icons.arrow_back_ios, size: 16,)
                    ),
                    Text(_beach ? 'Areia' : 'Quadra'),
                    IconButton(
                      onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                      icon: const Icon(Icons.arrow_forward_ios, size: 16)
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Modelo dos jogos'),
                const SizedBox(width: 16,),
                SizedBox(
                  width: 80,
                  child: DropdownButton<String>(
                    value: _selectedValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedValue = newValue;
                      });
                    },
                    items: ['2x2', '3x3', '4x4', '5x5', '6x6'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Misto?'),
                Transform.scale(
                    scale: .7,
                    child: Switch(value: _misto, onChanged: (value) => setState(() => _misto = value))
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Categorias: (máx. 4)'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(140, 30)
                        ),
                        onPressed: () {
                          if(_categoriasPadrao.length < 4) {
                            showDialog(
                                context: context,
                                builder: (context) => const AddCategoriaDialog()
                            ).then((categoria) {
                              if(categoria != null) {
                                setState(() => _categoriasPadrao.add(categoria));
                              }
                            });
                          }
                        },
                          label: const Text('Adicionar', style: TextStyle(fontSize: 12),),
                          icon: const Icon(Icons.add)
                      )
                    ],
                  ),
                  if(_categoriasPadrao.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: Center(child: Text('Nenhuma categoria adicionada'),),
                    )
                  else
                    SizedBox(
                      height: 100,
                      width: 400,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categoriasPadrao.length,
                        itemBuilder: (context, index) {
                          final categoria = _categoriasPadrao[index];
        
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Chip(
                                onDeleted: () => setState(() => _categoriasPadrao.removeAt(index)),
                                label: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(categoria.nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
                                    Row(
                                      children: [
                                        const Text('Pontos: '),
                                        Text('${categoria.nivelCategoria}')
                                      ],
                                    )
                                  ],
                                )
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton.icon(
            onPressed: () {
              if(_key.currentState!.validate()) {
                final Tournament tournament = Tournament(
                    nomeTorneio: _nameController.text,
                    campo: _beach ? 1 : 0,
                    modelo: TipoPartida.fromDescription(_selectedModel!),
                    categorias: _categoriasPadrao,
                    misto: _misto,
                    qtdJogadoresEmCampo: _selectedValue
                );
                Navigator.pop(context, tournament);
              }
            },
            label: const Text('Salvar')
        ),
        TextButton.icon(onPressed: () => Navigator.pop(context, false), label: const Text('Cancelar', style: TextStyle(color: Colors.red),)),
      ],
    );
  }
}
