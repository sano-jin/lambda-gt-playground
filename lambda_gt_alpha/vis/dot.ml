open Util
open Eval

let links_of_atoms atoms = List.concat_map snd @@ atoms

(** local link と free link を分ける *)
let unzip_links =
  List.partition_map @@ function LocalLink l -> Left l | FreeLink f -> Right f

(** 可視化のために，アトムリストを dot に変換する *)
let dot_of_atoms (atoms : graph) =
  (* リンク名からポートの集合への写像を作る． *)
  let link_map =
    let helper ((atom_i, _), args) =
      List.mapi (fun arg_i link -> (link, (atom_i, arg_i))) args
    in
    List.concat_map helper atoms
  in
  let link_dict = ListExtra.gather link_map in

  (* 端点が二つしか無いリンク (normal link) と，そうでは無いものに分離する．*)
  let normal_links, link_dict =
    let helper = function
      | LocalLink x, [ p1; p2 ] -> Either.Left (x, (p1, p2))
      | mapping -> Either.Right mapping
    in
    List.partition_map helper link_dict
  in

  (* normal link を dot の文字列に変換する． *)
  let normal_links_str =
    let helper (_, ((i1, _), (i2, _))) =
      Printf.sprintf "\tAtom_%d -> Atom_%d;" i1 i2
    in
    String.concat "\n" @@ List.map helper normal_links
  in

  let stage = Util.unique () in
  let links = List.sort_uniq compare @@ links_of_atoms atoms in
  let locallinks, freelinks = unzip_links @@ links in

  let local_link_setting locallink =
    if List.mem_assoc (LocalLink locallink) link_dict then
      Some
        ("\tL_" ^ string_of_int stage ^ "_" ^ string_of_int locallink
       ^ "[label=\"\", shape=point];")
    else None
  in
  let local_link_settings =
    String.concat "\n" @@ List.filter_map local_link_setting locallinks
  in

  let free_link_setting freelink =
    "\tF_" ^ freelink ^ "[label=\"" ^ freelink ^ "\", shape=plain];"
  in
  let free_link_settings =
    String.concat "\n" @@ List.map free_link_setting freelinks
  in

  let atom_setting _atom_id (((i, atom_name), _) : Eval.atom) =
    let v = string_of_atom_name atom_name in
    "\tAtom_" ^ string_of_int i ^ "[label=\"" ^ v ^ "\"];"
  in
  let atom_settings = String.concat "\n" @@ List.mapi atom_setting atoms in

  let string_of_link = function
    | LocalLink i -> "L_" ^ string_of_int stage ^ "_" ^ string_of_int i
    | FreeLink f -> "F_" ^ f
  in

  let atom_links _atom_id ((i, _), args) =
    let helper link =
      if List.mem_assoc link link_dict then
        Some ("\tAtom_" ^ string_of_int i ^ " -> " ^ string_of_link link ^ ";")
      else None
    in
    List.filter_map helper args
  in

  let atoms_links =
    String.concat "\n" @@ List.concat @@ List.mapi atom_links atoms
  in

  let dot =
    [
      "digraph G {";
      "\tgraph [layout = LAYOUT];";
      "\tedge [arrowhead = none];";
      atom_settings;
      local_link_settings;
      free_link_settings;
      normal_links_str;
      atoms_links;
      "}";
    ]
  in
  String.concat "\n\n" dot
