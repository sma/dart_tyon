TYON
====

This is a parser for [Tyon](https://github.com/defiant00/tyon) documents written in Dart 3. Currently, this package is just a parser, a.k.a. decoder, and not an encoder. For compatibility with JSON, the `tyonDecode` function returns a `Map<String, dynamic>`, even if the specification seems to allow multiple identical keys and requires the keys to be ordered. Also, comments are obviously lost when parsing a document. All values are strings, lists or maps.

## Usage

```dart
print(tyonDecode('''
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
'''));
```

## Grammar

I derived this EBNF grammar from the specification:

```ebnf
tyon = { typeDecl | keyValuePair }
typeDecl = '/' Literal '=' keys
keys = '(' { key } ')'
key = Literal | String
keyValuePair = key '=' value
value = Literal | String | list | map | typedValue
list = '[' { value } ']'
map = '(' { keyValuePair } ')'
typedValue = inlineType (listValues | mapValues)
inlineType = "/" (Literal | keys)
listValues = '[' { listValue } ']'
listValue = listValues | typedValue | untypedValue | mapValues
untypedValue = "/" "_" (list | map)
mapValues = "(" { value } ")"
```

A `Literal` is a sequence of non-whitespace characters that doesn't include `()[]=;"` and that doesn't start with a `/`. A `String` is enclosed in `"` and may include any unicode character but `"`. If you want to include a `"`, use `""`.

The number of values in `mapValues` must match the number of keys from its type.
