functor SmallStepUtil (S : SMALL_STEP) : SMALL_STEP_UTIL =
struct
  open S
  type petrol = int

  local
    val guzzle = Option.map (fn x => x - 1)
    fun expended (SOME x) = x <= 0
      | expended NONE = false

    fun go (M, gas) i =
      if expended gas then
        (M,i)
      else
        case step M of
             STEP M' => go (M', guzzle gas) (i + 1)
           | CANON => (M,i)
           | NEUTRAL => (M,i)
  in
    fun steps (M, gas) = go (M, gas) 0
  end
end

functor SmallStep (Syn : ABT_UTIL where type Operator.t = UniversalOperator.t)
        : SMALL_STEP where type syn = Syn.t =
struct
  type syn = Syn.t

  open Syn
  open Operator CttCalculus CttCalculusInj
  structure View = RestrictAbtView (structure Abt = Syn and Injection = CttCalculusInj)
  open View

  infix $ \ $$ \\ //

  fun theta $$ es =
    Syn.$$ (`> theta, es)

  exception Stuck of Syn.t
  datatype t = STEP of Syn.t | CANON | NEUTRAL

  fun stepSpreadBeta (P, E) =
    case project P of
        PAIR $ #[L, R] => (E // L) // R
      | _ => raise Stuck (SPREAD $$ #[P, E])

  fun stepApBeta (F, A) =
    case project F of
        LAM $ #[B] => B // A
      | _ => raise Stuck (AP $$ #[F, A])

  fun stepDecideBeta (S, L, R) =
    case project S of
        INL $ #[A] => L // A
      | INR $ #[B] => R // B
      | _ => raise Stuck (DECIDE $$ #[S, L, R])

  fun stepNatrecBeta (M, Z, xyS) =
    case project M of
         ZERO $ #[] => Z
       | SUCC $ #[N] => (xyS // N) // (NATREC $$ #[N, Z, xyS])
       | _ => raise Stuck (NATREC $$ #[M, Z, xyS])

  fun stepFix (F) = AP $$ #[F, FIX $$ #[F]]

  fun stepCbv (A, F) = F // A

  fun step' e =
    case project e of
        UNIV _ $ _ => CANON
      | VOID $ _ => CANON
      | UNIT $ _ => CANON
      | AX $ _ => CANON
      | PROD $ _ => CANON
      | PAIR $ _ => CANON
      | SPREAD $ #[P, E] => (
          case step P of
              STEP P' => STEP (SPREAD $$ #[P', E])
            | CANON => STEP (stepSpreadBeta (P, E))
            | NEUTRAL => NEUTRAL
      )
      | FUN $ _ => CANON
      | LAM $ _ => CANON
      | AP $ #[L, R] => (
          case step L of
              STEP L' => STEP (AP $$ #[L', R])
            | CANON => STEP (stepApBeta (L, R))
            | NEUTRAL => NEUTRAL
      )
      | FIX $ #[F] => (
	  case step F of
	      STEP F' => STEP (FIX $$ #[F'])
	    | CANON => STEP (stepFix F)
	    | NEUTRAL => NEUTRAL
      )
      | CBV $ #[A, F] => (
          case step A of
              STEP A' => STEP (CBV $$ #[A', F])
            | CANON => STEP (stepCbv (A, F))
            | NEUTRAL => NEUTRAL
      )
      | ISECT $ _ => CANON
      | EQ $ _ => CANON
      | MEM $ _ => CANON
      | SUBSET $ _ => CANON
      | PLUS $ _ => CANON
      | INL $ _ => CANON
      | INR $ _ => CANON
      | NAT $ _ => CANON
      | ZERO $ _ => CANON
      | SUCC $ _ => CANON
      | IMAGE $ _ => CANON
      | DECIDE $ #[S, L, R] =>
          (case step S of
              STEP S' => STEP (DECIDE $$ #[S', L, R])
            | CANON => STEP (stepDecideBeta (S, L, R))
            | NEUTRAL => NEUTRAL)
      | NATREC $ #[M, Z, xyS] =>
          (case step M of
                STEP M' => STEP (NATREC $$ #[M', Z, xyS])
              | CANON => STEP (stepNatrecBeta (M, Z, xyS))
              | NEUTRAL => NEUTRAL)
      | SO_APPLY $ #[L, R] =>
          (* This can't come up but I don't think it's wrong
           * Leaving this in here so it's an actual semantics
           * for the core type theory: not just what users
           * can say with the syntax we give.
           *)
          (case project L of
               x \ L => STEP (subst R x L)
             | _ =>
             (case step L of
                 CANON => raise Stuck (SO_APPLY $$ #[L, R])
               | STEP L' => STEP (SO_APPLY $$ #[L', R])
               | NEUTRAL => NEUTRAL))
      | ` _ => NEUTRAL (* Cannot step an open term *)
      | x \ e => (
        case step e of
            STEP e' => STEP (x \\ e')
          | NEUTRAL => NEUTRAL
          | CANON => NEUTRAL
      )
      | _ => raise Stuck e

    and step e =
      step' e
      handle CttCalculusInj.Mismatch => NEUTRAL
end

structure Semantics = SmallStep(Syntax)
