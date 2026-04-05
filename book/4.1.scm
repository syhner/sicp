; > An evaluator (or interpreter) for a programming language is a procedure that, when applied to an expression of the language, performs the actions required to evaluate that expression. it is a program which determines the meaning of expressions in a programming language

; > The technology for coping with large-scale computer systems merges with the technology for building new computer languages, and computer science itself becomes no more (and no less) than the discipline of constructing appropriate descriptive languages.

; > An evaluator that is written in the same language that it evaluates is said to be metacircular.

; the metacircular evaluator is essentially a Scheme formulation of the environment model of evaluation where
; 1. to evaluate a combination (a compound expression other than a special form), evaluate the subexpressions and then apply the value of the operator subexpression to the values of the operand subexpressions.
; 2. to apply a compound (non-primitive) procedure to a set of arguments, evaluate the body of the procedure in a new environment. to construct this environment, extend the environment part of the procedure object by a frame in which the formal parameters of the procedure are bound to the arguments to which the procedure is applied.

; > These two rules describe the essence of the evaluation process, a basic cycle in which expressions to be evaluated in environments are reduced to procedures to be applied to arguments, which in turn are reduced to new expressions to be evaluated in new environments, and so on, until we get down to symbols, whose values are looked up in the environment, and to primitive procedures, which are applied directly.

; allows us to do things like
; (+ 1 (* 2 3)) where the primitive operator + can only deal with numbers
; (+ x 1) where we need an evaluator to keep track of variables and obtain their values before invoking the primitive procedures
; compound procedures
; special forms

; > eval takes as arguments an expression and an environment. It classifies the expression and directs its evaluation. eval is structured as a case analysis of the syntactic type of the expression to be evaluated. In order to keep the procedure general, we express the determination of the type of an expression abstractly, making no commitment to any particular representation for the various types of expressions. Each type of expression has a predicate that tests for it and an abstract means for selecting its parts. This abstract syntax makes it easy to see how we can change the syntax of the language by using the same evaluator, but with a different collection of syntax procedures.
(define (eval exp env)
  (cond
    ; For self-evaluating expressions, such as numbers, eval returns the expression itself.
    ((self-evaluating? exp) exp)

    ; eval must look up variables in the environment to find their values.
    ((variable? exp) (lookup-variable-value exp env))

    ; For quoted expressions, eval returns the expression that was quoted.
    ((quoted? exp) (text-of-quotation exp))

    ; An assignment to (or a definition of) a variable must recursively call eval to compute the new value to be associated with the variable. The environment must be modified to change (or create) the binding of the variable.
    ((assignment? exp) (eval-assignment exp env))
    ((definition? exp) (eval-definition exp env))

    ; An if expression requires special processing of its parts, so as to evaluate the consequent if the predicate is true, and otherwise to evaluate the alternative.  
    ((if? exp) (eval-if exp env))

    ; A lambda expression must be transformed into an applicable procedure by packaging together the parameters and body specified by the lambda expression with the environment of the evaluation.
    ((lambda? exp) (make-procedure (lambda-parameters exp)
                                   (lambda-body exp)
                                   env))

    ; A begin expression requires evaluating its sequence of expressions in the order in which they appear.
    ((begin? exp) (eval-sequence (begin-actions exp) env))

    ; A case analysis (cond) is transformed into a nest of if expressions and then evaluated.
    ((cond? exp) (eval (cond->if exp) env))

    ; For a procedure application, eval must recursively evaluate the operator part and the operands of the combination. The resulting procedure and arguments are passed to apply, which handles the actual procedure application.
    ((application? exp) (apply (eval (operator exp) env)
                               (list-of-values (operands exp) env)))

    (else
     (error "Unknown expression type: EVAL" exp))))

; apply takes two arguments, a procedure and a list of arguments to which the procedure should be applied. apply classifies procedures into two kinds
(define (apply procedure arguments)
  (cond 
    ; primitive procedures
    ((primitive-procedure? procedure)
     (apply-primitive-procedure procedure arguments))

    ; sequentially evaluate the expressions that make up the body of the procedure
    ; the environment for the evaluation of the body of a compound procedure is constructed by extending the base environment carried by the procedure to include a frame that binds the parameters of the procedure to the arguments to which the procedure is to be applied.
    ((compound-procedure? procedure)
     (eval-sequence (procedure-body procedure)
                    (extend-environment (procedure-parameters procedure)
                                        arguments
                                        (procedure-environment procedure))))

  (else
   (error "Unknown procedure type: APPLY" procedure))))

; produce the list of arguments to which the procedure is to be applied.
(define (list-of-values exps env)
  (if (no-operands? exps)
      '()
      (cons (eval (first-operand exps) env)
            (list-of-values (rest-operands exps) env))))

(define (eval-if exp env)
; The if-predicate is evaluated in the language being implemented and thus yields a value in that language. The interpreter predicate `true?` translates that value into a value that can be tested by the if in the implementation language
  (if (true? (eval (if-predicate exp) env))
      (eval (if-consequent exp) env)
      (eval (if-alternative exp) env)))

; evaluate the sequence of expressions in a procedure body and by eval to evaluate the sequence of expressions in a begin expression
(define (eval-sequence exps env)
  (cond ((last-exp? exps)
         (eval (first-exp exps) env))
  (else (eval (first-exp exps) env)
        (eval-sequence (rest-exps exps) env))))

(define (eval-assignment exp env)
  (set-variable-value! (assignment-variable exp)
                       (eval (assignment-value exp) env)
                        env)
  'ok)

(define (eval-definition exp env)
  (define-variable! (definition-variable exp)
                    (eval (definition-value exp) env)
                    env)
  'ok)

; ---- representing expressions

; the only self-evaluating items are numbers and strings
(define (self-evaluating? exp)
  (cond ((number? exp) true)
        ((string? exp) true)
  (else false)))

; variables are represented by symbols
(define (variable? exp) (symbol? exp))

; quotations have the form (quote <text-of-quotation>):
(define (quoted? exp) (tagged-list? exp 'quote))
(define (text-of-quotation exp) (cadr exp))

; identify lists beginning with a designated symbol
(define (tagged-list? exp tag)
  (if (pair? exp)
      (eq? (car exp) tag)
      false))

; assignments have the form (set! <var> <value>)
(define (assignment? exp) (tagged-list? exp 'set!))
(define (assignment-variable exp) (cadr exp))
(define (assignment-value exp) (caddr exp))

; definitions have the form (define <var> <value>)
; or (define (<var> <parameter1>. . . <parametern>) <body>) which is syntactic sugar for
; (define <var> (lambda (<parameter1>. . . <parametern>) <body>))
(define (definition? exp) (tagged-list? exp 'define))
(define (definition-variable exp)
  (if (symbol? (cadr exp))
      (cadr exp)
      (caadr exp)))
(define (definition-value exp)
  (if (symbol? (cadr exp))
      (caddr exp)
      (make-lambda (cdadr exp)   ; formal parameters
                   (cddr exp)))) ; body

; lambda expressions are lists that begin with the symbol lambda
(define (lambda? exp) (tagged-list? exp 'lambda))
(define (lambda-parameters exp) (cadr exp))
(define (lambda-body exp) (cddr exp))
(define (make-lambda parameters body)
  (cons 'lambda (cons parameters body)))

; conditionals have the form (if <predicate> <consequent> [<alternative> = false])
(define (if? exp) (tagged-list? exp 'if))
(define (if-predicate exp) (cadr exp))
(define (if-consequent exp) (caddr exp))
(define (if-alternative exp)
  (if (not (null? (cdddr exp)))
      (cadddr exp)
      'false))
(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))

; begin expressions have the form (begin <exp_1> <exp_2> ...)
; package a sequence of expressions into a single expression
(define (begin? exp) (tagged-list? exp 'begin))
(define (begin-actions exp) (cdr exp))
(define (last-exp? seq) (null? (cdr seq)))
(define (first-exp seq) (car seq))
(define (rest-exps seq) (cdr seq))
(define (sequence->exp seq)
  (cond ((null? seq) seq)
    ((last-exp? seq) (first-exp seq))
  (else (make-begin seq))))
(define (make-begin seq) (cons 'begin seq))

; procedure applications have the form (<operator> <operand_1> <operand_2> ...)
(define (application? exp) (pair? exp))
(define (operator exp) (car exp))
(define (operands exp) (cdr exp))
(define (no-operands? ops) (null? ops))
(define (first-operand ops) (car ops))
(define (rest-operands ops) (cdr ops))

; some special forms (e.g. cond, and, or, let, let*, do, for, while, until) can be implemented as syntactic transformations (called derived expressions) to special forms that the evaluation process can already handle (e.g. if, define). user-defined ones are called macros
(define (cond? exp) (tagged-list? exp 'cond))
(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) (car clause))
(define (cond-actions clause) (cdr clause))
(define (cond->if exp) (expand-clauses (cond-clauses exp)))
(define (expand-clauses clauses)
  (if (null? clauses)
    'false ; no else clause
    (let ((first (car clauses))
          (rest (cdr clauses)))
      (if (cond-else-clause? first)
        (if (null? rest)
            (sequence->exp (cond-actions first))
            (error "ELSE clause isn't last: COND->IF"
                   clauses))
        (make-if (cond-predicate first)
                 (sequence->exp (cond-actions first))
                 (expand-clauses rest))))))

; ----

; In most Lisp implementations, dispatching on the type of an expression is done in a data-directed style. This allows a user to add new types of expressions that eval can distinguish, without modifying the definition of eval itself.

; (define (eval exp env)
; (cond ((self-evaluating? exp) exp)
;       ((variable? exp) (lookup-variable-value exp env))
;       ((application? exp)
;        (let ((proc
;               (get 'eval (operator exp))))
;          (if proc
;              (proc exp env)
;              (apply (eval (operator exp) env)
;                     (list-of-values (operands exp) env)))))
;       (else
;        (error "Unknown expression type: EVAL" exp))))

; (define (eval-quoted exp env)
;   (text-of-quotation exp))
; (put 'eval 'quote eval-quoted)

; (define (eval-assignment exp env)
;   (set-variable-value! (assignment-variable exp)
;                        (eval (assignment-value exp) env)
;                        env)
;   'ok)
; (put 'eval 'set! eval-assignment)

; (define (eval-definition exp env)
;   (define-variable! (definition-variable exp)
;                     (eval (definition-value exp) env)
;                     env)
;   'ok)
; (put 'eval 'define eval-definition)

; (define (eval-if exp env)
;   (if (true? (eval (if-predicate exp) env))
;       (eval (if-consequent exp) env)
;       (eval (if-alternative exp) env)))
; (put 'eval 'if eval-if)

; (define (eval-lambda exp env)
;   (make-procedure (lambda-parameters exp)
;                   (lambda-body exp)
;                   env))
; (put 'eval 'lambda eval-lambda)

; (define (eval-begin exp env)
;   (eval-sequence (begin-actions exp) env))
; (put 'eval 'begin eval-begin)

; (define (eval-cond exp env)
;   (eval (cond->if exp) env))
; (put 'eval 'cond eval-cond)

; ---- evaluator data structures

; In addition to defining the external syntax of expressions, the evaluator implementation must also define the data structures that the evaluator manipulates internally, as part of the execution of a program

; testing predicates
(define (true? x) (not (eq? x false)))
(define (false? x) (eq? x false))

; representing procedures
(define (make-procedure parameters body env)
  (list 'procedure parameters body env))
(define (compound-procedure? p)
  (tagged-list? p 'procedure))
(define (procedure-parameters p) (cadr p))
(define (procedure-body p) (caddr p))
(define (procedure-environment p) (cadddr p))

; operations on environments - a simple approach but inefficient due to deep binding (having to search through many frames for a binding). one way to avoid this is through lexical addressing.

(define (enclosing-environment env) (cdr env))
(define (first-frame env) (car env))
(define the-empty-environment '())
(define (make-frame variables values)
  (cons variables values))

(define (frame-variables frame) (car frame))
(define (frame-values frame) (cdr frame))
(define (add-binding-to-frame! var val frame)
  (set-car! frame (cons var (car frame)))
  (set-cdr! frame (cons val (cdr frame))))

(define (extend-environment vars vals base-env)
  (if (= (length vars) (length vals))
      (cons (make-frame vars vals) base-env)
      (if (< (length vars) (length vals))
          (error "Too many arguments supplied" vars vals)
          (error "Too few arguments supplied" vars vals))))

(define (lookup-variable-value var env)
(define (env-loop env)
(define (scan vars vals)
  (cond ((null? vars)
         (env-loop (enclosing-environment env)))
        ((eq? var (car vars)) (car vals))
        (else (scan (cdr vars) (cdr vals)))))
  (if (eq? env the-empty-environment)
      (error "Unbound variable" var)
      (let ((frame (first-frame env)))
           (scan (frame-variables frame)
                (frame-values frame)))))
  (env-loop env))

(define (set-variable-value! var val env)
(define (env-loop env)
  (define (scan vars vals)
    (cond ((null? vars)
           (env-loop (enclosing-environment env)))
          ((eq? var (car vars))
           (set-car! vals val))
          (else
           (scan (cdr vars) (cdr vals)))))
  (if (eq? env the-empty-environment)
      (error "Unbound variable: SET!" var)
      (let ((frame (first-frame env)))
        (scan (frame-variables frame)
              (frame-values frame)))))
(env-loop env))

(define (define-variable! var val env)
  (let ((frame (first-frame env)))
    (define (scan vars vals)
      (cond ((null? vars)
             (add-binding-to-frame! var val frame))
            ((eq? var (car vars)) (set-car! vals val))
            (else (scan (cdr vars) (cdr vals)))))
      (scan (frame-variables frame) (frame-values frame))))

; ---- running the evaluator as a program

; There must be a binding for each primitive procedure name, so that when eval evaluates the operator of an application of a primitive, it will find an object to pass to apply. We thus set up a global environment that associates unique objects with the names of the primitive procedures that can appear in the expressions we will be evaluating. The global environment also includes bindings for the symbols true and false, so that they can be used as variables in expressions to be evaluated.

(define (setup-environment)
  (let ((initial-env
         (extend-environment (primitive-procedure-names)
                             (primitive-procedure-objects)
                             the-empty-environment)))
  (define-variable! 'true true initial-env)
  (define-variable! 'false false initial-env)
  initial-env))

(define (primitive-procedure? proc)
  (tagged-list? proc 'primitive))
(define (primitive-implementation proc) (cadr proc))

(define primitive-procedures
  (list (list 'car car)
  (list 'cdr cdr)
  (list 'cons cons)
  (list 'null? null?)))
(define (primitive-procedure-names)
  (map car primitive-procedures))
(define (primitive-procedure-objects)
  (map (lambda (proc) (list 'primitive (cadr proc)))
       primitive-procedures))

(define (apply-primitive-procedure proc args)
  (apply-in-underlying-scheme (primitive-implementation proc)
                              args))
; avoid naming conflict between metacircular evaluator's apply and underlying scheme
(define apply-in-underlying-scheme apply)

; For convenience in running the metacircular evaluator, we provide a driver loop that models the read-eval-print loop of the underlying Lisp system. It prints a prompt, reads an input expression, evaluates this expression in the global environment, and prints the result. We precede each printed result by an output prompt so as to distinguish the value of the expression from other output that may be printed.
(define input-prompt ";;;M-Eval input:")
(define output-prompt ";;;M-Eval value:")
(define (driver-loop)
  (prompt-for-input input-prompt)
  (let ((input (read)))
    (let ((output (eval input the-global-environment)))
      (announce-output output-prompt)
      (user-print output)))
  (driver-loop))
(define (prompt-for-input string)
  (newline) (newline) (display string) (newline))
(define (announce-output string)
  (newline) (display string) (newline))
; avoid printing environment part of compound procedure which may be long and may include cycles
(define (user-print object)
  (if (compound-procedure? object)
      (display (list 'compound-procedure
                     (procedure-parameters object)
                     (procedure-body object)
                     '<procedure-env>))
      (display object)))

(define the-global-environment (setup-environment))
(driver-loop)

; ---- seperating syntactic analysis from evaluation

; this evaluator is inefficient since the syntactic analysis is interleaved with the execution e.g. each recursive call of (factorial 4) will have to have its syntax analysed. we can fix this by splitting eval into analysis and execution
(define (eval exp env) ((analyze exp) env))

; performs semantic analysis. will only be called once on an expression.
; returns an execution procedure which takes an environment as its argument and completes the evaluation. the execution procedure encapsulates the work to be done in executing the analyzed expression and may be called many times
(define (analyze exp)
(cond ((self-evaluating? exp) (analyze-self-evaluating exp))
      ((quoted? exp) (analyze-quoted exp))
      ((variable? exp) (analyze-variable exp))
      ((assignment? exp) (analyze-assignment exp))
      ((definition? exp) (analyze-definition exp))
      ((if? exp) (analyze-if exp))
      ((lambda? exp) (analyze-lambda exp))
      ((begin? exp) (analyze-sequence (begin-actions exp)))
      ((cond? exp) (analyze (cond->if exp)))
      ((application? exp) (analyze-application exp))
      (else (error "Unknown expression type: ANALYZE" exp))))

; ignore env, return exp
(define (analyze-self-evaluating exp)
  (lambda (env) exp))

; extract quotation once
(define (analyze-quoted exp)
  (let ((qval (text-of-quotation exp)))
    (lambda (env) qval)))

; looking up a variable value must still be done in the execution phase, since this depends upon knowing the environment (though lexical analysis can move some of the variable search to the semantic analysis)
(define (analyze-variable exp)
  (lambda (env) (lookup-variable-value exp env)))

; defer actually setting the variable until the execution (when the environment has been supplied). assignment-value expression can be analysed recursively and will now be analysed only once. the same holds true for definitions.
(define (analyze-assignment exp)
  (let ((var (assignment-variable exp))
        (vproc (analyze (assignment-value exp))))
    (lambda (env)
      (set-variable-value! var (vproc env) env)
      'ok)))
(define (analyze-definition exp)
  (let ((var (definition-variable exp))
        (vproc (analyze (definition-value exp))))
    (lambda (env)
      (define-variable! var (vproc env) env)
      'ok)))

; extract and analyze the predicate, consequent, and alternative
(define (analyze-if exp)
  (let ((pproc (analyze (if-predicate exp)))
        (cproc (analyze (if-consequent exp)))
        (aproc (analyze (if-alternative exp))))
    (lambda (env) (if (true? (pproc env))
                      (cproc env)
                      (aproc env)))))

; analyze the lambda body only once, though procedures resulting from evaluation of the lambda may be applied many times
(define (analyze-lambda exp)
  (let ((vars (lambda-parameters exp))
        (bproc (analyze-sequence (lambda-body exp))))
    (lambda (env) (make-procedure vars bproc env))))

; each expression in the sequence is analyzed, yielding an execution procedure. these execution procedures are combined to produce an execution procedure that takes an environment as argument and sequentially calls each individual execution procedure with the environment as argument.
(define (analyze-sequence exps)
  (define (sequentially proc1 proc2)
    (lambda (env) (proc1 env) (proc2 env)))
  (define (loop first-proc rest-procs)
    (if (null? rest-procs)
        first-proc
        (loop (sequentially first-proc (car rest-procs))
              (cdr rest-procs))))
  (let ((procs (map analyze exps)))
    (if (null? procs) (error "Empty sequence: ANALYZE"))
    (loop (car procs) (cdr procs))))

; analyze the operator and operands and construct an execution procedure that calls the operator execution procedure (to obtain the actual procedure to be applied) and the operand execution procedures (to obtain the actual arguments)
(define (analyze-application exp)
  (let ((fproc (analyze (operator exp)))
        (aprocs (map analyze (operands exp))))
    (lambda (env)
      (execute-application
        (fproc env)
        (map (lambda (aproc) (aproc env))
            aprocs)))))

; diﬀers from apply in that the procedure body for a compound procedure has already been analyzed, so there is no need to do further analysis. instead, we just call the execution procedure for the body on the extended environment
(define (execute-application proc args)
  (cond ((primitive-procedure? proc)
         (apply-primitive-procedure proc args))
        ((compound-procedure? proc)
         ((procedure-body proc)
          (extend-environment (procedure-parameters proc)
                              args
                              (procedure-environment proc))))
        (else
          (error "Unknown procedure type: EXECUTE-APPLICATION"
                 proc))))
