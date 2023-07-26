(** リスト系の追加関数

    - List.Extra モジュールなどとして定義した方が良いかも *)

open Combinator
(** open basic combinators *)

open Option_extra


(** 要素に Option を返す関数を適用して，初めて Some になったところでリストを分割する

    - Some になった値も返す
    - None になった部分のリストは反転して返すことに注意
    - [rev_appned] をすると元のリストから一つ要素を除いたものになる
    - [break_opt (fun x -> if x > 3 then Some x else None) \[1; 2; 3; 4; 5; 6\]
      ---> Some (4, (\[3; 2; 1\], \[5; 6\]))
      ]
    - Tail-recursive

    @return a list, (Some (f a, a list) | None) *)
let rev_break_opt f =
  let rec helper left = function
    | [] -> None
    | h :: t -> (
        match f h with
        | None -> helper (h :: left) t
        | Some s -> Some (s, (left, t)))
  in
  helper []



(** Either 型の要素のリストを左右に振り分ける *)
let partition_eithers l = List.partition_map id l

(** safe [List.combine] *)
let combine_opt list1 list2 =
  let rec helper = function
    | [], [] -> Some []
    | h1 :: t1, h2 :: t2 ->
        let+ t = helper (t1, t2) in
        (h1, h2) :: t
    | _ -> None
  in
  helper (list1, list2)



(** set minus. e.g. [set_minus \[1, 2, 3\] \[2, 4\] = \[1, 3\]] *)
let set_minus l r = List.filter (not <. flip List.mem r) l



(** [\[x -> y1; x -> y2; ...\]] を [\[x -> \[y1; y2; ...\]; ...\] にする *)
let gather mappings =
  let rec insert (x, y) = function
    | [] -> [ (x, [ y ]) ]
    | (x2, ys) :: t ->
        if x = x2 then (x2, y :: ys) :: t else (x2, ys) :: insert (x, y) t
  in
  List.fold_right insert mappings []

