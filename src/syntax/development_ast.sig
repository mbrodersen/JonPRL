signature DEVELOPMENT_AST =
sig
  type label

  structure Syntax : ABT_UTIL
    where type Operator.t = label OperatorType.operator

  structure Tactic : TACTIC
    where type label = label
    where type term = Syntax.t

  datatype command =
      PRINT of Syntax.Operator.t
    | EVAL of Syntax.t * int option

  datatype t =
      THEOREM of label * Syntax.t * Tactic.t
    | OPERATOR of label * Arity.t
    | TACTIC of label * Tactic.t
    | DEFINITION of Syntax.t * Syntax.t
    | NOTATION of Notation.t * Syntax.Operator.t
    | COMMAND of command
end
