(** Parse *)

open Util
include Syntax

(** @return AST of defshape *)
let parse_graph = Parser.graph_eof Lexer.token <. Lexing.from_string

(** @return AST of defshape *)
let parse_rule = Parser.rule_eof Lexer.token <. Lexing.from_string

(** @return AST of defshape *)
let parse_exp = Parser.exp_eof Lexer.token <. Lexing.from_string
