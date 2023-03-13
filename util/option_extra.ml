(** OptionExtra. * monadic combinators for the Option type *)

open Combinator

(** *)
let ( >>= ) = Option.bind

let ( let* ) = Option.bind
let ( let+ ) x f = Option.map f x
let ( <|> ) l r = if Option.is_some l then l else r ()



(** monadic combinators for the traversible type *)

(** monadic [fold_left]

    - f を適用して，Some が帰ってきたら fold を続ける．
    - もし一度でも None が帰ってきたら，None を返す *)
let rec foldM f acc = function
  | [] -> Some acc
  | h :: t -> f acc h >>= flip (foldM f) t


(** Monadic while. Tail recursive.

    @param f Option 型を返す関数
    @param x 最初の入力値
    @return f をゼロ回以上適用して None になったら，その直前の x を返す *)
let rec whileM f x = match f x with None -> x | Some x -> whileM f x
