/// Parses [input] as TYON document and returns the result.
Map<String, dynamic> tyonDecode(String input) {
  return _TYONParser(_TYONLexer(input)).parse();
}

class _TYONToken {
  const _TYONToken(this.type, this.value);
  final int type;
  final String value;

  bool get isEOF => type == 0;
  bool isSymbol(String symbol) => type == 1 && value == symbol;
  bool get isString => type == 2;
  bool get isLiteral => type == 3;

  @override
  String toString() => type == 0 ? 'end of file' : value;
}

/* In Dart 3 you could use this instead of the class above:
typedef _TYONToken = (int, String);

extension on _TYONToken {
  bool get isEOF => $1 == 0;
  bool isSymbol(String symbol) => $1 == 1 && $2 == symbol;
  bool get isString => $1 == 2;
  bool get isLiteral => $1 == 3;
  String get value => $2;
}
*/

class _TYONLexer {
  _TYONLexer(String input) : _iterator = _regex.allMatches(input).iterator;
  final Iterator<RegExpMatch> _iterator;

  /// Matches a symbol (one of `/()[]=`), a string, or a literal.
  static final RegExp _regex = RegExp(r'[/()\[\]=]|"(?:[^"]|"")*"|;[^\n]*|[^\s()\[\]=;]+');

  _TYONToken nextToken() {
    if (!_iterator.moveNext()) return _TYONToken(0, '');
    String token = _iterator.current[0]!;
    if (token.startsWith(';')) return nextToken();
    if ('/()[]='.contains(token)) return _TYONToken(1, token);
    if (token.startsWith('"') && token.endsWith('"')) {
      return _TYONToken(2, token.substring(1, token.length - 1).replaceAll('""', '"'));
    }
    return _TYONToken(3, token);
  }
}

class _TYONParser {
  _TYONParser(this.lexer);
  final _TYONLexer lexer;

  /// Maps type names to their type.
  final _types = <String, List<String>>{};

  _TYONToken _nextToken() => lexer.nextToken();

  void _expect(String symbol) {
    final token = _nextToken();
    if (!token.isSymbol(symbol)) throw 'Expected $symbol, got $token';
  }

  // tyon = {typeDecl | keyValuePair}
  Map<String, dynamic> parse() {
    final result = <String, dynamic>{};
    for (var token = _nextToken(); !token.isEOF; token = _nextToken()) {
      if (token.isSymbol('/')) {
        _parseTypeDecl();
      } else {
        result.addEntries([_parseKeyValuePair(token)]);
      }
    }
    return result;
  }

  // typeDecl = '/' Literal '=' keys
  void _parseTypeDecl() {
    final token = _nextToken();
    if (!token.isLiteral) throw 'Expected type name, got $token';
    final name = token.value;
    _expect('=');
    _expect('(');
    _types[name] = _parseKeys();
  }

  // keys = '(' {key} ')'
  List<String> _parseKeys() {
    final type = <String>[];
    for (var token = _nextToken(); !token.isSymbol(')'); token = _nextToken()) {
      if (token.isEOF) throw 'Expected ), got $token';
      type.add(_parseKey(token));
    }
    return type;
  }

  // keyValuePair = key '=' value
  MapEntry<String, dynamic> _parseKeyValuePair(_TYONToken token) {
    final key = _parseKey(token);
    _expect('=');
    return MapEntry(key, _parseValue(_nextToken()));
  }

  // key = Literal | String
  String _parseKey(_TYONToken token) {
    if (token.isLiteral) return token.value;
    if (token.isString) return token.value;
    throw 'Expected key, got $token';
  }

  // value = Literal | String | list | map | typedValue
  dynamic _parseValue(_TYONToken token) {
    if (token.isLiteral) return token.value;
    if (token.isString) return token.value;
    if (token.isSymbol('[')) return _parseList();
    if (token.isSymbol('(')) return _parseMap();
    if (token.isSymbol('/')) return _parseTypedOrUntypedValue();
    throw 'Expected value, got $token';
  }

  // list = '[' {value} ']'
  List<dynamic> _parseList() {
    final result = <dynamic>[];
    for (var token = _nextToken(); !token.isSymbol(']'); token = _nextToken()) {
      if (token.isEOF) throw 'Expected ], got $token';
      result.add(_parseValue(token));
    }
    return result;
  }

  // map = '(' {keyValuePair} ')'
  Map<String, dynamic> _parseMap() {
    final result = <String, dynamic>{};
    for (var token = _nextToken(); !token.isSymbol(')'); token = _nextToken()) {
      if (token.isEOF) throw 'Expected ), got $token';
      result.addEntries([_parseKeyValuePair(token)]);
    }
    return result;
  }

  // typedValue = inlineType (listValues | mapValues)
  // untypedValue = '/' '_' (list | map)
  dynamic _parseTypedOrUntypedValue() {
    final type = _parseTypeOrInlineType();
    final token = _nextToken();
    if (type == null) {
      if (token.isSymbol('[')) return _parseList();
      if (token.isSymbol('(')) return _parseMap();
    } else {
      if (token.isSymbol('[')) return _parseListValues(type);
      if (token.isSymbol('(')) return _parseMapValues(type);
    }
    throw 'Expected [ or (, got $token';
  }

  // inlineType = '/' (Literal | keys)
  List<String>? _parseTypeOrInlineType() {
    final token = _nextToken();
    if (token.isLiteral) {
      if (token.value == '_') return null;
      return _types[token.value] ?? (throw 'Unknown type ${token.value}');
    }
    if (token.isSymbol('(')) return _parseKeys();
    throw 'Expected type name or inline type, got $token';
  }

  // listValues = '[' {listValue} ']'
  List<dynamic> _parseListValues(List<String> type) {
    final result = <dynamic>[];
    for (var token = _nextToken(); !token.isSymbol(']'); token = _nextToken()) {
      if (token.isEOF) throw 'Expected ], got $token';
      result.add(_parseListValue(type, token));
    }
    return result;
  }

  // listValue = listValues | typedList | typedMap | untypedMap | mapValues
  dynamic _parseListValue(List<String> type, _TYONToken token) {
    if (token.isSymbol('/')) return _parseTypedOrUntypedValue();
    if (token.isSymbol('[')) return _parseListValues(type);
    if (token.isSymbol('(')) return _parseMapValues(type);
    throw 'Expected / or [ or (, got $token';
  }

  // mapValues = '(' {value} ')'
  Map<String, dynamic> _parseMapValues(List<String> type) {
    final result = <String, dynamic>{};
    for (final key in type) {
      final token = _nextToken();
      if (token.isEOF || token.isSymbol(')')) throw 'Expected value, got $token';
      if (token.isLiteral && token.value == '_') continue;
      result[key] = _parseValue(token);
    }
    _expect(')');
    return result;
  }
}
