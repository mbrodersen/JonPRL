signature LEVEL =
sig
  eqtype t

  exception LevelError

  (* A pretty printed version of a level where if
   * [toString l = s] then [toString (succ l) = s ^ "'"].
   *)
  val toString : t -> string

  (* The lowest level. *)
  val base : t

  (* Increase a level by one, it is always the case
   * that [pred o succ = id].
   *)
  val succ : t -> t

  (* Decrease a level by one. This raises a LevelError
   * if supplied [base] since [base] is the lowest level
   *)
  val pred : t -> t
  val max : t * t -> t

  type constraint
  type substitution

  (* We can construct a substitution on levels from a level
   * l by yanking each level up l times. so [yank base] is an
   * identity substitution and [yank (succ base)] will raise every
   * level up by one.
   *)
  val yank : t -> substitution

  (* Assert that second level may be transformed
   * into the first. If the levels are the same then
   * this is always true.
   *
   * This isn't commutative!
   *)
  val unify : t * t -> constraint

  (* This may raise a LevelError. Given a bunch of
   * constraints, transform them into a substitution
   * that if the list of constraints contained one
   * generated by [unify (l1, l2)], then with the resulting
   * substitution [subst s l1 = l2]. However, [subst s l2 = l1]
   * may *not* hold.
   *
   * This is possible if and only if each constraint states we
   * must shift levels in the same way. For example the constraint
   * formed by [unify (base, succ base)] specifies we shift a
   * level up by one. If [resolve] is to succeed when given
   * such a constraint then all the other constraints must be
   * of the form [unify (x, succ x)].
   *
   * For this reason it isn't the case [unify] that commutes.
   *)
  val resolve : constraint list -> substitution

  val subst : substitution -> t -> t

  val assertLt : t * t -> unit
  val assertEq : t * t -> unit

  val parse : t CharParser.charParser
end
