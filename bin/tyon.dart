import 'dart:convert';
import 'dart:io';

import 'package:tyon/tyon.dart';

void main(List<String> arguments) {
  if (arguments.length < 2 || arguments[0] != 'to-json') {
    print('Usage: tyon to-json <files>');
    exit(1);
  }
  for (final file in arguments.skip(1)) {
    final tyon = File(file).readAsStringSync();
    final json = tyonDecode(tyon);
    final name = '${file.endsWith('.tyon') ? file.substring(0, file.length - 5) : file}.json';
    File(name).writeAsStringSync(jsonEncode(json));
  }
}
