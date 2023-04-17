/// Encodes [value] as a TYON string.
String tyonEncode(Map<String, dynamic> value) {
  final sink = StringBuffer();
  for (final entry in value.entries) {
    _tyonEncodeLiteral(entry.key, sink);
    sink.write(' = ');
    _tyonEncode(entry.value, 0, sink);
  }
  return sink.toString();
}

/// Encodes [value] as a TYON literal, possibly omitting double quotes.
void _tyonEncodeLiteral(String value, StringSink sink) {
  if (RegExp(r'^[^\s()\[\]=;]+$').hasMatch(value)) {
    sink.write(value);
  } else {
    sink.write('"');
    sink.write(value.replaceAll('"', '""'));
    sink.write('"');
  }
}

/// Encodes [value] as a TYON literal, string, map or list, using [indent]
/// to indent nested maps and lists. Currently, no typed values are used.
void _tyonEncode(dynamic value, int indent, StringSink sink) {
  if (value is Map<String, dynamic>) {
    if (value.isEmpty) {
      sink.write('()\n');
    } else {
      sink.write('(\n');
      indent++;
      for (final entry in value.entries) {
        sink.write('  ' * indent);
        sink.write(entry.key);
        sink.write(' = ');
        _tyonEncode(entry.value, indent, sink);
      }
      --indent;
      sink.write('${'  ' * indent})\n');
    }
  } else if (value is List<dynamic>) {
    if (value.isEmpty) {
      sink.write('[]\n');
    } else {
      sink.write('[\n');
      indent++;
      for (final item in value) {
        sink.write('  ' * indent);
        _tyonEncode(item, indent, sink);
      }
      --indent;
      sink.write('${'  ' * indent}]\n');
    }
  } else {
    _tyonEncodeLiteral('$value', sink);
    sink.write('\n');
  }
}
