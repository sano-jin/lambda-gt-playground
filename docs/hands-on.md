# Hands on tutorial on the Lambda GT interpreter

インタプリタを拡張する．

- 算術計算ができるようにする．

必要なこと

1. parser の拡張
   1. parser/syntax.ml, eval/syntax.ml を拡張して，構文に数値と二項演算（加算，減算，etc）を追加
   2. 数値や二項演算を parse できるようにする．
2. 評価器の拡張
   1. eval/eval.ml を拡張する．
