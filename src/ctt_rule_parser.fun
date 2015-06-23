functor CttRuleParser
  (structure ParserContext : PARSER_CONTEXT
   structure Tactic : TACTIC
     where type level = int
     where type label = ParserContext.label
   structure ParseSyntax : PARSE_ABT
     where type t = Tactic.term
     where type Variable.t = Tactic.name
     where type ParseOperator.world = ParserContext.label -> Arity.t
   val stringToLabel : string -> ParserContext.label
   ) : INTENSIONAL_PARSER
         where type world = ParserContext.world
           and type t = Tactic.t =
struct
  open ParserContext Tactic ParserCombinators CharParser

  infix 2 return wth suchthat return guard when
  infixr 1 || <|>
  infixr 3 &&
  infixr 4 << >>

  open JonprlTokenParser

  val parseInt =
    repeat1 digit wth valOf o Int.fromString o String.implode

  val parseLevel =
    lexeme (symbol "@" >> parseInt)

  val parseIndex =
    lexeme (symbol "#" >> parseInt)

  fun parseOpt p =
    symbol "_" return NONE
      || p wth SOME

  val parseName =
    identifier
      wth ParseSyntax.Variable.named

  val parseLabel = identifier wth stringToLabel

  type 'a intensional_parser = world -> 'a charParser
  type tactic_parser = (Pos.t -> Tactic.t) intensional_parser

  val parseTm : ParseSyntax.t intensional_parser =
    squares o ParseSyntax.parseAbt [] o lookupOperator

  val parseCum : tactic_parser =
    fn w => symbol "cum"
      && opt parseLevel
      wth (fn (name, k) => fn pos => CUM (k, {name = name, pos = pos}))

  val parseWitness : tactic_parser =
    fn w => symbol "witness"
      && parseTm w
      wth (fn (name, tm) => fn pos =>
              WITNESS (tm, {name = name, pos = pos}))

  val parseHypothesis : tactic_parser =
    fn w => symbol "hypothesis"
      && parseIndex
      wth (fn (name, i) => fn pos =>
        HYPOTHESIS (i, {name = name, pos = pos}))

  val parseEqSubst : tactic_parser =
    fn w => symbol "subst"
      && parseTm w && parseTm w && opt parseLevel
      wth (fn (name, (M, (N, k))) => fn pos =>
              EQ_SUBST ({left = M, right = N, level = k},
                        {name = name, pos = pos}))

  val parseDir =
    (symbol "→" || symbol "->") return Dir.RIGHT
      || (symbol "←" || symbol "<-") return Dir.LEFT

  val parseHypSubst : tactic_parser =
    fn w => symbol "hyp-subst"
      && parseDir
      && parseIndex
      && parseTm w && opt parseLevel
      wth (fn (name, (dir, (i, (M, k)))) => fn pos =>
              HYP_SUBST
                ({dir = dir,
                  index = i,
                  domain = M,
                  level = k},
                 {name = name, pos = pos}))

  val parseIntroArgs =
    fn w => opt (parseTm w)
      && opt parseIndex
      && opt (brackets parseName)
      && opt parseLevel
      wth (fn (tm, (rule, (z, k))) =>
            {term = tm,
             rule = rule,
             freshVariable = z,
             level = k})

  val parseNames =
    opt (brackets (commaSep1 parseName))
    wth (fn SOME xs => xs
          | NONE => [])

  val parseElimArgs =
    fn w => parseIndex
      && opt (parseTm w)
      && parseNames
      wth (fn (i, (M, names)) =>
            {target = i,
             term = M,
             names = names})

  val parseTerms : term list intensional_parser =
    fn w => opt (squares (commaSep1 (ParseSyntax.parseAbt [] (lookupOperator w))))
    wth (fn oxs => getOpt (oxs, []))

  val parseEqCdArgs =
    fn w => (parseTerms w)
      && parseNames
      && opt parseLevel
      wth (fn (Ms, (xs, k)) => {names = xs, terms = Ms, level = k})

  val parseExtArgs =
    fn w => opt (brackets parseName)
      && opt parseLevel
      wth (fn (z,k) => {freshVariable = z, level = k})

  val parseIntro =
    fn w => symbol "intro"
      && parseIntroArgs w
      wth (fn (name, args) => fn pos =>
              INTRO (args, {name = name, pos = pos}))

  val parseElim =
    fn w => symbol "elim"
      && parseElimArgs w
      wth (fn (name, args) => fn pos =>
              ELIM (args, {pos = pos, name = name}))

  val parseEqCd =
    fn w => symbol "eq-cd"
      && (parseEqCdArgs w)
      wth (fn (name, args) => fn pos =>
              EQ_CD (args, {name = name, pos = pos}))

  val parseExt =
    fn w => symbol "ext"
      && parseExtArgs w
      wth (fn (name, args) => fn pos =>
              EXT (args, {name = name, pos = pos}))

  val parseSymmetry : tactic_parser =
    fn w => symbol "symmetry"
      wth (fn name => fn pos => SYMMETRY {name = name, pos = pos})

  val parseAssumption : tactic_parser =
    fn w => symbol "assumption"
      wth (fn name => fn pos => ASSUMPTION {name = name, pos = pos})

  val parseMemCd : tactic_parser =
    fn w => symbol "mem-cd"
      wth (fn name => fn pos => MEM_CD {name = name, pos = pos})

  val parseAuto : tactic_parser =
    fn w => symbol "auto"
      wth (fn name => fn pos => AUTO {name = name, pos = pos})

  val parseLemma : tactic_parser =
    fn w => symbol "lemma"
      && brackets parseLabel
      wth (fn (name, lbl) => fn pos =>
             LEMMA (lbl, {name = name, pos = pos}))

  val parseUnfold : tactic_parser =
    fn w => symbol "unfold"
      && brackets (separate parseLabel whiteSpace)
      wth (fn (name, lbls) => fn pos =>
             UNFOLD (lbls, ({name = name, pos = pos})))

  val parseCustomTactic : tactic_parser =
    fn w => symbol "refine"
      >> brackets identifier
      wth (fn name => fn (pos : Pos.t) =>
            CUSTOM_TACTIC (stringToLabel name, {name = name, pos = pos}))

  fun tacticParsers w =
    parseLemma w
      || parseUnfold w
      || parseCustomTactic w
      || parseWitness w
      || parseHypothesis w
      || parseEqSubst w
      || parseHypSubst w
      || parseIntro w
      || parseElim w
      || parseEqCd w
      || parseExt w
      || parseCum w
      || parseAuto w
      || parseMemCd w
      || parseAssumption w
      || parseSymmetry w

  val parse : world -> Tactic.t charParser =
    fn w => !! (tacticParsers w)
    wth (fn (t, pos) => t pos)
end

structure CttRuleParser = CttRuleParser
  (structure Tactic = Tactic
   structure ParseSyntax = Syntax
   structure ParserContext = StringVariableContext
   val stringToLabel = StringVariable.named)

structure CttScript = TacticScript
  (structure Tactic = Tactic
   structure RuleParser = CttRuleParser)
