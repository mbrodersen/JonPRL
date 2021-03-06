structure TacticEval :
sig
  exception RemainingSubgoals of Development.judgement Goal.goal list
  val eval : Development.world -> Tactic.t -> Refiner.tactic
end =
struct
  open Tactic
  open Refiner.Rules
  open GeneralRules

  structure PT = ProgressTacticals(Lcf) and T = Tacticals(Lcf) and TT = TransformationalTacticals(Lcf)
  exception RemainingSubgoals = T.RemainingSubgoals

  fun an a t = AnnotatedLcf.annotate (a, t)

  fun eval wld t =
    case t of
        LEMMA (theta, a) => an a (Lemma (wld, theta))
      | BHYP (hyp, a) => an a (BHypRules.BHyp hyp)
      | UNFOLD (thetas, a) => an a (Unfolds (wld, thetas))
      | CUSTOM_TACTIC (lbl, a) =>
        an a (Development.lookupTactic wld lbl)
      | WITNESS (t, a) => an a (Witness t)
      | HYPOTHESIS (i, a) => an a (Hypothesis i)
      | EQ_SUBST ({equality, domain, level}, a) =>
        an a (EqRules.Subst (equality, domain, level))
      | HYP_SUBST ({dir, index, domain, level}, a) =>
        an a (EqRules.HypSubst (dir, index, domain, level))
      | CEQ_SUBST ({equality, domain}, a) =>
        an a (CEqRules.Subst (equality, domain))
      | CHYP_SUBST ({dir, index, domain}, a) =>
        an a (CEqRules.HypSubst (dir, index, domain))
      | INTRO ({term, rule, freshVariable, level}, a) =>
        an a (RefinerUtil.Intro {term = term,
                                 rule = rule,
                                 invertible = false,
                                 freshVariable = freshVariable,
                                 level = level} wld)
      | ELIM ({target, term, names, level}, a) =>
        an a (RefinerUtil.Elim {target = target,
				term   = term,
				names  = names,
				level  = level} wld)
      | EQ_CD ({names, terms, level}, a) =>
        an a (RefinerUtil.EqCD {names = names,
                                invertible = false,
                                terms = terms,
                                level = level} wld)
      | EXT ({freshVariable, level}, a) =>
        an a (RefinerUtil.Ext {freshVariable = freshVariable, level = level})
      | CUM (l, a) => an a (UnivRules.Cum l)
      | AUTO (oi, a) => an a (RefinerUtil.Auto (wld, oi))
      | REDUCE (i, a) => an a (RefinerUtil.Reduce i)
      | ASSUMPTION a => an a Assumption
      | ASSERT ({assertion = t, name = name}, a) =>
        an a (Assert (t, name))
      | CUT_LEMMA (theta, name, a) => an a (RefinerUtil.CutLemma (wld, theta, name))
      | WF_LEMMA (theta, a) => an a (RefinerUtil.WfLemma (wld, theta))
      | UNHIDE (hyp, a) => an a (RefinerUtil.Unhide hyp)
      | POINTWISE_FUNCTIONALITY ({target,names,level}, a) => an a (PointwiseFunctionality (target, names, level))
      | SYMMETRY a => an a EqRules.Sym
      | CEQUAL_SYM a => an a CEqRules.Sym
      | CEQUAL_STEP a => an a CEqRules.Step
      | CEQUAL_STRUCT a => an a CEqRules.Struct
      | CEQUAL_APPROX a => an a CEqRules.Approx
      | APPROX_REFL a => an a ApproxRules.Refl
      | BOTTOM_DIVERGES (i, a) => an a (ApproxRules.BottomDiverges i)
      | ASSUME_HAS_VALUE ({name, level}, a) => an a (ApproxRules.AssumeHasValue (name, level))
      | EQ_EQ_BASE a => an a EqRules.EqBase
      | TRY tac => T.TRY (eval wld tac)
      | LIMIT tac => PT.LIMIT (eval wld tac)
      | PROGRESS tac => PT.PROGRESS (eval wld tac)
      | ORELSE (tacs, a) => an a (List.foldl T.ORELSE T.FAIL (map (eval wld) tacs))
      | THEN ts =>
        List.foldl
          (fn (APPLY x, rest) => T.THEN (rest, eval wld x)
            | (LIST xs, rest) => T.THENL (rest, map (eval wld) xs)
            | (FOCUS (i, x), rest) => T.THENF (rest, i, eval wld x))
          T.ID
          ts
      | PRUNE tac => TT.PRUNE (eval wld tac)
      | ID a => an a T.ID
      | FAIL a => an a T.FAIL
      | TRACE (msg, a) => an a (T.TRACE msg)
      | COMPLETE (t, a) => an a (T.COMPLETE (eval wld t))
      | MATCH branches =>
        RefinerUtil.Match
          (List.map
               (fn (CtxPattern {hyps, goal}, branch) =>
                   {hyps = hyps,
                    goal = goal,
                    branch = fn subst => eval wld (substBranch subst branch)})
               branches)
      | THIN (hyp, a) =>
          an a (Thin hyp)
      | FIAT a => an a Fiat
      | REDUCE_EQUAND (dir, a) => an a (RefinerUtil.ReduceEquand dir)
      | ON_CLASS (c, tac) => RefinerUtil.OnClass c (eval wld tac)
      | RESOURCE (r, a) =>
        an a (List.foldl T.THEN T.ID (Development.lookupResource wld r))
end
