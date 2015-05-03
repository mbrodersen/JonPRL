functor Whnf (Syn : ABTUTIL where Operator = Lang) :
sig
  val whnf : Syn.t -> Syn.t
  exception WhnfStuck
end =
struct
  exception WhnfStuck

  open Lang Syn
  infix $ $$

  fun whnf x =
    case out x of
         FST $ #[M] =>
           (case out (whnf M) of
                PAIR $ #[M1, M2] => whnf M1
              | _ => raise WhnfStuck)
       | SND $ #[M] =>
           (case out (whnf M) of
                 PAIR $ #[M1, M2] => whnf M2
               | _ => raise WhnfStuck)
       | AP $ #[M,N] =>
           (case out (whnf M) of
                 LAM $ #[xE] => whnf (subst1 xE N)
               | _ => raise WhnfStuck)
       | MATCH_UNIT $ #[M,N] =>
           (case out (whnf M) of
                 AX $ #[] => whnf N
               | _ => raise WhnfStuck)
       | _ => x


end
