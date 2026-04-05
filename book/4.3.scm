(define (prime-sum-pair list1 list2)
  (let ((a (an-element-of list1))
        (b (an-element-of list2)))
    (require (prime? (+ a b)))
    (list a b)))

; (amb e_1> <e_2> ... <e_n>)
; returns the value of one of the n expressions <e_i> “ambiguously.”

(list (amb 1 2 3) (amb 'a 'b))
; may yield (1 a) (1 b) (2 a) (2 b) (3 a) (3 b)

; (amb) is amb with no choices causing the computation to 'fail'
(define (require p) (if (not p) (amb)))

; fails if the list is empty, otherwise it ambiguously returns an element of the list
(define (an-element-of items)
  (require (not (null? items)))
  (amb (car items) (an-element-of (cdr items))))

; much like stream approach, but instead of an object that represents the sequence of all integers >= n, returns a single integer
(define (an-integer-starting-from n)
  (amb n (an-integer-starting-from (+ n 1))))

; > The distinction between nondeterministically returning a single choice and returning all choices depends somewhat on our point of view. From the perspective of the code that uses the value, the nondeterministic choice returns a single value. From the perspective of the programmer designing the code, the nondeterministic choice potentially returns all possible values, and the computation branches so that each value is investigated separately.

; > Abstractly, we can imagine that evaluating an amb expression causes time to split into branches, where the computation continues on each branch with one of the possible values of the expression. We say that amb represents a nondeterministic choice point. If we had a machine with a suﬃcient number of processors that could be dynamically allocated, we could implement the search in a straightforward way. Execution would proceed as in a sequential machine, until an amb expression is encountered. At this point, more processors would be allocated and initialized to continue all of the parallel executions implied by the choice. Each processor would proceed sequentially as if it were the only choice, until it either terminates by encountering a failure, or it further subdivides, or it finishes.

; chronological backtracking: backtrack by time using most recent choice point
; dependency-directed backtracking: backtrack by cause using logical dependencies connecting facts

; try-again will backtrack and attempt to generate a non-failing execution

;;; Amb-Eval input:
(prime-sum-pair '(1 3 5 8) '(20 35 110))
;;; Starting a new problem
;;; Amb-Eval value:
(3 20)

;;; Amb-Eval input:
try-again
;;; Amb-Eval value: (3 110)

;;; Amb-Eval input:
try-again
;;; Amb-Eval value: (8 35)

;;; Amb-Eval input:
try-again
;;; There are no more values of (prime-sum-pair (quote (1 3 5 8)) (quote (20 35 110)))

;;; Amb-Eval input:
(prime-sum-pair '(19 27 30) '(11 36 58))
;;; Starting a new problem
;;; Amb-Eval value: (30 11)

; > The advantage of nondeterministic programming is that we can suppress the details of how search is carried out, thereby expressing our programs at a higher level of abstraction.

; use case: logic puzzles e.g. alice does not live on the top floor, bob lives one level below alice, charlie does not live on a floor adjacent to bob, etc.
; use case: parsing natural language where there can be multiple legal parses e.g. 'the professor lectures to the student with the cat'

; ---- implementing the amb evaluator

; The execution procedures in the amb evaluator take three arguments: the environment, and two procedures called continuation procedures. The evaluation of an expression will finish by calling one of these two continuations: If the evaluation results in a value, the success continuation is called with that value; if the evaluation results in the discovery of a dead end, the failure continuation is called. Constructing and calling appropriate continuations is the mechanism by which the nondeterministic evaluator implements backtracking.

(define (amb? exp) (tagged-list? exp 'amb))
(define (amb-choices exp) (cdr exp))

; analyzes the given expression and applies the resulting execution procedure to the given environment, together with two given continuations
(define (ambeval exp env succeed fail)
  ((analyze exp) env succeed fail))

; the general form of an execution procedure is
; (lambda (env succeed fail)
; ;; succeed is (lambda (value fail). . .)
; ;; fail is (lambda (). . .)
; ...)

; simple expressions
(define (analyze-self-evaluating exp)
  (lambda (env succeed fail)
    (succeed exp fail)))
(define (analyze-quoted exp)
  (let ((qval (text-of-quotation exp)))
    (lambda (env succeed fail)
      (succeed qval fail))))
(define (analyze-variable exp)
  (lambda (env succeed fail)
    (succeed (lookup-variable-value exp env) fail)))
(define (analyze-lambda exp)
  (let ((vars (lambda-parameters exp))
        (bproc (analyze-sequence (lambda-body exp))))
(lambda (env succeed fail)
  (succeed (make-procedure vars bproc env) fail))))

; conditionals and sequences
(define (analyze-if exp)
  (let ((pproc (analyze (if-predicate exp)))
        (cproc (analyze (if-consequent exp)))
        (aproc (analyze (if-alternative exp))))
    (lambda (env succeed fail)
      (pproc env
             ;; success continuation for evaluating the predicate
             ;; to obtain pred-value
             (lambda (pred-value fail2)
               (if (true? pred-value)
                   (cproc env succeed fail2)
                   (aproc env succeed fail2)))
             ;; failure continuation for evaluating the predicate
             fail))))
(define (analyze-sequence exps)
  (define (sequentially a b)
    (lambda (env succeed fail)
      (a env
         ;; success continuation for calling a
         (lambda (a-value fail2)
           (b env succeed fail2))
         ;; failure continuation for calling a
         fail)))
  (define (loop first-proc rest-procs)
    (if (null? rest-procs)
        first-proc
        (loop (sequentially first-proc
                            (car rest-procs))
              (cdr rest-procs))))
  (let ((procs (map analyze exps)))
    (if (null? procs)
        (error "Empty sequence: ANALYZE"))
    (loop (car procs) (cdr procs))))

; definitions and assignments
(define (analyze-definition exp)
  (let ((var (definition-variable exp))
  (vproc (analyze (definition-value exp))))
  (lambda (env succeed fail)
  (vproc env
      (lambda (val fail2)
        (define-variable! var val env)
        (succeed 'ok fail2))
      fail))))
(define (analyze-assignment exp)
  (let ((var (assignment-variable exp))
        (vproc (analyze (assignment-value exp))))
    (lambda (env succeed fail)
      (vproc env
             (lambda (val fail2)        ;*1*
               (let ((old-value
                      (lookup-variable-value var env)))
                 (set-variable-value! var val env)
                 (succeed 'ok
                          (lambda ()    ;*2*
                            (set-variable-value!
                             var old-value env)
                            (fail2)))))
             fail))))

; procedure applications
(define (analyze-application exp)
(let ((fproc (analyze (operator exp)))
      (aprocs (map analyze (operands exp))))
  (lambda (env succeed fail)
    (fproc env
           (lambda (proc fail2)
             (get-args aprocs
                       env
                       (lambda (args fail3)
                         (execute-application
                          proc args succeed fail3))
                       fail2))
           fail))))
(define (get-args aprocs env succeed fail)
  (if (null? aprocs)
      (succeed '() fail)
      ((car aprocs)
       env
       ;; success continuation for this aproc
       (lambda (arg fail2)
         (get-args
          (cdr aprocs)
          env
          ;; success continuation for
          ;; recursive call to get-args
          (lambda (args fail3)
            (succeed (cons arg args) fail3))
          fail2))
       fail)))
(define (execute-application proc args succeed fail)
  (cond ((primitive-procedure? proc)
         (succeed (apply-primitive-procedure proc args)
                  fail))
        ((compound-procedure? proc)
         ((procedure-body proc)
          (extend-environment
           (procedure-parameters proc)
           args
           (procedure-environment proc))
          succeed
          fail))
        (else
         (error "Unknown procedure type: EXECUTE-APPLICATION"
                proc))))

; evaluating amb expressions
(define (analyze-amb exp)
(let ((cprocs (map analyze (amb-choices exp))))
  (lambda (env succeed fail)
    (define (try-next choices)
      (if (null? choices)
          (fail)
          ((car choices)
           env
           succeed
           (lambda ()
             (try-next (cdr choices))))))
    (try-next cprocs))))

; driver loop
(define input-prompt ";;; Amb-Eval input:")
(define output-prompt ";;; Amb-Eval value:")

(define (driver-loop)
  (define (internal-loop try-again)
    (prompt-for-input input-prompt)
    (let ((input (read)))
      (if (eq? input 'try-again)
          (try-again)
          (begin
            (newline)
            (display ";;; Starting a new problem ")
            (ambeval
             input
             the-global-environment
             ;; ambeval success
             (lambda (val next-alternative)
               (announce-output output-prompt)
               (user-print val)
               (internal-loop next-alternative))
             ;; ambeval failure
             (lambda ()
               (announce-output
                ";;; There are no more values of")
               (user-print input)
               (driver-loop)))))))
  (internal-loop
   (lambda ()
     (newline)
     (display ";;; There is no current problem")
     (driver-loop))))
