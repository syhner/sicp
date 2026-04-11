; an interpreter provides a more powerful environment for interactive program development and debugging than compilation, because the source program being executed is available at run time to be examined and modified. in addition, because the entire library of primitives is present, new programs can be constructed and added to the system during debugging.

(define (compile exp target linkage)
  (cond ((self-evaluating? exp)
         (compile-self-evaluating exp target linkage))
        ((quoted? exp) (compile-quoted exp target linkage))
        ((variable? exp)
         (compile-variable exp target linkage))
        ((assignment? exp)
         (compile-assignment exp target linkage))
        ((definition? exp)
         (compile-definition exp target linkage))
        ((if? exp) (compile-if exp target linkage))
        ((lambda? exp) (compile-lambda exp target linkage))
        ((begin? exp)
         (compile-sequence (begin-actions exp) target linkage))
        ((cond? exp)
         (compile (cond->if exp) target linkage))
        ((application? exp)
         (compile-application exp target linkage))
        (else
         (error "Unknown expression type: COMPILE" exp))))

; linkage descriptor describes how the code resulting from compilation of the expression should proceed when it has finished its execution. it requires that the code do one of:
; - next - continue at the next instruction in sequence
; - return - return from the procedure being compiled
; - <label> - jump to a named entry point

; > one strategy is to begin with the explicit-control evaluator and translate its instructions to instructions for the new machine. Aadiﬀerent strategy is to begin with the compiler and change the code generators so that they generate code for the new machine. the second strategy allows us to run any lisp program on the new machine by first compiling it with the compiler running on our original Lisp system, and linking it with a compiled version of the runtime library. better yet, we can compile the compiler itself, and run this on the new machine to compile other lisp programs. or we can compile one of the interpreters to produce an interpreter that runs on the new machine.
