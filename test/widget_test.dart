// Smoke test placeholder. O teste de contador do template do Flutter foi
// removido — não representa nada deste app (que não tem contador, e o
// widget raiz MyApp depende de inicialização assíncrona feita em main(),
// como dotenv/GetStorage/DI, que um WidgetTester não configura sozinho).
// Nenhum teste de widget real foi escrito ainda pra RotaTec.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
