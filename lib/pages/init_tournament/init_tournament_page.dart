import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/pages/init_tournament/widgets/add_chave_dialog.dart';
import '../../model/categoria.dart';
import '../../model/tournament.dart';
import 'widgets/add_categoria_dialog.dart';

class InitTournamentPage extends StatefulWidget {
  const InitTournamentPage({super.key});

  @override
  State<InitTournamentPage> createState() => _InitTournamentPageState();
}

class _InitTournamentPageState extends State<InitTournamentPage> {
  final GlobalKey<FormState> _key = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final PageController _pageController = PageController();
  String? _selectedValue = '2x2';
  String? _selectedModel = 'Categorias';
  bool _beach = true;
  bool _misto = true;
  bool _loading = false;
  final List<Chave> _chaves = [
    Chave(nome: 'Chave A', times: {}),
    Chave(nome: 'Chave B', times: {}),
  ];
  final List<Categoria> _categoriasPadrao = [
    Categoria(nome: 'Iniciante', nivelCategoria: 'Iniciante'),
    Categoria(nome: 'Amador', nivelCategoria: 'Amador'),
    Categoria(nome: 'Profissional', nivelCategoria: 'Profissional'),
  ];
  late final dataController = Provider.of<DataController>(context, listen: false);

  Future<String> gerarCodigoTorneio() async => await dataController.gerarCodigoTorneio();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Iniciar torneio'),
      ),
      body: Form(
        key: _key,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(
            child: SizedBox(
              width: width < 800 ? width : width * .55,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
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
                  TextFormField(
                    controller: _passController,
                    validator: (value) {
                      if(value != null) {
                        if(value.isEmpty) {
                          return 'este campo é obrigatório';
                        }
                      }

                      return null;
                    },
                    decoration: const InputDecoration(
                        hintText: 'Senha de administrador'
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecione a modalidade',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Text('Misto?'),
                          Transform.scale(
                              scale: .7,
                              child: Switch(value: _misto, onChanged: (value) => setState(() => _misto = value))
                          )
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Dividir jogadores por:'),
                      const SizedBox(width: 16),
                      DropdownButton(
                        value: _selectedModel,
                        items: ['Categorias', 'Chaves'].map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item)
                        )).toList(),
                        onChanged: (newItem) {
                          setState(() => _selectedModel = newItem);
                        }
                      ),
                    ],
                  ),
                  if(_selectedModel == 'Categorias')
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
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Chaves: (máx. 4)'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    fixedSize: const Size(140, 30)
                                ),
                                onPressed: () {
                                  if(_chaves.length < 4) {
                                    showDialog(
                                        context: context,
                                        builder: (context) => const AddChaveDialog()
                                    ).then((chave) {
                                      if(chave != null) {
                                        setState(() => _chaves.add(chave));
                                      }
                                    });
                                  }
                                },
                                label: const Text('Adicionar', style: TextStyle(fontSize: 12),),
                                icon: const Icon(Icons.add)
                              )
                            ],
                          ),
                          if(_chaves.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 24.0),
                              child: Center(child: Text('Nenhuma chave adicionada'),),
                            )
                          else
                            SizedBox(
                              height: 100,
                              width: 400,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _chaves.length,
                                itemBuilder: (context, index) {
                                  final chave = _chaves[index];

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Chip(
                                      onDeleted: () => setState(() => _chaves.removeAt(index)),
                                      label: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(chave.nome!, style: const TextStyle(fontWeight: FontWeight.bold),),
                                          const Text('Jogadores: Nenhum')
                                        ],
                                      )
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  if(_loading)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(strokeWidth: 2,)
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        if(_key.currentState!.validate()) {
                          setState(() => _loading = true);
                          final codigo = await gerarCodigoTorneio();
                          setState(() => _loading = false);
                          if(_selectedModel == 'Categorias') {
                            _chaves.clear();
                          }else {
                            _categoriasPadrao.clear();
                          }
                          final Tournament tournament = Tournament(
                            createdAt: DateTime.now(),
                            nomeTorneio: _nameController.text,
                            senha: _passController.text,
                            codigo: codigo,
                            campo: _beach ? 1 : 0,
                            modelo: _selectedModel,
                            categorias: _categoriasPadrao,
                            chaves: _chaves,
                            misto: _misto,
                            qtdJogadoresEmCampo: _selectedValue
                          );
                          dataController.tournament = tournament;
                          GoRouter.of(context).pushNamed('choose-players');
                        }
                      },
                      label: const Text('Salvar')
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
