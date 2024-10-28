enum TipoPartida {
  sideOut(0, 'Side-out'),
  partida15Pontos(1, 'Partida de 15 pontos'),
  partida21Pontos(2, 'Partida de 21 pontos'),
  partida25Pontos(3, 'Partida de 25 pontos');

  final int valor;
  final String description;

  const TipoPartida(this.valor, this.description);

  // Método para obter a classificação pelo número
  static TipoPartida? fromCode(int code) {
    return TipoPartida.values.firstWhere((partida) => partida.valor == code);
  }

  // Método para obter a classificação pelo descrição
  static TipoPartida? fromDescription(String description) {
    return TipoPartida.values.firstWhere((partida) => partida.description == description);
  }
}
