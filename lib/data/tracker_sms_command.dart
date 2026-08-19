/// Templates de comando SMS por modelo de rastreador — cada comando tem um
/// texto com placeholders (`{chave}`) e os parâmetros preenchíveis, prontos
/// pra virar campos de texto na tela. Pra adicionar outro modelo no futuro,
/// basta criar outra `List<SmsCommandTemplate>` e referenciar em [byModel].
class SmsCommandParam {
  final String key;
  final String label;
  final String defaultValue;

  const SmsCommandParam({required this.key, required this.label, this.defaultValue = ''});
}

class SmsCommandTemplate {
  final String label;
  final String description;
  final String template;
  final List<SmsCommandParam> params;

  /// Comandos obrigatórios pra ativar o rastreador (mostrados em destaque).
  final bool required;

  const SmsCommandTemplate({
    required this.label,
    required this.description,
    required this.template,
    this.params = const [],
    this.required = false,
  });

  /// Monta o texto final substituindo `{chave}` pelo valor de cada parâmetro.
  String build(Map<String, String> values) {
    var result = template;
    for (final param in params) {
      final value = values[param.key] ?? param.defaultValue;
      result = result.replaceAll('{${param.key}}', value);
    }
    return result;
  }
}

enum TrackerModel { j16 }

/// Comandos do J16 — pesquisados no protocolo padrão usado por revendedores
/// de rastreador no Brasil (ex.: central de ajuda Softruck, wiki SmartGPS).
final _j16Commands = <SmsCommandTemplate>[
  SmsCommandTemplate(
    label: 'APN',
    description: 'Configura o acesso à internet do chip. Confira com a operadora se mudar de SIM.',
    template: 'APN,{apn},{usuario},{senha}#',
    required: true,
    params: const [
      SmsCommandParam(key: 'apn', label: 'APN', defaultValue: 'vivaconecta.alga.br'),
      SmsCommandParam(key: 'usuario', label: 'Usuário', defaultValue: 'algar'),
      SmsCommandParam(key: 'senha', label: 'Senha', defaultValue: '1212'),
    ],
  ),
  SmsCommandTemplate(
    label: 'Servidor',
    description: 'Aponta o rastreador pro nosso servidor.',
    template: 'SERVER,0,{ip},{porta},0#',
    required: true,
    params: const [
      SmsCommandParam(key: 'ip', label: 'IP do servidor', defaultValue: '167.99.126.116'),
      SmsCommandParam(key: 'porta', label: 'Porta', defaultValue: '5023'),
    ],
  ),
  SmsCommandTemplate(
    label: 'Fuso horário',
    description: 'Ajusta o fuso do rastreador (Brasília = UTC-3).',
    template: 'GMT,W,{horas},{minutos}#',
    params: const [
      SmsCommandParam(key: 'horas', label: 'Horas', defaultValue: '3'),
      SmsCommandParam(key: 'minutos', label: 'Minutos', defaultValue: '0'),
    ],
  ),
  SmsCommandTemplate(
    label: 'Intervalo de atualização',
    description: 'Frequência de envio de posição com ignição ligada/desligada (segundos).',
    template: 'TIMER,{ligado},{desligado}#',
    params: const [
      SmsCommandParam(key: 'ligado', label: 'Ignição ligada (s)', defaultValue: '30'),
      SmsCommandParam(key: 'desligado', label: 'Ignição desligada (s)', defaultValue: '3600'),
    ],
  ),
  const SmsCommandTemplate(label: 'Bloquear veículo', description: 'Corta a ignição remotamente.', template: 'RELAY,1#'),
  const SmsCommandTemplate(label: 'Desbloquear veículo', description: 'Libera a ignição.', template: 'RELAY,0#'),
  const SmsCommandTemplate(label: 'Reiniciar', description: 'Reinicia o módulo GSM/GPS do rastreador.', template: 'RESET#'),
  const SmsCommandTemplate(label: 'Status', description: 'Pede o status atual do equipamento.', template: 'STATUS#'),
];

List<SmsCommandTemplate> commandsFor(TrackerModel model) {
  switch (model) {
    case TrackerModel.j16:
      return _j16Commands;
  }
}
