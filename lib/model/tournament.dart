import 'package:volleyball_tournament_app/model/categoria.dart';
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
  int? qtdJogadores;
  TipoPartida? modelo;
  List<Categoria>? categorias;
  String? qtdJogadoresEmCampo;
  List<Player>? jogadores;
  List<Partida>? partidas;
  bool? misto;

  Tournament({
    this.id,
    this.createdAt,
    this.nomeTorneio,
    this.codigo,
    this.senha,
    this.campo,
    this.qtdJogadores,
    this.modelo,
    this.categorias,
    this.qtdJogadoresEmCampo,
    this.jogadores,
    this.partidas,
    this.misto,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'nomeTorneio': nomeTorneio,
      'codigo': codigo,
      'senha': senha,
      'modalidade': campo,
      'qtdJogadores': qtdJogadores,
      'qtdJogadoresEmCampo': qtdJogadoresEmCampo,
      'modelo': modelo?.valor ?? 0,
      'categorias': categorias?.map((categoria) => categoria.toJson()).toList(),
      'jogadores': jogadores?.map((jogador) => jogador.toJson()).toList(),
      'partidas': partidas?.map((partida) => partida.toJson()).toList(),
      'misto': misto
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
      qtdJogadores: json['qtdJogadores'],
      qtdJogadoresEmCampo: json['qtdJogadoresEmCampo'],
      modelo: json['modelo'] != null ? TipoPartida.fromCode(json['modelo']) : null,
      categorias: json['categorias'] != null
          ? (json['categorias'] as List).map((categoria) => Categoria.fromJson(categoria)).toList()
          : null,
      jogadores: json['jogadores'] != null
          ? (json['jogadores'] as List).map((jogador) => Player.fromJson(jogador)).toList()
          : null,
        partidas: json['partidas'] != null
          ? (json['partidas'] as List).map((partida) => Partida.fromJson(partida)).toList()
          : null,
      misto: json['misto']
    );
  }
}
