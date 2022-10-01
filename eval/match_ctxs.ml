open Util
open Util.OptionExtra
open Syntax

(** atom のマッチング終了後，graph context のマッチングの前に，グラフのリンク名を変換し，fusion を補う．*)

let subst_link_of_link link_env x =
  Option.value (List.assoc_opt x link_env) ~default:x

let subst_link_of_atoms = List.map <. second <. List.map <. subst_link_of_link

(** target graph において同じリンク名となるリンクに対応している，テンプレートのリンクをまとめる， *)
let gather_links =
  (List.map @@ List.map @@ fun x -> LocalLink x)
  <. List.map snd <. ListExtra.gather <. List.map swap

(** link_env から補った，局所リンク同士を引数にもつ fusion を作る *)
let local2local_fusions_of_link_env =
  let helper = function [] -> [] | x :: xs -> List.map (fusion_of x) xs in
  List.concat_map helper <. gather_links

(** マッチング対象のグラフでは自由リンクだが，テンプレートのリンクでは局所リンクであった場合に，自由リンクと局所リンクの fusion
    を作ってグラフに補う． *)
let local2free_fusions_of_link_env =
  List.map (fun (x, y) -> fusion_of (LocalLink x) y)
  <. List.filter (is_free_link <. snd)

(** マッチング対象のグラフのリンク名をテンプレートのリンク名に変換する． [link_env] と [rest_graph] を引数にとる． *)
let subst_links_of_rest_graph =
  let helper = function
    | x, (LocalLink _ as y) -> Some (y, LocalLink x)
    | _ -> None
  in
  subst_link_of_atoms <. List.filter_map helper

(** find_atoms をした後の link_env の後処理をする． 自由リンクと局所リンクを引数にもつ fusion を作る．
    マッチング対象のグラフの局所リンク名をルール左辺のものに合わせる． *)
let rest_graph_of (link_env, rest_graph) =
  subst_links_of_rest_graph link_env rest_graph
  @ local2local_fusions_of_link_env link_env
  @ local2free_fusions_of_link_env link_env

(** graph context のマッチングを行う．*)

let has_link_of_atom (_, args) x = List.exists (( = ) x) args
let has_links_of_atom xs atom = List.exists (has_link_of_atom atom) xs
let has_link_of_atoms x = List.exists @@ List.exists @@ ( = ) x <. snd

let free_links_of_atoms atoms =
  (List.concat_map @@ List.filter is_free_link <. List.map snd) atoms

let links_of_atoms atoms = List.concat_map snd atoms

(** 全てのアトムをマッチさせる．ただし，必要に応じて fusion を補う atoms_lhs はまだマッチングしていない LHS のアトムのリスト．
    atoms_rest はマッチング対象のグラフにおいて，まだマッチングを試していないアトムのリスト *)
let match_ctxs ctxs_lhs target_graph =
  let rec match_ctxs theta target_graph = function
    | [] -> Some (theta, target_graph)
    | ctx :: rest_lhs_ctxs ->
        (* ターゲットのグラフのマッチングを試していないアトムのリストを引数にとる *)
        let free_links = snd ctx in
        (* リンクを辿って，連結グラフを取得する *)
        let rec traverse_links traversed_graph rest_graph traversing_links =
          let traversable_graph (* graph context の持つ自由リンクを持つアトムの集合 *), rest =
            List.partition (has_links_of_atom traversing_links) rest_graph
          in
          if traversable_graph = [] then
            if
              (* target graph の自由自由リンクは必ず template
                 の自由リンクでマッチする必要があるので含まれているかどうか確認する． *)
              ListExtra.set_minus
                (free_links_of_atoms traversed_graph)
                free_links
              = []
            then Some (traversed_graph, rest)
            else None
          else
            let new_links = links_of_atoms traversable_graph in
            let new_links = ListExtra.set_minus new_links traversing_links in
            traverse_links (traversable_graph @ traversed_graph) rest new_links
        in

        (let* matched_graph, rest_target_graph =
           traverse_links [] target_graph free_links
         in
         match_ctxs
           ((ctx, matched_graph) :: theta)
           rest_target_graph rest_lhs_ctxs)
        <|> fun _ -> match_ctxs theta target_graph rest_lhs_ctxs
  in
  match_ctxs [] target_graph ctxs_lhs
