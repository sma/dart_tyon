// ignore_for_file: inference_failure_on_collection_literal

import 'package:tyon/tyon.dart';
import 'package:test/test.dart';

void main() {
  test('empty file', () {
    expect(tyonDecode(''), equals({}));
  });

  test('just a comment', () {
    expect(tyonDecode('; this is a comment'), equals({}));
  });

  test('literal key/value', () {
    expect(tyonDecode(' a = 1 '), equals({'a': '1'}));
    expect(tyonDecode('foo= bar '), equals({'foo': 'bar'}));
    expect(tyonDecode('foo =bar;commented '), equals({'foo': 'bar'}));
  });

  test('string key/value', () {
    expect(tyonDecode('"" = "" '), equals({'': ''}));
    expect(tyonDecode('" a " = "();" '), equals({' a ': '();'}));
    expect(tyonDecode('"""" = """" '), equals({'"': '"'}));
  });

  test('unusual literals', () {
    expect(
      tyonDecode('a=[123 true 2023/07/04 first-name don\'t_worry quoted"text"]'),
      equals({
        'a': [
          '123',
          'true',
          '2023/07/04',
          'first-name',
          "don't_worry",
          'quoted"text"',
        ],
      }),
    );
  });

  test('simple list', () {
    expect(
        tyonDecode('numbers = [1 2 3]'),
        equals({
          'numbers': ['1', '2', '3']
        }));
    expect(
        tyonDecode('one = [one]'),
        equals({
          'one': ['one']
        }));
    expect(tyonDecode('null = []'), equals({'null': []}));
  });

  test('nested list of lists', () {
    expect(
      tyonDecode('numbers = [1 [2 3] 4 []]'),
      equals({
        'numbers': [
          '1',
          ['2', '3'],
          '4',
          [],
        ]
      }),
    );
  });

  test('nested list of maps', () {
    expect(
      tyonDecode('''
      nested = [          ; a list containing:
          42              ;   a value
          [1 2 3]         ;   a nested list
          (               ;   a map
              first = 1
              second = 2
          )
      ]
      '''),
      equals({
        'nested': [
          '42',
          ['1', '2', '3'],
          {'first': '1', 'second': '2'}
        ]
      }),
    );
  });

  test('map', () {
    expect(
        tyonDecode('''
      person = (
          first = John
          last = Doe
          age = 42
          "favorite numbers" = [1 2 3]
      )'''),
        equals({
          'person': {
            'first': 'John',
            'last': 'Doe',
            'age': '42',
            'favorite numbers': ['1', '2', '3'],
          },
        }));
  });

  test('type declaration', () {
    expect(tyonDecode('/person = (first-name middle-initial last-name age)'), equals({}));
  });

  test('typed map', () {
    expect(
      tyonDecode('''
      /person = (first middle last age "favorite number")
      owner = /person (Mary X Sue 36 "fourty two")
      '''),
      equals(
        {
          'owner': {
            'first': 'Mary',
            'middle': 'X',
            'last': 'Sue',
            'age': '36',
            'favorite number': 'fourty two',
          },
        },
      ),
    );
  });

  test('map with inline type', () {
    expect(
      tyonDecode('inline = /(a b c)(1 2 3)'),
      equals({
        'inline': {'a': '1', 'b': '2', 'c': '3'},
      }),
    );
  });

  test('list with inline type', () {
    expect(
      tyonDecode('''
      points = /(x y) [
        (1 2)           ; x = 1, y = 2
        (3 4)           ; x = 3, y = 4
       ]'''),
      equals({
        'points': [
          {'x': '1', 'y': '2'},
          {'x': '3', 'y': '4'}
        ],
      }),
    );
  });

  test('list with untyped type', () {
    expect(
      tyonDecode('''
      /person = (first middle last age)   ; declare type 'person'
      list = /person [
        (John D Doe 42)                 ; first = John, middle = D, last = Doe, age = 42
        /_ (first = Mary age = 42)      ; explicitly untyped map overrides the parent type
        /(last age)(Sue 36)             ; last = Sue, age = 36
        []                              ; empty list
        [(John X Doe 41)]
      ]'''),
      equals({
        'list': [
          {'first': 'John', 'middle': 'D', 'last': 'Doe', 'age': '42'},
          {'first': 'Mary', 'age': '42'},
          {'last': 'Sue', 'age': '36'},
          [],
          [
            {'first': 'John', 'middle': 'X', 'last': 'Doe', 'age': '41'},
          ],
        ],
      }),
    );
  });

  test('typed map with omitted values', () {
    expect(
      tyonDecode('''
        a=/(x y)(1 _)
        b=/(x y)(_ 2)
        c=/(x y)(_ _)
      '''),
      equals({
        'a': {'x': '1'},
        'b': {'y': '2'},
        'c': {},
      }),
    );
  });

  test('example', () {
    expect(
      tyonDecode('''
      ; This is a TYON document

      title = "TYON Example" ; files are implicitly maps

      list = [1 2 3]

      map = (
          first = John
          last = Doe
          age = 42
          "favorite numbers" = [13 42]
      )

      ; strings can contain any character except ", which is escaped as ""
      string = "hello, this is a string
      with some ""quoted text"" and
      multiple lines"

      ; a type declaration specifies the keys for the type
      /person = (first last age)

      ; a typed map matches the type keys to values in order
      owner = /person (Mary Sue 36) ; first = Mary, last = Sue, age = 36

      ; a value of _ in a typed map means there is no corresponding value
      employee = /person (Other _ 25) ; first = Other, age = 25

      ; lists can also be typed, with the type applying to the children
      typed-list = /person [
          (John Doe 42)
          (Mary Sue 36)
      ]

      ; types can be declared inline
      points = /(x y z) [
          (1 2 3)
          (4 5 6)
          (7 8 9)
      ]

      ; types can be overridden
      people = /person [
          (John Doe 42)
          /(x y) (1 2)    ; type overridden by the inline type
          /_ (            ; type overridden to be untyped
              a = 1
              b = 2
              c = 3
          )
      ]
    '''),
      equals({
        'title': 'TYON Example',
        'list': ['1', '2', '3'],
        'map': {
          'first': 'John',
          'last': 'Doe',
          'age': '42',
          'favorite numbers': ['13', '42'],
        },
        'string': 'hello, this is a string\n      with some "quoted text" and\n      multiple lines',
        'owner': {'first': 'Mary', 'last': 'Sue', 'age': '36'},
        'employee': {'first': 'Other', 'age': '25'},
        'typed-list': [
          {'first': 'John', 'last': 'Doe', 'age': '42'},
          {'first': 'Mary', 'last': 'Sue', 'age': '36'},
        ],
        'points': [
          {'x': '1', 'y': '2', 'z': '3'},
          {'x': '4', 'y': '5', 'z': '6'},
          {'x': '7', 'y': '8', 'z': '9'},
        ],
        'people': [
          {'first': 'John', 'last': 'Doe', 'age': '42'},
          {'x': '1', 'y': '2'},
          {'a': '1', 'b': '2', 'c': '3'},
        ],
      }),
    );
  });

  test('unfinished encoder', () {
    final tyon = '''
      ; an example
      name=John
      age=42
      address=(
        street="Main Street"
        city="New York"
        zip=12345
      )
      friends=[
        ( name=Mary age=40 )
        ( name=Bob age=45 )
      ]''';
    expect(tyonEncode(tyonDecode(tyon)), equals('''
name = John
age = 42
address = (
  street = "Main Street"
  city = "New York"
  zip = 12345
)
friends = [
  (
    name = Mary
    age = 40
  )
  (
    name = Bob
    age = 45
  )
]
'''));
  });
}
