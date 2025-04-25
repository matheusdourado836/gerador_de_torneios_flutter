import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/etapas.dart';
import 'package:volleyball_tournament_app/model/partida.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'enums.dart';

class Tournament {
  String? id;
  DateTime? createdAt;
  String? nomeTorneio;
  String? codigo;
  String? senha;
  int? campo;
  String? modelo;
  List<Categoria>? categorias;
  List<Chave>? chaves;
  String? qtdJogadoresEmCampo;
  List<Player>? jogadores;
  List<Partida>? partidas;
  List<PartidaChave>? partidasChave;
  bool? misto;
  bool? ativo;
  AllFases? selectedStage;
  List<Team>? timesClassificados;

  Tournament({
    this.id,
    this.createdAt,
    this.nomeTorneio,
    this.codigo,
    this.senha,
    this.campo,
    this.modelo,
    this.categorias,
    this.chaves,
    this.qtdJogadoresEmCampo,
    this.jogadores,
    this.partidas,
    this.partidasChave,
    this.misto,
    this.ativo,
    this.selectedStage,
    this.timesClassificados,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'nomeTorneio': nomeTorneio,
      'codigo': codigo,
      'senha': senha,
      'modalidade': campo,
      'qtdJogadoresEmCampo': qtdJogadoresEmCampo,
      'modelo': modelo,
      'categorias': categorias?.map((categoria) => categoria.toJson()).toList(),
      'chaves': chaves?.map((chaves) => chaves.toJson()).toList(),
      'jogadores': jogadores?.map((jogador) => jogador.toJson()).toList(),
      'partidas': partidas?.map((partida) => partida.toJson()).toList(),
      'misto': misto,
      'ativo': ativo,
      'selectedStage': null,
    };
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      nomeTorneio: json['nomeTorneio'],
      codigo: json['codigo'],
      senha: json['senha'],
      campo: json['modalidade'],
      qtdJogadoresEmCampo: json['qtdJogadoresEmCampo'],
      modelo: json['modelo'],
      categorias: json['categorias'] != null
        ? (json['categorias'] as List).map((categoria) => Categoria.fromJson(categoria)).toList()
        : null,
      chaves: json['chaves'] != null
        ? (json['chaves'] as List).map((chave) => Chave.fromJson(chave)).toList()
        : null,
      jogadores: json['jogadores'] != null
        ? (json['jogadores'] as List).map((jogador) => Player.fromJson(jogador)).toList()
        : null,
      partidas: json['partidas'] != null
        ? (json['partidas'] as List).map((partida) => Partida.fromJson(partida)).toList()
        : null,
      partidasChave: json['partidasChave'] != null
        ? (json['partidasChave'] as Map).entries.map((e) => PartidaChave(
              nome: e.key,
              partidas: (e.value as List).map((p) => Partida.fromJson(p)).toList()
          )).toList()
        : null,
      misto: json['misto'],
      ativo: json['ativo'],
      selectedStage: json['selectedStage'] != null
        ? AllFases.fromJson(json['selectedStage'])
        : null
    );
  }
}