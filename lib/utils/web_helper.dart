import 'dart:js' as js;

void downloadWeb(String url, String fileName) {
  js.context.callMethod('open', [url, '_blank']);
}
