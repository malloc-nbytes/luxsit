

(* let rec parse_bin_expr (p : parser_t) : parser_t * (node_bin_expr_t option) = *)
(*   let p, lhs = parse_expr p in *)
(*   match lhs with *)
(*   | None -> p, None *)
(*   | Some lhs_expr -> *)
(*      match peek p with *)
(*      | Some t when t.tokentype == Token.Plus -> *)
(*         let p, _ = expect p Token.Plus in *)
(*         let p, rhs = parse_expr p in *)
(*         (match rhs with *)
(*          | Some rhs_expr -> p, Some (NodeBinExprAdd { lhs = lhs_expr; rhs = rhs_expr }) *)
(*          | None -> *)
(*             let _ = err "Expected expression" in *)
(*             failwith "parser error") *)
(*      | Some t when t.tokentype == Token.Mult -> failwith "todo: multiplication" *)
(*      | _ -> failwith "peek failed" *)

(* 1 + 2) *)
