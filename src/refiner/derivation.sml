structure Derivation =
struct
  datatype t =
      UNIV_EQ of Level.t | CUM
    | EQ_EQ | EQ_EQ_BASE | EQ_MEMBER_EQ
    | PROD_EQ | PROD_INTRO | IND_PROD_INTRO | PROD_ELIM | PAIR_EQ | SPREAD_EQ
    | FUN_EQ | FUN_INTRO | FUN_ELIM | LAM_EQ | AP_EQ | FUN_EXT
    | ISECT_EQ | ISECT_INTRO | ISECT_ELIM | ISECT_MEMBER_EQ | ISECT_MEMBER_CASE_EQ
    | WITNESS | HYP_EQ | EQ_SUBST | EQ_SYM
    | SUBSET_EQ | SUBSET_INTRO | IND_SUBSET_INTRO | SUBSET_ELIM | SUBSET_MEMBER_EQ
    | PLUS_EQ | PLUS_INTROL | PLUS_INTROR | PLUS_ELIM | INL_EQ | INR_EQ | DECIDE_EQ

    | NAT_EQ | NAT_ELIM | ZERO_EQ | SUCC_EQ | NATREC_EQ

    | FIAT
    | CEQUAL_EQ | CEQUAL_MEMBER_EQ | CEQUAL_SYM | CEQUAL_STEP
    | CEQUAL_SUBST | CEQUAL_STRUCT of Arity.t
    | CEQUAL_APPROX | CEQUAL_ELIM
    | APPROX_EQ | APPROX_MEMBER_EQ | APPROX_EXT_EQ | APPROX_REFL | APPROX_ELIM
    | BOTTOM_DIVERGES | ASSUME_HAS_VALUE
    | BASE_EQ | BASE_INTRO | BASE_ELIM_EQ | BASE_MEMBER_EQ of int
    | ATOM_SUBTYPE_BASE

    | IMAGE_EQ | IMAGE_MEM_EQ | IMAGE_ELIM | IMAGE_EQ_IND
    | PER_EQ | PER_MEM_EQ | PER_ELIM

    | UNHIDE
    | POINTWISE_FUNCTIONALITY

    | ATOM_EQ | TOKEN_EQ | MATCH_TOKEN_EQ of string vector | TEST_ATOM_EQ
    | TEST_ATOM_REDUCE_LEFT | TEST_ATOM_REDUCE_RIGHT


    | CONTAINER_EQ | CONTAINER_MEM_EQ | CONTAINER_ELIM
    | EXTENSION_EQ | EXTEND_EQ | EXTENSION_ELIM
    | NEIGH_EQ | NEIGH_NIL_EQ | NEIGH_SNOC_EQ | NEIGH_ELIM | NEIGH_IND_EQ

    | WTREE_EQ | WTREE_MEM_EQ | WTREE_REC_EQ | WTREE_INTRO | WTREE_ELIM

    | LEMMA of {label : Label.t}
    | ASSERT

  val eq : t * t -> bool = op=

  fun arity theta =
    case theta of
         UNIV_EQ _ => #[]
       | CUM => #[0]
       | EQ_EQ => #[0,0,0]
       | EQ_EQ_BASE => #[0,0,0]
       | EQ_MEMBER_EQ => #[0]
       | CEQUAL_EQ => #[0, 0]
       | CEQUAL_MEMBER_EQ => #[0]
       | CEQUAL_SYM => #[0]
       | CEQUAL_STEP => #[0]
       | CEQUAL_SUBST => #[0, 0]
       | CEQUAL_STRUCT arity => arity
       | CEQUAL_APPROX => #[0, 0]
       | CEQUAL_ELIM => #[0,2]
       | APPROX_EQ => #[0,0]
       | APPROX_MEMBER_EQ => #[0]
       | APPROX_EXT_EQ => #[0]
       | APPROX_REFL => #[]
       | APPROX_ELIM => #[0,0]
       | BOTTOM_DIVERGES => #[0]
       | ASSUME_HAS_VALUE => #[1,0]

       | BASE_EQ => #[]
       | BASE_INTRO => #[]
       | BASE_ELIM_EQ => #[1]
       | BASE_MEMBER_EQ n => Vector.tabulate (n + 1, fn _ => 0)
       | ATOM_SUBTYPE_BASE => #[0]

       | IMAGE_EQ => #[0,0]
       | IMAGE_MEM_EQ => #[0,0]
       | IMAGE_ELIM => #[1]
       | IMAGE_EQ_IND => #[0,0,0,4]

       | PER_EQ => #[2,2,3,3,3,5]
       | PER_MEM_EQ => #[0,0,0,0]
       | PER_ELIM => #[1,0]

       | UNHIDE => #[0]
       | POINTWISE_FUNCTIONALITY => #[2,3]

       | ATOM_EQ => #[]
       | TOKEN_EQ => #[]
       | MATCH_TOKEN_EQ toks =>
           Vector.tabulate
            (Vector.length toks + 2,
             fn i => if i = 0 then 0 else 2)
       | TEST_ATOM_EQ => #[0,0,1,1]
       | TEST_ATOM_REDUCE_LEFT => #[0,0]
       | TEST_ATOM_REDUCE_RIGHT => #[0,0]

       | PROD_EQ => #[0,1]
       | PROD_INTRO => #[0,0,0,1]
       | IND_PROD_INTRO => #[0,0]
       | PROD_ELIM => #[0,2]
       | PAIR_EQ => #[0,0,1]
       | SPREAD_EQ => #[0,3]

       | PLUS_EQ => #[0, 0]
       | PLUS_INTROL => #[0, 0] (* The extra arg is that the other *)
       | PLUS_INTROR => #[0, 0] (* branch has a type. Just a wf-ness goal *)
       | PLUS_ELIM => #[0, 1, 1]
       | INL_EQ => #[0, 0]
       | INR_EQ => #[0, 0]
       | DECIDE_EQ => #[0, 2, 2]

       | NAT_EQ => #[]
       | NAT_ELIM => #[0,0,2]
       | ZERO_EQ => #[]
       | SUCC_EQ => #[0]
       | NATREC_EQ => #[0,0,2]

       | FUN_EQ => #[0,1]
       | FUN_INTRO => #[1,0]
       | FUN_ELIM => #[0,0,0,2]
       | LAM_EQ => #[1,0]
       | AP_EQ => #[0,0]
       | FUN_EXT => #[1,0,0,0]

       | ISECT_EQ => #[0,1]
       | ISECT_INTRO => #[1,0]
       | ISECT_ELIM => #[0,0,0,2]
       | ISECT_MEMBER_EQ => #[1,0]
       | ISECT_MEMBER_CASE_EQ => #[0,0]

       | WITNESS => #[0,0]
       | HYP_EQ => #[0]
       | EQ_SUBST => #[0,0,1]
       | EQ_SYM => #[0]

       | SUBSET_EQ => #[0,1]
       | SUBSET_INTRO => #[0,0,0,1]
       | IND_SUBSET_INTRO => #[0,0]
       | SUBSET_ELIM => #[0,2]
       | SUBSET_MEMBER_EQ => #[0,0,1]

       | CONTAINER_EQ => #[]
       | CONTAINER_MEM_EQ => #[0,1]
       | CONTAINER_ELIM => #[0,2]

       | EXTENSION_EQ => #[0,0]
       | EXTEND_EQ => #[0,1]
       | EXTENSION_ELIM => #[0,2]

       | NEIGH_EQ => #[0]
       | NEIGH_NIL_EQ => #[0]
       | NEIGH_SNOC_EQ => #[0,1]
       | NEIGH_IND_EQ => #[0,0,3]
       | NEIGH_ELIM => #[0,0,3]

       | WTREE_EQ => #[0]
       | WTREE_MEM_EQ => #[0,1]
       | WTREE_REC_EQ => #[3,0]
       | WTREE_INTRO => #[0]
       | WTREE_ELIM => #[0,3]

       | FIAT => #[]
       | LEMMA _ => #[]
       | ASSERT => #[0, 1]

  fun toString theta =
    case theta of
         UNIV_EQ i => "U-eq{" ^ Level.toString i ^ "}"
       | CUM => "cum"

       | EQ_EQ => "eq⁼"
       | EQ_EQ_BASE => "eq-eq-base⁼"
       | EQ_MEMBER_EQ => "eq-mem⁼"
       | CEQUAL_EQ => "~⁼"
       | CEQUAL_MEMBER_EQ => "~-mem⁼"
       | CEQUAL_SYM => "~-sym"
       | CEQUAL_STEP => "~-step"
       | CEQUAL_SUBST => "~-subst"
       | CEQUAL_STRUCT _ => "~-struct"
       | CEQUAL_APPROX => "~-~<="
       | CEQUAL_ELIM => "~-elim"
       | APPROX_EQ => "~<=-eq"
       | APPROX_MEMBER_EQ => "~<=-mem-eq"
       | APPROX_EXT_EQ => "~<=-ext-eq"
       | APPROX_REFL => "~<=-refl"
       | APPROX_ELIM => "~<=-elim"
       | BOTTOM_DIVERGES => "bottom-div"
       | ASSUME_HAS_VALUE => "assume-has-value"

       | BASE_EQ => "base-eq"
       | BASE_INTRO => "base-intro"
       | BASE_ELIM_EQ => "base-elim-eq"
       | BASE_MEMBER_EQ _ => "base-member-eq"
       | ATOM_SUBTYPE_BASE => "atom-subtype-base"

       | IMAGE_EQ => "image-eq"
       | IMAGE_MEM_EQ => "image-mem-eq"
       | IMAGE_ELIM => "image-elim"
       | IMAGE_EQ_IND => "image-eq-ind"

       | PER_EQ => "per-eq"
       | PER_MEM_EQ => "per-mem-eq"
       | PER_ELIM => "per-elim"

       | UNHIDE => "unhide"
       | POINTWISE_FUNCTIONALITY => "pointwise-functionality"

       | ATOM_EQ => "atom-eq"
       | TOKEN_EQ => "token-eq"
       | MATCH_TOKEN_EQ toks =>
           let
             val n = Vector.length toks
             val toks' = Vector.map (fn x => "\"" ^ x ^ "\"") toks
           in
             "token-match-eq{"
             ^ Vector.foldri (fn (i, s1, s2) => if i = n - 1 then s1 else s1 ^ "; " ^ s2) "" toks'
             ^ "}"
           end
       | TEST_ATOM_EQ => "test_atom-eq"
       | TEST_ATOM_REDUCE_LEFT => "test_atom-reduce-left"
       | TEST_ATOM_REDUCE_RIGHT => "test_atom-reduce-right"

       | PROD_EQ => "prod-eq"
       | PROD_INTRO => "prod-intro"
       | IND_PROD_INTRO => "independent-prod-intro"
       | PROD_ELIM => "prod-elim"
       | PAIR_EQ => "pair-eq"
       | SPREAD_EQ => "spread-eq"

       | FUN_EQ => "fun-eq"
       | FUN_INTRO => "fun-intro"
       | FUN_ELIM => "fun-elim"
       | LAM_EQ => "lam-eq"
       | AP_EQ => "ap-eq"
       | FUN_EXT => "funext"

       | PLUS_INTROL => "plus-introl"
       | PLUS_INTROR => "plus-intror"
       | PLUS_ELIM => "plus-elim"
       | PLUS_EQ => "plus-eq"
       | INL_EQ => "inl-eq"
       | INR_EQ => "inr-eq"
       | DECIDE_EQ => "decide-eq"

       | NAT_EQ => "nat-eq"
       | NAT_ELIM => "nat-elim"
       | ZERO_EQ => "zero-eq"
       | SUCC_EQ => "succ-eq"
       | NATREC_EQ => "natrec-eq"

       | ISECT_EQ => "isect-eq"
       | ISECT_INTRO => "isect-intro"
       | ISECT_ELIM => "isect-elim"
       | ISECT_MEMBER_EQ => "isect-mem-eq"
       | ISECT_MEMBER_CASE_EQ => "isect-mem-case⁼"

       | WITNESS => "witness"
       | HYP_EQ => "hyp-eq"
       | EQ_SUBST => "subst"
       | EQ_SYM => "sym"
       | FIAT => "<<<<<FIAT>>>>>"

       | SUBSET_EQ => "subset-eq"
       | SUBSET_INTRO => "subset-intro"
       | IND_SUBSET_INTRO => "independent-subset-intro"
       | SUBSET_ELIM => "subset-elim"
       | SUBSET_MEMBER_EQ => "subset-member-eq"

       | CONTAINER_EQ => "container-eq"
       | CONTAINER_MEM_EQ => "container-mem-eq"
       | CONTAINER_ELIM => "container-elim"

       | EXTENSION_EQ => "extension-eq"
       | EXTEND_EQ => "extend-eq"
       | EXTENSION_ELIM => "extension-elim"

       | NEIGH_EQ => "neigh-eq"
       | NEIGH_NIL_EQ => "neigh-nil-eq"
       | NEIGH_SNOC_EQ => "neigh-snoc-eq"
       | NEIGH_IND_EQ => "neigh-ind-eq"
       | NEIGH_ELIM => "neigh-elim"


       | WTREE_EQ => "wtree-eq"
       | WTREE_MEM_EQ => "wtree-mem-eq"
       | WTREE_REC_EQ => "wtree-rec-eq"
       | WTREE_INTRO => "wtree-intro"
       | WTREE_ELIM => "wtree-elim"

       | LEMMA {label} => Label.toString label
       | ASSERT => "assert"
end

structure DerivationInj = OperatorInjection (Derivation)
