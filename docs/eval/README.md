# Eval

Evaluator

- [syntax.ml](syntax.ml)

  - Syntax of atoms as an list.

- [preprocess.ml](preprocess.ml)

  - Transform an AST graph to a list of atoms. Alpha convert link names.

- [eval.ml](eval.ml)

  - The evaluator.

- [match.ml](match.ml)

  - Matches atoms and graph contexts and returns the obtained graph substitutions.

- [match_atoms.ml](match_atoms.ml)

  - Matches atoms and returns the link mappings and the rest graph.

- [postprocess.ml](postprocess.ml)

  - Transform the link names in the rest graphs and supply fusions
    according to the link mappings.

- [match_ctxs.ml](match.ml)

  - Matches graph contexts and returns the obtained graph substitutions.

- [pushout.ml](pushout.ml)

  - Substitute graph contexts with the given graph substitution (rewriting after matching).
