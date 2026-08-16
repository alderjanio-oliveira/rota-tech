class MotionConfig {
  static const int fps = 30; // altere aqui no futuro

  /// Depois desse tempo sem uma posição real do GPS, para de projetar (dead
  /// reckoning) e congela no último ponto — sem isso, o motor continuava
  /// "chutando" a posição pra frente indefinidamente.
  static const Duration maxPredictionAge = Duration(seconds: 20);

  /// A partir de quanto tempo sem posição real um hiato passa a "quebrar" a
  /// trilha num trecho novo (em vez de só ligar com uma linha até o próximo
  /// ponto real). Precisa ser bem maior que o intervalo normal de report do
  /// rastreador, senão qualquer pausa comum entre pings já fragmentava a
  /// linha inteira — reservado pra hiatos de verdade (tela bloqueada, sem
  /// sinal por um tempo).
  static const Duration trailGapThreshold = Duration(minutes: 2);
}
