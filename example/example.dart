import 'package:tyon/tyon.dart';

void main() {
  final map = tyonDecode('''
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
''');
  print(map['title']); // TYON Example
  print(map['list']); // [1, 2, 3]
  print(map['map']); // {first: John, last: Doe, age: 42, favorite numbers: [13, 42]}
  print(map['owner']); // {first: Mary, last: Sue, age: 36}
  print(map['employee']); // {first: Other, age: 25}
  print(map['typed-list']); // [{first: John, last: Doe, age: 42}, {first: Mary, last: Sue, age: 36}]
  print(map['points']); // [{x: 1, y: 2, z: 3}, {x: 4, y: 5, z: 6}, {x: 7, y: 8, z: 9}]
  print(map['people']); // [{first: John, last: Doe, age: 42}, {x: 1, y: 2}, {a: 1, b: 2, c: 3}]
}
