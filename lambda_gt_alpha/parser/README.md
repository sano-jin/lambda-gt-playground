# Parse

_Lexical/Syntax analyzer_

- [syntax.ml](syntax.ml)

  - AST definition

- [lexer.mll](lexer.mll)

  - Defines a token for lexing

- [parser.mly](parser.mly)

  - Defines a grammar for parsing

- [parse.ml](parse.ml)
  - Parser

## Infer についてのメモ

<https://discuss.ocaml.org/t/generate-a-parser-enabling-incremental-api-and-inspection-api/9380/2>

```bash
menhir --explain --inspection --table --dump --infer-write-query mockfile.ml parser.mly
# to generate mockfile.ml

ocamlfind ocamlc -I . -I src syntax.ml -c -o syntax.cmi

ocamlfind ocamlc -I lib -package menhirLib -i mockfile.ml > sigfile
# to generate sigfile. Note that -I lib refers to the directory of external modules, their .cm[io] files should be ready to use.

menhir --explain --inspection --table --dump --infer-read-reply sigfile parser.mly
# to generate especially parser_e.ml, parser_e.mli, .conflicts and automaton.
```
