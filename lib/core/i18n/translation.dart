import 'package:get/get.dart';
import 'en.dart';
import 'pt.dart';
import 'es.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'pt_BR': ptBR,
    'es_ES': esES,
  };
}
