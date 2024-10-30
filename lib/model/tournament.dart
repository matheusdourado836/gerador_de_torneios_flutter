import 'package:volleyball_tournament_app/model/categoria.dart';
import 'package:volleyball_tournament_app/model/player.dart';
import 'enums.dart';

class Tournament {
  String? id;
  String? nomeTorneio;
  int? campo;
  int? qtdJogadores;
  TipoPartida? modelo;
  List<Categoria>? categorias;
  String? qtdJogadoresEmCampo;
  List<Player>? jogadores;
  bool? misto;

  Tournament({
    this.id,
    this.nomeTorneio,
    this.campo,
    this.qtdJogadores,
    this.modelo,
    this.categorias,
    this.qtdJogadoresEmCampo,
    this.jogadores,
    this.misto,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeTorneio': nomeTorneio,
      'modalidade': campo,
      'qtdJogadores': qtdJogadores,
      'qtdJogadoresEmCampo': qtdJogadoresEmCampo,
      'modelo': modelo?.valor ?? 0,
      'categorias': categorias?.map((categoria) => categoria.toJson()).toList(),
      'jogadores': jogadores?.map((jogador) => jogador.toJson()).toList(),
      'misto': misto
    };
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    print('JSON QUE TA CHEGANDO ${json}');
    return Tournament(
      id: json['id'],
      nomeTorneio: json['nomeTorneio'],
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
      misto: json['misto']
    );
  }
}
