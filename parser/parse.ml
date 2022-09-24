(** Parse *)

open Util
include Syntax

(** @return AST of graph *)
let parse_graph = Parser.graph_eof Lexer.token <. Lexing.from_string

(** @return AST of expression *)
let parse_exp = Parser.exp_eof Lexer.token <. Lexing.from_string
