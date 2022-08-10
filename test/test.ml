prerr_endline @@ "testing parser";
Test_parse.test ();
prerr_newline ();

prerr_endline @@ "testing preprocessor";
Test_preprocess.test ();
prerr_newline ();

prerr_endline @@ "testing find_atoms";
Test_matching.test ();
prerr_newline ();

prerr_endline @@ "testing match_atoms";
Test_match_atoms.test ();
prerr_newline ();

prerr_endline @@ "testing match_and_synthesis";
Test_synthesis.test ();
prerr_newline ();

prerr_endline @@ "testing eval";
Test_eval.test ();
prerr_newline ()
