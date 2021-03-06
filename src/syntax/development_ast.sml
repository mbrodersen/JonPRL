structure DevelopmentAst : DEVELOPMENT_AST =
struct
  type label = string

  structure Syntax = Syntax
  structure Tactic  = Tactic

  datatype command =
      PRINT of Syntax.Operator.t
    | EVAL of Syntax.t * int option
    | SEARCH of Syntax.Operator.t
    | ADD_RESOURCE of Resource.t * Tactic.t
    | NEW_RESOURCE of Resource.t

  datatype t =
      THEOREM of label * Syntax.Operator.t * Syntax.t * Tactic.t
    | OPERATOR of label * Syntax.Operator.t
    | TACTIC of label * Tactic.t
    | DEFINITION of Syntax.t * Syntax.t
    | NOTATION of Notation.t * Syntax.Operator.t
    | COMMAND of command
end
