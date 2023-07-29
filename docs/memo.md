---
title: Memo
---

# Repairing λGT

グラフと型（生成文法）を入力にとり，
preprocessing したグラフと，
型が生成するグラフの集合を出力する．

### Port Graph

グラフのノードは以下の 2 種類ある．

- アトム: Port を持つ頂点
  - それぞれの port からは hyper でない edge が出て，
    port または unnamed hyperlink に接続される．
- Hyperlink: Port を持たない頂点．普通のグラフ理論の頂点．
  - 任意本の edge が出て，
    port または hyperlink に接続される．

同じポートや hyperlink から多重辺が出ることは想定していない．
あくまでポートや hyperlink から出る辺は一本で，他のポートに直接繋がるか，
ハイパーリンクに接続されるかのどちらか．

# todo

Fusion の扱い方を変えて，
free link 周りのグラフのマッチングを再実装する．

# このリポジトリについて

このリポジトリは，
visualiser に渡すために JSON へ変換するコードと，
javascript として解釈実行するためのコードを含んでいる．

TODO: それぞれの使い方を整理してまとめる．

ディレクトリ構成

- bin: インタプリタを起動する，entry point.
- docs: ドキュメント．
- dune-project
- eval: evaluator
- example: 例題．
- js: visualiser の backend としてインタプリタを用いるためのコード．
- lib: 使っていない．全部この下に配置し直すべきかも．
- parser: parser.
- run: インタプリタを実行する shell script.
- scripts: 使い捨ての (shell) script などを置いておくためのディレクトリ．
- test: テストコード．ounit とかを使うようにするべきかも．
- util: 共用関数などを置いておくディレクトリ．base で置き換えられるかも．
- vis: graph を visualiser が扱いやすい形に変換して json で出力するコード．
