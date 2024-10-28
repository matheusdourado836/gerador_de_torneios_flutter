class Categoria {
  String? nome;
  String? criterio;
  int? pontos;

  Categoria({this.nome, this.criterio, this.pontos});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    nome: json['nome'],
    criterio: json['criterio'],
    pontos: json['pontos'],
  );

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "criterio": criterio,
    "pontos": pontos,
  };
}