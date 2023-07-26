(** 基本的なコンビネータなど *)

(** some very basic combinators *)

let flip f x y = f y x
let id x = x

(** tuple の操作のためのコンビネータ *)

let first f (a, b) = (f a, b)
let second f (a, b) = (a, f b)
let swap (x, y) = (y, x)

(** compositional functions *)

let ( <. ) f g x = f (g x)
let ( <.. ) f g x y = f (g x y)

(** Some operators for triple *)

