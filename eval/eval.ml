open Parse
open Util
include Syntax
include Preprocess
include Match_atoms
include Match_ctxs
include Match
include Pushout

let ctx_of (x, args) = (x, List.map (fun x -> FreeLink x) args)

let eval prerr =
  let rec eval depth theta =
    let depth = succ depth in
    let eval = eval depth in
    let prerr = prerr <. DebugPrint.indent depth in
    function
    | Graph graph -> fuse_fusions @@ synthesis prerr theta graph
    | App (e1, e2) as exp -> (
        prerr @@ "evaling exp = " ^ string_of_exp exp;
        let v1 = eval theta e1 in
        let v2 = eval theta e2 in
        match v1 with
        | [ (Lam (ctx, e, theta), _) ] ->
            let ctx = ctx_of ctx in
            let theta = (ctx, v2) :: theta in
            prerr @@ string_of_theta theta;
            prerr @@ "evaling exp = " ^ string_of_exp e ^ " with theta = "
            ^ string_of_theta theta;
            eval theta e
        | [ ((RecLam (ctx1, ctx2, e, theta), _) as rec_lam) ] ->
            let ctx1 = ctx_of ctx1 in
            let ctx2 = ctx_of ctx2 in
            let theta = (ctx1, [ rec_lam ]) :: (ctx2, v2) :: theta in
            prerr @@ string_of_theta theta;
            prerr @@ "evaling exp = " ^ string_of_exp e ^ " with theta = "
            ^ string_of_theta theta;
            eval theta e
        | _ -> failwith @@ "function expected but got " ^ string_of_graph v2)
    | Case (e1, template, e2, e3) as exp -> (
        prerr @@ "evaling exp = " ^ string_of_exp exp;
        let v1 = eval theta e1 in
        let _, template = alpha100 template in
        match match_atoms prerr template v1 with
        | None ->
            prerr @@ "match failed";
            eval theta e3
        | Some theta2 ->
            prerr @@ "match succeded with theta = " ^ string_of_theta theta2;
            let theta = theta2 @ theta in
            eval theta e2)
    | Let (ctx, e1, e2) as exp ->
        prerr @@ "evaling exp = " ^ string_of_exp exp;
        let v1 = eval theta e1 in
        let ctx = ctx_of ctx in
        let theta = (ctx, v1) :: theta in
        eval theta e2
    | LetRec (ctx1, ctx2, e1, e2) as exp ->
        prerr @@ "evaling exp = " ^ string_of_exp exp;
        let rec_lam = RecLam (ctx1, ctx2, e1, theta) in
        let ctx = ctx_of ctx1 in
        let theta = (ctx, [ (rec_lam, snd ctx) ]) :: theta in
        eval theta e2
  in
  eval 0 []
