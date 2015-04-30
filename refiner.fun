signature REFINER_TYPES =
sig
  type goal
  type evidence

  type validation = evidence list -> evidence
  type tactic = goal -> (goal list * validation)
end

signature REFINER_TACTICS =
sig
  type tactic
  val THEN : tactic * tactic -> tactic
  val ORELSE : tactic * tactic -> tactic
end

functor RefinerTactics (R : REFINER_TYPES) :
sig
  include REFINER_TACTICS where type tactic = R.tactic
end =
struct
  type tactic = R.tactic

  fun THEN (tac1, tac2) (g : R.goal) =
    let
      val (subgoals1, validation1) = tac1 g
      val (subgoals2, validations2) = ListPair.unzip (List.map tac2 subgoals1)
    in
      (List.foldl (op @) [] subgoals2,
       fn Ds =>
         let
           val lengths = List.map List.length subgoals2
           val derivations = ListUtil.multisplit lengths Ds
         in
           validation1 (ListPair.map (fn (v, d) => v d) (validations2, derivations))
         end)
    end

  fun ORELSE (tac1, tac2) : R.tactic = fn g =>
    tac1 g handle _ => tac2 g
end

functor Refiner
  (structure Syn : ABTUTIL where Operator = Lang and Variable = Variable
   val print_mode : PrintMode.t) :>
sig

  structure Evidence : ABTUTIL
  exception MalformedEvidence of Evidence.t
  val extract : Evidence.t -> Syn.t

  type ctx = Syn.t Context.context
  include REFINER_TYPES
    where type goal = ctx * Syn.t
    and type evidence = Evidence.t

  structure CoreTactics : REFINER_TACTICS where type tactic = tactic
  structure InferenceRules :
  sig
    val UnitIntro : tactic
    val ProdIntro : tactic
    val ImpIntro : Context.name -> tactic
    val AxIntro : tactic
    val PairIntro : tactic
    val LamIntro : tactic
    val MemIntro : tactic
    val Witness : Syn.t -> tactic
    val Assumption : tactic
    val Hypothesis : Context.name -> tactic
    val HypMem : tactic
  end

  structure DerivedTactics :
  sig
    val CanMemAuto : tactic
    val MemAuto : tactic
  end
end =
struct
  type ctx = Syn.t Context.context
  type goal = ctx * Syn.t

  structure EOp =
  struct
    datatype t
      = UNIT_INTRO
      | PROD_INTRO
      | IMP_INTRO
      | AX_INTRO
      | PAIR_INTRO
      | LAM_INTRO
      | MEM_INTRO
      | WITNESS of Syn.t
      | HYP_MEM

    fun eq UNIT_INTRO UNIT_INTRO = true
      | eq PROD_INTRO PROD_INTRO = true
      | eq IMP_INTRO IMP_INTRO = true
      | eq AX_INTRO AX_INTRO = true
      | eq PAIR_INTRO PAIR_INTRO = true
      | eq LAM_INTRO LAM_INTRO = true
      | eq MEM_INTRO MEM_INTRO = true
      | eq (WITNESS m) (WITNESS n) = Syn.eq (m, n)
      | eq HYP_MEM HYP_MEM = true
      | eq _ _ = false

    fun arity UNIT_INTRO = #[]
      | arity PROD_INTRO = #[0,0]
      | arity IMP_INTRO = #[1]
      | arity AX_INTRO = #[]
      | arity PAIR_INTRO = #[0,0]
      | arity LAM_INTRO = #[1]
      | arity MEM_INTRO = #[0]
      | arity (WITNESS _) = #[0]
      | arity HYP_MEM = #[0]

    fun to_string UNIT_INTRO = "unit-I"
      | to_string PROD_INTRO = "prod-I"
      | to_string IMP_INTRO = "imp-I"
      | to_string AX_INTRO = "ax-I"
      | to_string PAIR_INTRO = "pair-I"
      | to_string LAM_INTRO = "lam-I"
      | to_string MEM_INTRO = "∈*-I"
      | to_string (WITNESS m) = "witness{" ^ Syn.to_string print_mode m ^ "}"
      | to_string HYP_MEM = "hyp-∈"
  end

  structure Evidence =
    AbtUtil
      (Abt
        (structure Operator = EOp
         and Variable = Syn.Variable))

  structure E = Evidence

  structure RefinerTypes : REFINER_TYPES =
  struct
    type goal = goal
    type evidence = E.t
    type validation = evidence list -> evidence
    type tactic = goal -> (goal list * validation)
  end

  open RefinerTypes

  exception MalformedEvidence of E.t

  local
    open E EOp Lang
    infix $ \
  in
    fun extract (ev : E.t) : Syn.t =
      case out ev of
           UNIT_INTRO $ #[] => Syn.$$ (AX, #[])
         | PROD_INTRO $ #[D,E] => Syn.$$ (PAIR, #[extract D, extract E])
         | IMP_INTRO $ #[xE] => Syn.$$ (LAM, #[extract xE])
         | AX_INTRO $ _ => Syn.$$ (AX, #[])
         | PAIR_INTRO $ _ => Syn.$$ (AX, #[])
         | LAM_INTRO $ _ => Syn.$$ (AX, #[])
         | MEM_INTRO $ _ => Syn.$$ (AX, #[])
         | WITNESS m $ _ => m
         | ` x => Syn.`` x
         | x \ E => Syn.\\ (x, extract E)
         | _ => raise MalformedEvidence ev
  end


  open Lang
  open Syn EOp
  infix $
  infix $$

  val %$$ = Evidence.$$
  infix %$$

  val %\\ = Evidence.\\
  infix %\\

  val %`` = Evidence.``

  structure Whnf = Whnf(Syn)

  structure CoreTactics = RefinerTactics(RefinerTypes)

  structure InferenceRules =
  struct
    val UnitIntro : tactic = fn (G, P) =>
      case out P of
           UNIT $ _ => ([], fn args => UNIT_INTRO %$$ Vector.fromList args)
         | _ => raise Fail "UnitIntro"

    val AxIntro : tactic = fn (G, P) =>
      case out P of
           CAN_MEM $ #[ax, unit] =>
             (case (out ax, out unit) of
                  (AX $ #[], UNIT $ #[]) =>
                    ([], fn args => AX_INTRO %$$ Vector.fromList args)
                | _ => raise Fail "AxIntro")
         | _ => raise Fail "AxIntro"

    val PairIntro : tactic = fn (G, P) =>
      case out P of
           CAN_MEM $ #[pair, prod] =>
             (case (out pair, out prod) of
                   (PAIR $ #[M,N], PROD $ #[A,B]) =>
                     ([(G, MEM $$ #[M,A]), (G, MEM $$ #[N,B])],
                      fn args => PAIR_INTRO %$$ Vector.fromList args)
                 | _ => raise Fail "PairIntro")
         | _ => raise Fail "PairIntro"

    val LamIntro : tactic = fn (G, P) =>
      case out P of
           CAN_MEM $ #[lam, imp] =>
             (case (out lam, out imp) of
                   (LAM $ #[zE], IMP $ #[A,B]) =>
                   let
                     val (z, E) = unbind zE
                   in
                     ([(Context.insert G z A, MEM $$ #[E, B])],
                      fn [D] => LAM_INTRO %$$ #[z %\\ D]
                         | _ => raise Fail "ImpIntro")
                   end
                 | _ => raise Fail "LamIntro")
         | _ => raise Fail "LamIntro"

    val MemIntro : tactic = fn (G, P) =>
      case out P of
           MEM $ #[M, A] =>
           let
             val M0 = Whnf.whnf M
             val A0 = Whnf.whnf A
           in
             ([(G, CAN_MEM $$ #[M0, A0])], fn args => MEM_INTRO %$$ Vector.fromList args)
           end
         | _ => raise Fail "MemIntro"

    fun Witness M : tactic = fn (G, P) =>
      ([(G, MEM $$ #[M, P])],
       fn [D] => WITNESS M %$$ #[D]
         | _ => raise Fail "Witness")

    val HypMem : tactic = fn (G, P) =>
      case out P of
           MEM $ #[M,A] =>
           (case out M of
                 ` x =>
                   (case Context.lookup G x of
                         SOME Q =>
                           if Syn.eq (A, Q)
                           then ([], fn _ => HYP_MEM %$$ #[%`` x])
                           else raise Fail "HypMem"
                       | NONE => raise Fail "HypMem")
               | _ => raise Fail "HypMem")
         | _ => raise Fail "HypMem"

    val ProdIntro : tactic = fn (G, P) =>
      case out P of
           PROD $ #[P1, P2] =>
             ([(G, P1), (G, P2)],
              fn args => PROD_INTRO %$$ Vector.fromList args)
         | _ => raise Fail "ProdIntro"

    fun ImpIntro x : tactic = fn (G, P) =>
      case out P of
           IMP $ #[P1, P2] =>
             ([(Context.insert G x P1, P2)],
              fn [D] => IMP_INTRO %$$ #[x %\\ D]
                | _ => raise Fail "ImpIntro")
         | _ => raise Fail "ImpIntro"

    fun Hypothesis x : tactic = fn (G, P) =>
      (case Context.lookup G x of
            SOME P' =>
              if Syn.eq (P, P')
              then ([], fn _ => %`` x)
              else raise Fail "Hypothesis does not match"
          | NONE => raise Fail "No such hypothesis")

    val Assumption : tactic = fn (G, P) =>
      (case Context.search G (fn x => Syn.eq (P, x)) of
           SOME (x, _) => ([], fn _ => %`` x)
         | NONE => raise Fail "No matching assumption")
  end


  structure DerivedTactics =
  struct
    open CoreTactics InferenceRules
    infix ORELSE THEN

    val CanMemAuto = AxIntro ORELSE PairIntro ORELSE LamIntro
    val MemAuto = (MemIntro THEN CanMemAuto) ORELSE HypMem
  end
end

structure Test =
struct
  val print_mode = PrintMode.User

  structure Syn = AbtUtil(Abt(structure Operator = Lang and Variable = Variable))
  structure Refiner = Refiner(structure Syn = Syn val print_mode = print_mode)
  structure Ctx = Context
  open Lang Syn Refiner
  open CoreTactics DerivedTactics InferenceRules
  infix $$ \\ THEN ORELSE

  exception RemainingSubgoals of goal list


  fun check P (tac : tactic) =
  let
    val (subgoals, validate) = tac (Context.empty, P)
    val result = if null subgoals then validate [] else raise RemainingSubgoals subgoals
  in
    (print ("Theorem: " ^ Syn.to_string print_mode P ^ "\n");
     print ("Evidence: " ^ Evidence.to_string print_mode result ^ "\n");
     print ("Extract: " ^ Syn.to_string print_mode (extract result) ^ "\n\n"))
  end

  val ax = AX $$ #[]
  val unit = UNIT $$ #[]

  fun & (a, b) = PROD $$ #[a,b]
  infix &

  fun pair m n = PAIR $$ #[m,n]
  fun fst m = FST $$ #[m]
  fun lam e =
    let
      val x = Variable.new ()
    in
      LAM $$ #[x \\ e x]
    end

  fun ~> (a, b) = IMP $$ #[a,b]
  infix ~>

  fun can_mem (m, a) = CAN_MEM $$ #[m,a]
  infix can_mem

  fun mem (m, a) = MEM $$ #[m,a]
  infix mem

  val _ =
      check
        (unit & (unit & unit))
        (ProdIntro THEN
          (UnitIntro ORELSE
            ProdIntro THEN
              UnitIntro))

  val _ =
     check
       (unit ~> (unit & unit))
       (ImpIntro (Variable.new()) THEN
         ProdIntro THEN
           Assumption)

  val _ =
      check
        (fst (pair ax ax) mem unit)
        (MemAuto THEN MemAuto)

  val _ =
      check
        (lam (fn x => `` x) mem (unit ~> unit))
        (MemAuto THEN MemAuto)

  val _ =
      check
        (unit ~> (unit & unit))
        (Witness (lam (fn x => pair (`` x) (`` x))) THEN
          MemAuto THEN
            MemAuto THEN
              MemAuto)

end
