; > Generally, “lazy” refers to the mechanisms of particular evaluators, while “normal-order” refers to the semantics of languages, independent of any particular evaluation strategy.

; > If the body of a procedure is entered before an argument has been evaluated we say that the procedure is non-strict in that argument.

; it can be useful to make some procedures non-strict e.g. compute the length of a list without knowing the values of the individual elements

; implementing this as a special form would result in this being just syntax, instead of a higher-order procedure that can be passed around as a value like one could if done with lazy evaluation
(define (unless condition usual-value exceptional-value)
  (if condition exceptional-value usual-value))

; we can implement non-strict compound procedure arguments
; delayed arguments are not evaluated, instead they are transformed into objects called thunks

; thunks will be forced only when its value is needed i.e. when a thunk is: 
; - passed to a primitive procedure that will use the value of the thunk
; - the value of a predicate of a conditional
; - the value of an operator that is about to be applied as a procedure

; with lazy evaluation, streams and lists can be identical, so there is no need for special forms or for separate list and stream operations. we can make cons should non-strict in the evaluator or by simply defining cons with procedures if we have lazy evaluation.
; lazy pairs also help with the problem that arose with streams in applicative-order evaluation where formulating stream models of systems with loops may require explicit delay operations beyond the ones supplied by cons-stream. with lazy evaluation, all arguments to procedures are delayed uniformly
; we can have other kinds of lazy data structures e.g. lazy trees
