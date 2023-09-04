type var_t =
  { stackloc : int }

type gen_t =
  { output : string;
    stackptr : int;
    vars : (string, var_t) Hashtbl.t }

let err (msg : string) : unit =
  Printf.printf "(ERR) %s\n" msg

(* Header and procedures to print. *)
(* let asm_header =
  "section .text\n" ^
  "dump:\n" ^
  "    mov     r8, -3689348814741910323\n" ^
  "    sub     rsp, 40\n" ^
  "    mov     BYTE [rsp+31], 10\n" ^
  "    lea     rcx, [rsp+30]\n" ^
  ".L2:\n" ^
  "    mov     rax, rdi\n" ^
  "    mul     r8\n" ^
  "    mov     rax, rdi\n" ^
  "    shr     rdx, 3\n" ^
  "    lea     rsi, [rdx+rdx*4]\n" ^
  "    add     rsi, rsi\n" ^
  "    sub     rax, rsi\n" ^
  "    mov     rsi, rcx\n" ^
  "    sub     rcx, 1\n" ^
  "    add     eax, 48\n" ^
  "    mov     BYTE [rcx+1], al\n" ^
  "    mov     rax, rdi\n" ^
  "    mov     rdi, rdx\n" ^
  "    cmp     rax, 9\n" ^
  "    ja      .L2\n" ^
  "    lea     rdx, [rsp+32]\n" ^
  "    mov     edi, 1\n" ^
  "    sub     rdx, rsi\n" ^
  "    mov     rax, 1\n" ^
  "    syscall\n" ^
  "    add     rsp, 40\n" ^
  "    ret\n" ^
  "global _start\n" ^
  "_start:\n" *)

let var_exists (gen : gen_t) (name : string) : bool =
  Hashtbl.mem gen.vars name

let get_var (gen : gen_t) (name : string) : var_t option =
  if var_exists gen name then
    let var = Hashtbl.find gen.vars name in
    Some var
  else
    None

let insert_var (gen : gen_t) (name : string) : unit =
  let v = { stackloc = gen.stackptr } in
  Hashtbl.add gen.vars name v

let push (gen : gen_t) (reg : string) : gen_t =
  let output = gen.output in
  let output = output ^ "    push " ^ reg ^ "\n" in
  { gen with output = output; stackptr = gen.stackptr + 1 }

let pop (gen : gen_t) (reg : string) : gen_t =
  let output = gen.output in
  let output = output ^ "    pop " ^ reg ^ "\n" in
  { gen with output = output; stackptr = gen.stackptr - 1 }

(* let gen_term (gen : gen_t) (term : Parser.node_term_t) : gen_t =
  match term with
  | Parser.NodeTermIntlit term_intlit ->
     let output = gen.output in
     let output = output ^ "    mov rax, " ^ term_intlit.intlit.data ^ "\n" in
     push ({ gen with output = output }) "rax"
  | Parser.NodeTermId term_id ->
     let var : var_t =
       match get_var gen term_id.id.data with
       | Some var -> var
       | None ->
          let _ = err ("undeclared ID " ^ term_id.id.data ^ "\n") in
          failwith "gen error" in

     let offset = string_of_int ((gen.stackptr - var.stackloc - 1) * 8) in
     let output = gen.output ^ "    mov rax, QWORD [rsp + " ^ offset ^ "]\n" in
     push { gen with output = output } "rax"
  | _ -> 
      let _ = err "gen_term: not implemented" in
      failwith "gen error" *)

(* let rec gen_expr (gen : gen_t) (expr : Parser.node_expr_t) : gen_t =
  match expr with
  | Parser.NodeTerm term -> gen_term gen term
  | Parser.NodeBinaryExpr bin_expr ->
     (match bin_expr with
      | Parser.NodeBinExprAdd add_expr ->
         let gen = gen_expr gen add_expr.lhs in (* gets put on top of stack *)
         let gen = gen_expr gen add_expr.rhs in (* gets put on top of stack *)
         let gen = pop gen "rdi" in (* pop the evaluated expr *)
         let gen = pop gen "rax" in (* pop the evaluated expr *)
         let output = gen.output ^ "    add rax, rdi\n" in
         push ({ gen with output = output }) "rax"
      | NodeBinExprMult mult_expr ->
         let gen = gen_expr gen mult_expr.lhs in
         let gen = gen_expr gen mult_expr.rhs in
         let gen = pop gen "rdi" in
         let gen = pop gen "rax" in
         let output = gen.output ^ "    imul rax, rdi\n" in
         push ({ gen with output = output }) "rax") *)

let generate_stmt (gen : gen_t) (stmt : Parser.stmt_t) : gen_t =
  match stmt with
  | Parser.Exit stmt_exit ->
     let gen = gen_expr gen stmt_exit in
     let output = gen.output in
     let output = output ^ "    mov rax, 60\n" in
     let gen = pop ({ gen with output = output }) "rdi" in
     { gen with output = gen.output ^ "    syscall\n" }
  | Parser.Let stmt_let ->
     if var_exists gen stmt_let.id.data then
       let _ = err ("ID " ^ stmt_let.id.data ^ " is already defined") in
       failwith "gen error"
     else
       let _ = insert_var gen stmt_let.id.data in
       gen_expr gen stmt_let.expr
  | Parser.Println stmt_print ->
     let gen = gen_expr gen stmt_print in
     let gen = pop gen "rdi" in
     let output = gen.output ^ "    call dump\n" in
     { gen with output = output }
  | _ ->
    let _ = err "gen_stmt: not implemented" in
    failwith "gen error"

let generate_program (program : Parser.program_t) : string =
  let rec iter_prog_stmts (gen : gen_t) (lst : Parser.stmt_t list) : gen_t =
    match lst with
    | [] -> gen
    | hd :: tl -> iter_prog_stmts (generate_stmt gen hd) tl
  in

  let asm_header = "" in (* temp *)

  let gen = { output = asm_header;
              stackptr = 0;
              vars = Hashtbl.create 20 } in

  let gen = iter_prog_stmts gen program.body in

  (* Obligatory exit for when the programmer forgets (>д<) *)
  let output = gen.output in
  let output = output ^ "    mov rax, 60\n" in
  let output = output ^ "    mov rdi, 0\n" in
  let output = output ^ "    syscall" in

  output
