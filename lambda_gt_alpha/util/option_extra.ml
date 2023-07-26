(** OptionExtra. * monadic combinators for the Option type *)

open Combinator

(** *)
let ( >>= ) = Option.bind

let ( let* ) = Option.bind
let ( <$> ) = Option.map
let ( let+ ) x f = Option.map f x
let ( <|> ) l r = if Option.is_some l then l else r ()

(** f を適用してどれか一つでも Some を返したらそれを返して終わりにする *)
let rec one_of f = function [] -> None | h :: t -> f h <|> fun _ -> one_of f t

let maybe default = function None -> default | Some s -> s

(** monadic combinators for the traversible type *)

(** monadic cons *)
let ( <::> ) h t = List.cons h <$> t

(** monadic [fold_left]

    - f を適用して，Some が帰ってきたら fold を続ける．
    - もし一度でも None が帰ってきたら，None を返す *)
let rec foldM f acc = function
  | [] -> Some acc
  | h :: t -> f acc h >>= flip (foldM f) t

(** monadic [fold_left_map]

    - f を適用して，Some が帰ってきたら fold を続ける．
    - もし一度でも None が帰ってきたら，None を返す *)
let rec fold_leftM f acc = function
  | [] -> Some (acc, [])
  | h :: t ->
      let* acc, h = f acc h in
      let+ acc, t = fold_leftM f acc t in
      (acc, h :: t)

(** monadic [List.map]

    - f を適用して，Some が帰ってきたら map を続ける．
    - もし一度でも None が帰ってきたら，None を返す *)
let rec mapM f = function
  | [] -> Some []
  | h :: t ->
      let* h = f h in
      let+ t = mapM f t in
      h :: t

(** Monadic while. Tail recursive.

    @param f Option 型を返す関数
    @param x 最初の入力値
    @return f をゼロ回以上適用して None になったら，その直前の x を返す *)
let rec whileM f x = match f x with None -> x | Some x -> whileM f x
