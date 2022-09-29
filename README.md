# A reference interpreter of the Lambda GT language.

## About

Graphs are a generalized concept that encompasses more complex data structures than trees,
such as difference lists, doubly-linked lists, skip lists, and leaf-linked trees.
Normally, these structures are handled with destructive assignments to heaps,
as opposed to a purely functional programming style.

We proposed a new purely functional language, λGT, that handles graphs as immutable, first-class data structures with
a pattern matching mechanism based on Graph Transformation.

Since graphs can be more complex than trees and require non-trivial formalism,
the implementation of the language is also more complicated than ordinary functional languages.
λGT is even more advanced than the ordinary graph transformation systems.

We implemented a reference interpreter, a reference implementation of the language.
We believe this is usable for further investigation, including in the design of real languages based on λGT.
The interpreter is written in only 500 lines of OCaml code.

For the syntax and semantics, please see
[the paper[1]](http://jssst.or.jp/files/user/taikai/2022/papers/20-L.pdf).

- We have enabled logging.
  ```ocaml
  {Log} exp
  ```
  evaluates `exp`, prints the value, and result in the value.

We have also implemented a visualizing tool
that runs on a browser, which is available at
<https://sano-jin.github.io/lambda-gt-online/>.

## Getting Started

### Prerequisites

- [opam](https://opam.ocaml.org/)

### Installation

```bash
git clone https://github.com/sano-jin/lambda-gt-alpha.git
cd lambda-gt-alpha
opam install .
dune build
```

## Usage

```bash
./run example/dlist.lgt
```

which will result in `{>< (_Y, _X)}`.

See [/example](example) for more examples.

## Citation

1. ([pdf](http://jssst.or.jp/files/user/taikai/2022/papers/20-L.pdf),
   [slide](./materials/jssst2022.pdf))
   A functional language with graphs as first-class data,
   In Proc. The 39th JSSST Annual Conference, 2022
   (15pp. unreferred paper).
   - <details><summary>Abstract</summary><div>
     Graphs are a generalized concept that encompasses more complex data structures than trees,
     such as difference lists, doubly-linked lists, skip lists, and leaf-linked trees. Normally, these structures are handled
     with destructive assignments to heaps, as opposed to a purely functional programming style. We proposed
     a new purely functional language, λGT, that handles graphs as immutable, first-class data structures with
     a pattern matching mechanism based on Graph Transformation. Since graphs can be more complex than
     trees and require non-trivial formalism, the implementation of the language is also more complicated than
     ordinary functional languages. λGT is even more advanced than the ordinary graph transformation systems.
     We implemented a reference interpreter, a reference implementation of the language. We believe this
     is usable for further investigation, including in the design of real languages based on λGT. The interpreter
     is written in only 500 lines of OCaml code.
     </div></details>
2. ([arXiv](https://arxiv.org/abs/2209.05149),
   [slide](./materials/pro2022.pdf))
   Type checking data structures more complex than tree,
   to be appeared in Journal of Information Processing, 2022 (19pp. refferred).
   - <details><summary>Abstract</summary><div>
     Graphs are a generalized concept that encompasses more complex data structures than trees,
     such as difference lists, doubly-linked lists, skip lists, and leaf-linked trees.
     Normally, these structures are handled with destructive assignments to heaps,
     which is opposed to a purely functional programming style and makes verification difficult.
     We propose a new
     purely functional language, \\(\lambda_{GT}\\), that handles graphs as immutable,
     first-class data structures with a pattern matching mechanism
     based on Graph Transformation and developed a new type system, \\(F_{GT}\\), for the language.
     Our approach is in contrast with the analysis of pointer manipulation programs
     using separation logic, shape analysis, etc. in that
     (i) we do not consider destructive operations
     but pattern matchings over graphs provided by the new higher-level language that
     abstract pointers and heaps away and that
     (ii) we pursue what properties can be established automatically using a rather simple typing framework.
     </div></details>

## Contact

Please feel free to contact me (ask me any questions about this).

- [twitter@sano65747676](https://twitter.com/sano65747676)
- [homepage](https://www.ueda.info.waseda.ac.jp/~sano/)
