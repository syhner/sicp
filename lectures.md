# SICP Lecture Notes

## 1A Overview and Introduction to Lisp

> The real problems come when we try to build very, very large systems … nobody can really hold them in their heads all at once … the only reason that that’s possible is because there are techniques for controlling the complexity of these large systems.

- "computer science" — not about computers in the same way that astronomy is not about telescopes, not a science
- it's easy to confuse the essence of a field with it's tools, it's more about formalising the truths of the field
- computer science is interested in formalising intuitions about 'process'
- declarative knowledge (what is true) i.e. sqrt(x) is the y such that y² = x and y ≥ 0. imperative knowledge (how to find the truth) to find an approximation to sqrt(x) by making a guess and improving until it is good enough

> So in that sense, computer science is like an abstract form of engineering. It’s the kind of engineering where you ignore the constraints that are imposed by reality.

- the fundamental building blocks of a language
  - primitive elements
  - means of combination (of those elements)
  - means of abstraction (to treat these combined objects as elements themselves)
- nested combinations can be modelled as trees, parentheses are just a way to write trees as a linear sequence of characters
- `COND`, `DEFINE`, and `LAMBDA` are not procedures, they are special forms. (`IF` is syntactic sugar over `COND`)
- packaging internals with block structure
- ```
  |                      | procedures    | data   |
  | -------------------- | ------------- | ------ |
  | primitive elements   | + * = /       | 23     |
  | means of combination | () COND       | CONS   | (CONS not mentioned yet)
  | means of abstraction | DEFINE LAMBDA | DEFINE |
  ```

## 1B Procedures and Processes; Substitution Model

- substitution model of evaluation

> The key to understanding complicated things is to know what not to look at, and what not compute, and what not to think.

- linear iteration: time O(n), space: O(1)
- linear recursion: time O(n), space: O(n)
- both can form from a recursive procedure. the iteration has all of its state in explicit variables. the recursion does not.

## 2A Higher-order Procedures

- abstraction as a method of creating shared building blocks
- damping as a signal processing strategy, and abstracting to use it as a building block
- top-down design allows the use of names of procedures that we aren't yet defined
- the rights of first-class citizens
  - to be passed as variables
  - to be passed as arguments to procedures
  - to be returned as values of procedures
  - to be incorporated into data structures

## 2B Compound Data

- seperating use from representation — this is data abstraction

> The real power is that you can pretend that you’ve made the decision and then later on figure out which one is right, which decision you ought to have made. And when you can do that, you have the best of both worlds.

- closure means we can make pairs of pairs, not just pairs of numbers. we say that the means of combination closes over the things that it makes.

> Once you have two things, you have as many things as you want.

- the abstraction should work regardless of unerlying abstractions e.g. rational number implementation doesn't care how pairs are implemented as long as they satisfy their contract of `(car (cons x y)) = x` and `(cdr (cons x y)) = y`.
- pairs can be implemented as procedures, blurring the line between procedures and data. you couldn't tell if they were implemented this way or not.

## 3A Henderson Escher Example

> The set of data objects in Lisp is closed under the operation of forming pairs

- lisp has a convention for representing a sequence as chained pairs, called a list. `car` of the list is the first item, `cdr` of the list is the rest of the list. the `cdr` of the last pair is the empty list aka `nil` which is printed as `()`.

- The difference between merely implementing something in a language and embedding something in the language: you don’t lose the original power of the language e.g. recursion or higher-order procedures

> Lisp is a lousy language for doing any particular problem. What it’s good for is figuring out the right language that you want and embedding that in Lisp. That’s the real power of this approach to design.

> So what you have is, at each level, the objects that are being talked about are the things that were erected at the previous level.

> The design process is not so much implementing programs as implementing languages. And that’s really the power of Lisp.

## 3B Symbolic Differentiation; Quotation

> In order to make a system that’s robust, it has to be insensitive to small changes, that is, a small change in the problem should lead to only a small change in the solution. There ought to be a continuity. The space of solutions ought to be continuous in this space of problems.

- computing symbolic differentiation is easier because they are reduction rules, in integration (the other direction) the rule you should take is ambiguous
- there is a distinction between the function (a black box) and the expression (which can be manipulated)
- quotation creates a referentially opaque context where substitution does not preserve meaning i.e. `(+ 1 2) = 5` but `'(+ 1 2) ≠ '5`

## 4A Pattern Matching and Rule-based Substitution

> Instead of bringing the rules to the level of the computer by writing a program that is those rules ... we're going to bring the computer to the level of us

we want to create an abstraction for matching and instantiation that we can use for any set of rules e.g. derivatives, algebra

### Rules

rules are pairs of `(pattern skeleton)`

- parts of a pattern (what to look for) are pattern variables
  - `foo` matches `foo` (symbols / numbers match to themselves)
  - `(a b)` matches a list with first element is `a` and second element `b` (generalises to lists of any length)
  - `(? name)` matches an expression and binds it to `name`
  - `(?c name)` matches a constant and binds it to `name`
  - `(?v name)` matches a variable and binds it to `name`
- parts of a skeleton (what to produce) are substitution objects
  - `foo` instantiates to `foo` (symbols / numbers instantiate to themselves)
  - `(a b)` instantiates to a list with first element `a` and second element `b` (generalises to lists of any length)
  - `(: name)` instantiates the value of `name` in the dictionary
  - `(: (op a b))` evaluate: look up `op`, `a`, `b` and apply the operator

```scheme
(define algebra-rules
                              ; CONSTANT FOLDING
  '((((? op) (?c e1) (?c e2)) ; (? op) (?c e1) (?c e2)) => (: (op e1 e2))
     (: (op e1 e2)))          ; e.g. (+ 1 2) => 5

                              ; COMMUTATIVITY
    (((? op) (? e1) (?c e2))  ; ((? op) (? e1) (?c e2)) =>  ((: op) (: e2) (: e1))
     ((: op) (: e2) (: e1)))  ; e.g. (+ x 3) => (+ 3 x)

                              ; ADDITIVE IDENTITY
    ((+ 0 (? e))              ; (+ 0 (? e)) => (: e)
     (: e))                   ; e.g. (+ 0 x) => x

                              ; MULTIPLICATIVE IDENTITY
    ((* 1 (? e))              ; (* 1 (? e)) => (: e)
     (: e))                   ; e.g. (* 1 x) => x

                              ; MULTIPLICATIVE ZERO PROPERTY
    ((* 0 (? e))              ; (* 0 (? e)) => 0
     0)))                     ; e.g. (* 0 x) => 0

(define deriv-rules

  '(((dd (?c c) (? v))                   ; DERIVATIVE OF A CONSTANT
    0)                                   ; e.g. (dd 2 x) => 0

    ((dd (?v v) (? v))                   ; DERIVATIVE OF A VARIABLE WITH RESPECT TO ITSELF
     1)                                  ; e.g. (dd x x) => 1

    ((dd (?v u) (? v))                   ; DERIVATIVE OF A VARIABLE WITH RESPECT TO A DIFFERENT VARIABLE
     0)                                  ; e.g. (dd x y) => 0

    ((dd (+ (? x1) (? x2)) (? v))        ; SUM RULE
     (+ (dd (: x1) (: v))                ; e.g. (dd (+ x 2) x) => (+ (dd x x) (dd 2 x)
        (dd (: x2) (: v))))              ; => (dd (* x y) x)

    ((dd (* (? x1) (? x2)) (? v))        ; PRODUCT RULE
     (+ (* (: x1) (dd (: x2) (: v)))     ; e.g. (dd (* x y) x) => (+ (* x (dd y x)) (* (dd x x) x))
        (* (dd (: x1) (: v)) (: x2))))   ; => (+ (* x 0) (* 1 y))

    ((dd (** (? x) (?c n)) (? v))        ; POWER RULE
     (* (* (: n) (** (: x) (: (- n 1)))) ; e.g. (dd (** (+ x 1) 3) x) => (* (* 3 (** (+ x 1) 2))
        (dd (: x) (: v))))))             ; => (dd (+ x 1) x))
```

### Matcher

walks a pattern and expression in parallel, recursively decomposing by matching the `car` then using the result as the dictionary for matching the `cdr`

```scheme
(define (match pat exp dict)
  (cond ((eq? dict 'failed)                  ; (match 'x 'x 'failed)
         'failed)                            ; => 'failed

        ((atom? pat)                         ; (match 'x 'x '())
         (if (and (atom? exp) (eq? pat exp)) ; => '()
             dict
             'failed))

        ((arbitrary-constant? pat)           ; (match '?c 42 '())
         (if (constant? exp)                 ; => '((?c 42))
             (extend-dict pat exp dict)
             'failed))

        ((arbitrary-variable? pat)           ; (match '?v 'x '())
         (if (variable? exp)                 ; => '((?v x))
             (extend-dict pat exp dict)
             'failed))

        ((arbitrary-expression? pat)         ; (match '?e '(+ x 1) '())
         (extend-dict pat exp dict))         ; => '((?e . (+ x 1)))

        ((atom? exp) 'failed)                ; (match '(+ x y) 'x '())
                                             ; => 'failed
        (else
         (match (cdr pat)                    ; (match '(+ ?e 3) '(+ x 3) '())
                (cdr exp)                    ; => '((?e x))
                (match (car pat)
                       (car exp)
                       dict)))))

(match '((? x) (? y) (? y) (? x)) ; pattern
       '(a b b a)                 ; expression
       '((x a)))                  ; dictionary
; => '((x a) (y b))               ; augmented dictionary

(match '((? x) (? y) (? y) (? x)) ; pattern
       '(a b b a)                 ; expression
       '((y a)))                  ; dictionary
; => 'failed

(match '((? op) (? e1) (?c e2)) ; pattern
       '(+ x 3)                 ; expression
       '())                     ; dictionary
; => '((e2 3) (e1 x) (op +))    ; augmented dictionary

(define (empty-dict) '())

(define (extend-dict pat dat dict)
  (let ((name (variable-name pat)))
    (let ((v ((assq name dict))))
      (cond ((not v)
             (cons (list name dat) dict)) ; name not present - add to dictionary
            ((eq? (cadr v) dat) dict)     ; name present with same value - do nothing
            (else 'failed)))))            ; name present with conflicting value - fail

(define (lookup var dict)
  (let ((v (assq var dict)))
    (if (not v) var (cadr v))))
```

### Instantiator

takes a skeleton and the augmented dictionary from the matcher as input, and ouputs an expression

```scheme
(define (instantiate skeleton dict)
  (define (loop s)                       ; avoid passing dict through every recursive call
    (cond ((atom? s) s)
          ((skeleton-evaluation? s)      ; forms beginning with a colon e.g. (: x)
           (evaluate (eval-exp s) dict))
          (else (cons (loop (car s))
                      (loop (cdr s))))))
  (loop skeleton))

(define (evaluate form dict)                      ; (: (op e1 e2)) => (+ 3 4) => 7
  (if (atom? form)
      (lookup form dict)                          ; atoms are looked up from the dictionary
      (apply (eval (lookup (car form) dict)       ; for everything else
                   user-initial-environment)      ; lookup and evaluate the car (operator)
             (mapcar (lambda (v) (lookup v dict)) ; and apply it to the result of
                     (cdr form)))))               ; everything from the cdr (operands)

(instantiate '((: op) (: e2) (: e1))
             '((e2 3) (e1 x) (op +)))
; => '(+ 3 x)                         ; expression
```

### Simplifier

the control structure by which rules are applied to expressions. we want to apply all of the rules to every node. returns a procedure that simplifies an expression using the given rules

```scheme
(define (simplifier the-rules)
  (define (simplify-exp exp)    ; first simplify any subexpressions recursively
    (try-rules                  ; if exp is compound (a list), simplify each part
     (if (compound? exp)        ; if exp is an atom, leave it
         (map simplify-exp exp) ; then hand off to try-rules
         exp)))

  (define (try-rules exp)                           ; try each rule in order
    (define (scan rules)                            ; first get the augmented dictionary from the matcher
      (if (null? rules)                             ; if the matcher fails, try the rest of the rules
          exp                                       ; if the matcher suceeds, instantiate the rule's skeleton
          (let ((dict (match (pattern (car rules))  ; and hand-off to simplify-exp
                             exp                    ; if there are no more rules, return the expression
                             (empty-dict))))
            (if (eq? dict 'failed)
                (scan (cdr rules))
                (simplify-exp
                 (instantiate (skeleton (car rules))
                              dict))))))

    (scan the-rules))

  simplify-exp)

(define algebra-simp (simplifier algebra-rules))
(define deriv-simp (simplifier deriv-rules))

(algebra-simp '(+ (* 1 x) (+ 0 x)))
; => (+ x x)                        ; simplified expression
```

## 4B Generic Operators

alongside vertical abstraction of data usage, we want horizontal abstraction of data representation, for the purposes of:

- independent non-conflicting work (e.g. representing complex numbers in polar or rectangular form)
- efficient representations (e.g. dense polynomial `3x^2 + 2x + 1` as `(3 2 1)` and spare polynomial `x^100 + 3x` as`((100 1) (1 3))`)

### Data-directed programming

> It's called data-directed programming ... the data objects themselves ... are carrying with them the information about how you should operate on them

this is done through the type tag so that generic operations can dispatch on type

### Message passing

if instead data objects carry the operations themselves, then this is another way to organise the system called message passing.

### Example

```scheme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OPERATION TABLE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (make-table)
  (let ((local-table (list '*table*)))
    (define (lookup key-1 key-2)
      (let ((subtable (assoc key-1 (cdr local-table))))
        (if subtable
            (let ((record (assoc key-2 (cdr subtable))))
              (if record (cdr record) #f))
            #f)))
    (define (insert! key-1 key-2 value)
      (let ((subtable (assoc key-1 (cdr local-table))))
        (if subtable
            (let ((record (assoc key-2 (cdr subtable))))
              (if record
                  (set-cdr! record value)
                  (set-cdr! subtable
                            (cons (cons key-2 value)
                                  (cdr subtable)))))
            (set-cdr! local-table
                      (cons (list key-1 (cons key-2 value))
                            (cdr local-table))))))
    (define (reset!)
      (set-cdr! local-table '()))
    (define (dispatch m)
      (cond ((eq? m 'lookup-proc) lookup)
            ((eq? m 'insert-proc!) insert!)
            ((eq? m 'reset-proc!) reset!)
            (else (error 'make-table "unknown operation" m))))
    dispatch))

(define operation-table (make-table))
(define get (operation-table 'lookup-proc))
(define put (operation-table 'insert-proc!))
(define reset (operation-table 'reset-proc!))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (attach-tag type-tag contents)
  (if (eq? type-tag 'scheme-number)
      contents
      (cons type-tag contents)))
(define (type-tag datum)
  (cond ((pair? datum) (car datum))
        ((number? datum) 'scheme-number)
        (else (error 'type-tag "bad tagged datum" datum))))
(define (contents datum)
  (cond ((pair? datum) (cdr datum))
        ((number? datum) datum)
        (else (error 'contents "bad tagged datum" datum))))

(define (apply-generic op . args)
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (if proc
          (apply proc (map contents args))
          (error "No method for these types: APPLY-GENERIC"
                (list op type-tags))))))

; used inside packages for recursive composition of data e.g. (3+2i)/(1+2i)
; this composition could be extended e.g. to matrices with a matrix-pkg
(define (add x y) (apply-generic 'add x y))
(define (sub x y) (apply-generic 'sub x y))
(define (mul x y) (apply-generic 'mul x y))
(define (div x y) (apply-generic 'div x y))
(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))

(define (using . installers)
  (reset)
  (for-each (lambda (f) (f)) installers))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PACKAGES - constructors, selectors, operators
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (scheme-number-pkg)
  (define (tag x) (attach-tag 'scheme-number x))
  ; interface
  (put 'make 'scheme-number (lambda (x) (tag x)))
  (put 'add '(scheme-number scheme-number) (lambda (x y) (tag (+ x y))))
  (put 'sub '(scheme-number scheme-number) (lambda (x y) (tag (- x y))))
  (put 'mul '(scheme-number scheme-number) (lambda (x y) (tag (* x y))))
  (put 'div '(scheme-number scheme-number) (lambda (x y) (tag (/ x y)))))

(define (rational-pkg)
  (define (tag x) (attach-tag 'rational x))
  ; internal
  (define (numer x) (car x))
  (define (denom x) (cdr x))
  (define (make-rat n d)
    (let ((g (gcd n d)))
      (cons (div n g) (div d g))))
  (define (add-rat x y)
    (make-rat (add (mul (numer x) (denom y))
                   (mul (numer y) (denom x)))
              (mul (denom x) (denom y))))
  (define (sub-rat x y)
    (make-rat (sub (mul (numer x) (denom y))
                   (mul (numer y) (denom x)))
              (mul (denom x) (denom y))))
  (define (mul-rat x y)
    (make-rat (mul (numer x) (numer y))
              (mul (denom x) (denom y))))
  (define (div-rat x y)
    (make-rat (mul (numer x) (denom y))
              (mul (denom x) (numer y))))
  ; interface
  (put 'add '(rational rational) (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational) (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational) (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational) (lambda (x y) (tag (div-rat x y))))
  (put 'make 'rational (lambda (n d) (tag (make-rat n d)))))


(define (rectangular-pkg)
  (define (tag x) (attach-tag 'rectangular x))
  ; internal
  (define (real-part z) (car z))
  (define (imag-part z) (cdr z))
  (define (make-from-real-imag x y) (cons x y))
  (define (magnitude z)
    (sqrt (add (square (real-part z))
             (square (imag-part z)))))
  (define (angle z)
    (atan (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a)
    (cons (mul r (cos a)) (mul r (sin a))))
  ; interface
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude '(rectangular) magnitude)
  (put 'angle '(rectangular) angle)
  (put 'make-from-real-imag 'rectangular
    (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular
    (lambda (r a) (tag (make-from-mag-ang r a)))))

(define (polar-pkg)
  (define (tag x) (attach-tag 'polar x))
  ; internal
  (define (magnitude z) (car z))
  (define (angle z) (cdr z))
  (define (make-from-mag-ang r a) (cons r a))
  (define (real-part z) (mul (magnitude z) (cos (angle z))))
  (define (imag-part z) (mul (magnitude z) (sin (angle z))))
  (define (make-from-real-imag x y)
    (cons (sqrt (add (square x) (square y)))
          (atan y x)))
  ; interface selectors
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude '(polar) magnitude)
  (put 'angle '(polar) angle)
; interface constructors
  (put 'make-from-real-imag 'polar
    (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar
    (lambda (r a) (tag (make-from-mag-ang r a)))))

; rather than having a row in the operation table for adding a 'rectangular'
; datum to a 'polar' datum, this introduces a higher-level type 'complex'
(define (complex-pkg)
  (define (tag z) (attach-tag 'complex z))
  ; imported
  (rectangular-pkg)
  (polar-pkg)
  ; internal constructors (from lower representation)
  (define (make-from-real-imag x y)
    ((get 'make-from-real-imag 'rectangular) x y))
  (define (make-from-mag-ang r a)
    ((get 'make-from-mag-ang 'polar) r a))
  ;; internal operations
  (define (add-complex z1 z2)
    (make-from-real-imag (add (real-part z1) (real-part z2))
                         (add (imag-part z1) (imag-part z2))))
  (define (sub-complex z1 z2)
    (make-from-real-imag (sub (real-part z1) (real-part z2))
                         (sub (imag-part z1) (imag-part z2))))
  (define (mul-complex z1 z2)
    (make-from-mag-ang (mul (magnitude z1) (magnitude z2))
                       (add (angle z1) (angle z2))))
  (define (div-complex z1 z2)
    (make-from-mag-ang (div (magnitude z1) (magnitude z2))
                       (sub (angle z1) (angle z2))))
  ; interface selectors
  (put 'real-part '(complex) real-part)
  (put 'imag-part '(complex) imag-part)
  (put 'magnitude '(complex) magnitude)
  (put 'angle '(complex) angle)
  ; interface operations
  (put 'add '(complex complex) (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex) (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex) (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex) (lambda (z1 z2) (tag (div-complex z1 z2))))
  ; interface constructors
  (put 'make-from-real-imag 'complex (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex (lambda (r a) (tag (make-from-mag-ang r a)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; USAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(using scheme-number-pkg complex-pkg)

; helpers around constructors
(define (make-scheme-number n)
  ((get 'make 'scheme-number) n))
(define (make-rational n d)
  ((get 'make 'rational) n d))
(define (make-complex-from-real-imag x y)
  ((get 'make-from-real-imag 'complex) x y))
(define (make-complex-from-mag-ang r a)
  ((get 'make-from-mag-ang 'complex) r a))

(add (make-scheme-number 2)
     (make-scheme-number 3))
; => 5

(add (make-complex-from-real-imag 1 2)
     (make-complex-from-real-imag 3 4))
; => ('complex 'rectangular 4 6)

(mul (make-complex-from-mag-ang 1 2)
     (make-complex-from-mag-ang 3 4))
; => ('complex 'rectangular 3 6)

; mix operand subtypes because they are both of type 'complex'
(add (make-complex-from-real-imag 1 2)
     (make-complex-from-mag-ang 3 4))
; => ('complex 'rectangular -0.9... -0.3...)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EXECUTION FLOW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; execution flow (some steps are not valid substitutions, this is for explanation only)
(real-part (make-complex-from-real-imag 2 3))
; helper around interface constructors
(real-part ((get 'make-from-real-imag 'complex) 2 3))
; complex-pkg interface constructor
(real-part (make-datum 'complex (make-from-real-imag 2 3)))
; complex-pkg internal constructor
(real-part (make-datum 'complex ((get 'make-from-real-imag 'rectangular) 2 3)))
; rectangular-pkg interface constructor
(real-part (make-datum 'complex (make-datum 'rectangular (make-from-real-imag 2 3))))
; rectangular-pkg internal constructor
(real-part (make-datum 'complex (make-datum 'rectangular (cons 2 3))))
; helper around apply-generic
(apply-generic 'real-part (make-datum 'complex (make-datum 'rectangular (cons 2 3))))
; complex-pkg interface selector
((get 'real-part '(complex)) (datum-contents (make-datum 'complex (make-datum 'rectangular (cons 2 3)))))
; complex-pkg internal selector
(apply-generic 'real-part (make-datum 'rectangular (cons 2 3)))
; rectangular-pkg interface selector
((get 'real-part '(rectangular)) (datum-contents (make-datum 'rectangular (cons 2 3))))
; rectangular-pkg internal selector
(car (cons 2 3))
; primitive
2
```

## 5A Assignment, State, and Side-effects

### Assignment

- functional programs are a kind of encoding of mathematical truths which can be understood by substitution (i.e. simplifying a mathematical expression which preserves truth)
- assigment (e.g. `(set! variable value)`) produces a moment in time which has a before and after. this is where the substitution model breaks down.

### Environment model

environments are a way of doing substitutions virtually

- an **environment** is a sequence of frames (pointer to a **frame**)
- each frame has
  - a table of **bindings** of associations of variables to values
  - a pointer to it's enclosing/parent environment
- the value of a variable is a given by the first frame that has it's binding. bindings in later frames are **shadowed**. if there is no binding then it is **unbound**.
- there is a global environment, consisting of a single frame (with no enclosing environment) that includes values for the symbols associated with primitive procedures (e.g. `+` is bound to the primitive addition procedure)
 
- a variable `v` is bound in an expression `E` if the meaning of `E` is unchanged after replacing all occurenced of `v` by some other variable `w` not already occuring in `E` e.g. in `(λ(x) (* x y))`
  - `x` is bound (since it could be replaced by `w` without changing meaning)
  - `y` and `*` is free/unbound
  - `(* x y)` is the **scope** of `x` (where it is defined)
- a quantifier is a symbol that binds a variable e.g. `λ` (in lisp), `∃`, `∀`, `∫`
- ??? something about lambda binding and creating a socpe

a procedure object is a pointer to a pair of
  - the code of the procedure
  - the enclosing environment

to evaluate a `lambda` expression
  1. construct a new frame (whose parent is the procedure's environment)
  2. bind the formal parameters of the procedure (to the arguments of the call)
  3. evaluate the procedure body (in the context of the new environment)

### Computational objects

```scheme
; add a binding in the global environment from `make-counter` to the procedure body `lambda (n) (...)`
(define make-counter
  (lambda (n)
    (lambda ()
      (set! n (inc n))
      n)))

; add more bindings to the global environment
(define c1 (make-counter 0))
(define c2 (make-counter 10))

; there are 2 environments where `n` is different. `n` is not in the global environment
(c1) ; => 1
(c1) ; => 2
(c2) ; => 11
(c2) ; => 12
```

- an action `A` has an effect on an object `x` if some property which was true of `x` before `A` becomes false after
- two objects are considered the same if any action that has an effect on one also has the same effect on the other

assignment can allow abstractions to be created that would otherwise be leaky (e.g. random numbers not leaking out to monte carlo simulation abstraction)

## 5B Computational Objects

because we have mutation, we need `cons` to have identity so that it is more than just a sum of it's parts

```scheme
(define a (cons 1 2))
(define b (cons a 1))
(set-car! a 3)
(caar b) ; should evaluate to 3
```

we can still define `cons`, `car` and `cdr` as procedures, even if we need to support mutation

```scheme
(define (cons x y)
  (lambda (m)
    (m x
       y
       (lambda (n) (set! x n))
       (lambda (n) (set! y n)))))
       
(define (car x)
  (x (lambda (a d sa sd) a)))
(define (cdr x)
  (x (lambda (a d sa sd) d)))

(define (set-car! x v)
  (x (lambda (a d sa sd) (sa v))))
(define (set-cdr! x v)
  (x (lambda (a d sa sd) (sd v))))
```

## 6A Streams, Part 1

### Motivation

```scheme
(define (sum-odd-squares tree)
  (if (leaf-node? tree)
      (if (odd? tree)
          (square tree)
          0)
      (+ (sum-odd-squares (left-branch tree))
         (sum-odd-squares (right-branch tree)))))

(define (odd-fibs n)
  (define (next k)
    (if (> k n)
        '()
        (let ((f (fib k)))
          (if (odd? f)
              (cons f (next (1+ k)))
              (next (1+ k))))))
  (next 1))
```

- `sum-odd-squares`: enumerate leaves -> filter odd -> map square -> accumulate sum
- `odd-fibs`: enumerate interval -> map fib -> filter odd -> accumulate list

we want the commonality between these procedures to be evident

> Going back to this fundamental principle of computer science that in order to control something, you need the name of it.

### Defining streams

the arrows between stages can be represented by streams which have the same axioms as `cons`, `car` and `cdr`

- constructors: `(cons-stream x y)` and `the-empty-stream`
- selector: `(head (cons-stream x y)) => x`
- selector: `(tail (cons-stream x y)) => y`

and we have higher-order procedures defined similarly to those for lists e.g. enumerate-interval, enumerate-tree, filter, map, accumulate

```scheme
(define (map-stream proc s)
  (if (empty-stream? s)
      the-empty-stream
      (cons-stream (proc (head s))
                   (map-stream proc (tail s)))))
```

now we can represent the problem with streams to reveal the commonality

```scheme
(define (sum-odd-squares tree)
  (accumulate +
              0
              (map square
                   (filter odd
                           (enumerate-tree tree)))))
(define (odd-fibs n)
  (accumulate cons
              '()
              (filter odd
                      (map fib
                           (enumerate-interval 1 n)))))
```

now we have **convential interfaces** for a wide array of problems.


```scheme
(define (flatten s)
  (accumulate append-stream
              the-empty-stream
              s))

(define (flatmap f s)
  (flatten (map f s)))

; all pairs 0<j<i<=N s.t. i+j is prime
(define (prime-sum-pairs n)
  (map
   (lambda (p)
     (list (car p) (cadr p) (+ (car p) (cadr p))))
   (filter
    (lambda (p)
      (prime (+ (car p) (cadr p))))
    (flatmap
     (lambda (i)
       (map
        (lambda (j) (list i j))
        (enumerate-interval 1 (-1+ i))))
     (enumerate-interval 1 n)))))
```

we see that flatmap takes the place of nested loops in other languages. this can be made more readable with syntactic sugar

```scheme
(define (prime-sum-pairs n)
  (collect
   (list i j (+ i j))
   ((i (enumerate-interval 1 n))
    (j (enumerate-interval 1 (-1+ i))))
   (prime? (+ i j))))
```

### Streams are delayed lists

we want the stream to compute itself incrementally (on-demand), so that we only need to process as much of the stream as necessary (as opposed to the whole stream at each stage). we want expressions that can be `delay`ed to create a promise (delayed procedure) which is only computed once `force`d

```scheme
(define (cons-stream x y) (cons x (delay y)))
(define (head s) (car s))
(define (tail s) (force (cdr s)))
(define (delay expr) (lambda () expr))
(define (force p) (p))
```

> The thing that delay did for us was to de-couple the apparent order of events in our programs from the actual order of events that happen in the machine

we can improve efficiency of `delay` by memoization, so that any re-computation of the same promise is cached

```scheme
(define (delay expr) (memo-proc (lambda () expr)))

(define (memo-proc proc)
  (let ((already-run? nil) (result nil))
    (lambda ()
      (if (not already-run?)
          (sequence (set! result (proc))
                    (set! already-run? (not nil))
                    result)
          result))))
```

## 6B Streams, Part 

### Infinite sreams

so far we don't compute elements until we ask for them e.g.

```scheme
(define (nth-stream n s)
  (if (= n 0)
      (head s)
      (nth-stream (-1+ n) (tail s))))
```

we can also have infinite streams

```scheme
(define (integers-from n)
  (cons-stream n (integers-from (1+ n))))
(define integers (integers-from 1))
```

### Defining streams implicitly

with some helpers

```scheme
(define (add-streams s1 s2)
  (cond ((empty-stream? s1) s2)
        ((empty-stream? s2) s1)
        (else (cons-stream (+ (head s1) (head s2))
                           (add-streams (tail s1) (tail s2))))))
(define (scale-stream c s)
  (map-stream (lambda (x) (* x c)) s))
```

we can define streams all at once

```scheme
(define ones (cons-stream 1 ones))
(define integers (add-streams integers ones))

(define (integral s initial-value dt)
  (define int
    (cons-stream initial-value
                 (add-streams (scale-stream dt s) int)))
  int)

(define fibs
  (cons-stream 0
               (cons-stream 1
                            (add-streams fibs (tail fibs)))))
```

### Explicit delay

suppose we want to solve `y'=y^2` using `y(0)=1` and `dt=0.001`

```scheme
(define y (integral dy 1 0.001))
(define dy (map-stream square y))
```

this doesn't work because `y` and `dy` each need the other defined first. we need streams to be able to get their first element. we can fix this in the same way that `cons-stream` allows self-referencing — by introducing a delay.

```scheme
(define (integral delayed-s initial-value dt)
  (define int
    (cons-stream initial-value
                 (let ((s (force delayed-s)))
                   (add-streams (scale-stream dt s) int))))
  int)

(define y (integral (delay dy) 1 0.001))
(define dy (map-stream square y))
```

### Normal-order evaluation

- we've been divorcing time in the program from time in the computer
- as in the previous example, sometimes you have to write explicit delays. in large programs it's difficult to see where these are needed.
- the way around this is to make all arguments delayed. this is normal-order evaluation. we wouldn't need `cons-stream` because it would be the same as `cons`. tradeoffs:
  - language becomes less expressive e.g. iterative procedures would not be possible
  - dragging tails of thunks
  - doesn't mix with side effects. with streams we abandon time but side-effects require time. functional programming languages avoid this issue by disallowing side effects. e.g.

```scheme
(define x 0)
(define (id n) (set! x n) n)
(define (inc a) (1+ a))
(define y (inc (id 3)))
x ; 0
y ; 4
x ; 3 (after y is evaluated)
```

### Avoiding mutable state

- instead of generating random numbers with internal state, we could create an infinite stream of random numbers
- instead of bank accounts using message passing, they could process a stream of transactions
- the purely functional programming model seems to break down when we want to model sharing i.e. a shared bank account. the request streams would have to merged somehow.
- there is a conflict between objects/state/time and delays/streams/FP that seems to be about different ways of viewing the world

## 7A Metacircular Evaluator, Part 1

### Eval and Apply

```scheme
(define eval
  (lambda (exp env)
    (cond
      ; special forms
      ((number? exp) exp)                 ; 3 -> 3
      ((symbol? exp) (lookup exp env))    ; x -> 3
      ((eq? (car exp) 'quote) (cadr exp)) ; 'foo -> (quote foo)
      ((eq? (car exp) 'lambda)            ; (λ(x) (+ x y)) -> (closure ((x) (+ x y)) <env>)
       (list 'closure (cdr exp) env))
      ((eq? (car exp) 'cond)              ; (cond (e1 p1) (e2 p2) ...) ->
       (evcond (cdr exp) env))
      ; default combination
      (else                               ; (+ x 3)
        (apply (eval (car exp) env)        
               (evlist (cdr exp) env))))))

(define apply
  (lambda (proc args)
    (cond
      ; primitive procedures
      ((primitive? proc)                    ; (+ 1 2) -> 3
       (apply-primop proc args))
      ; compound procedures / closures
      ((eq? (car proc) 'closure)            ; ((lambda (x) (+ x y)) 3) ->
       (eval                                ; eval body in extended env
         (cadadr proc)
         (bind (caadr proc)                 ; formal params, e.g. (x)
               args                         ; actual args, e.g. (3)
               (caddr proc))))              ; saved environment from closure
      (else
        (error "Unknown procedure" proc)))))

(define evlist
  (lambda (l env)
    (cond
      ; base case
      ((eq? l '()) '())                     ; no arguments -> ()
      ; evaluate each argument
      (else (cons (eval (car l) env)        ; evaluate first arg
                  (evlist (cdr l) env)))))) ; evaluate rest

(define evcond
  (lambda (clauses env)
    (cond
      ; no clauses left
      ((eq? clauses '()) '())
      ; explicit else clause
      ((eq? (caar clauses) 'else)
       (eval (cadar clauses) env))
      ; test failed, try next clause
      ((false? (eval (caar clauses) env))
       (evcond (cdr clauses) env))
      ; test succeeded
      (else
       (eval (cadar clauses) env)))))

(define bind
  (lambda (vars vals env)
    (cons (pair-up vars vals) ; extend env with ((x . 1) (y . 2) ...)
          env)))              ; new frame goes in front

(define pair-up
  (lambda (vars vals)
    (cond
      ; no variables left
      ((eq? vars '())
       (cond ((eq? vals '()) '())           ; matched exactly
             (else (error TMA))))           ; too many arguments
      ; no values left
      ((eq? vals '()) (error TFA))          ; too few arguments
      ; pair first var with first value
      (else (cons (cons (car vars)          ; (x . 1)
                        (car vals))    
                  (pair-up (cdr vars)       ; recurse on rest
                           (cdr vals)))))))

(define lookup
  (lambda (sym env)
    (cond
      ; no frames left
      ((eq? env '()) (error UBV))    ; unbound variable
      ; search current frame first
      (else
       ((lambda (vcell)
          (cond
            ((eq? vcell '())         ; not in this frame
             (lookup sym (cdr env))) ; try outer environment
            (else (cdr vcell))))     ; found binding, return value
        (assq sym (car env)))))))

(define assq
  (lambda (sym alist)
    (cond
      ; not found in this frame
      ((eq? alist '()) '())
      ; found matching binding
      ((eq? sym (caar alist))
       (car alist))               ; return (sym . val)
      ; keep searching
      (else
       (assq sym (cdr alist))))))
```

```scheme
(eval '((((lambda (x) (lambda (y) (+ x y))) 3) 4)) env)

(apply
  (eval '(((lambda (x) (lambda (y) (+ x y))) 3)) <ep>)
  (evlist '(4) <ep>))

(apply
  (eval '((lambda (x) (lambda (y) (+ x y))) 3) <ep>)
  (cons (eval '4 <ep>)
        (evlist '() <ep>)))

(apply
  (eval '((lambda (x) (lambda (y) (+ x y))) 3) <ep>)
  (cons 4 '()))

(apply
  (eval '((lambda (x) (lambda (y) (+ x y))) 3) <ep>)
  '(4))

(apply
  (apply
    (eval '(lambda (x) (lambda (y) (+ x y))) <ep>)
    '(3))
  '(4))

(apply
  (apply '(closure ((x) (lambda (y) (+ x y))) <ep>)
         '(3))
  '(4))

(apply
  (eval '(lambda (y) (+ x y)) <e1>)
  '(4))

(apply '(closure ((y) (+ x y)) <e1>)
       '(4))

(eval '(+ x y) <e2>)

(apply
  (eval '+ <e2>)
  (evlist '(x y) <e2>))

(apply '+ '(3 4))

7
```

- eval produces a procedure and arguments for apply
- apply produces an expression and environment for eval

### Definitions

> Defintions are inessential in a mathematical sense for doing all the things we need to do for computing

```
1. 2x + 2y = 6
2. x + y = 3
3. x - y = 1
4. x - y = 2
```

- 1 and 2 have an infinite number of solutions
- 2 and 3 have a unique solution in `<x,y>`
- 3 and 4 have no solutions

> The number of solutions is not in the form of the equations. All three sets have the same form. The number of solutions is in the content ... I can't tell by the form of a definition if it makes sense, only by its detailed content.

### Infinite loops

the simplest infinite loop

```scheme
((lambda (x) (x x)) (lambda (x) (x x)))
```

Y combinator (fixed-point combinator) — when applied to some function, produces the object which is the fixed-point of that function if it exists

```scheme
(define Y
  (lambda (f)
    ((lambda (x) (f (x x)))
     (lambda (x) (f (x x))))))

; (Y f)
; => ((lambda (x) (f (x x)))
;     (lambda (x) (f (x x))))
; => (f ((lambda (x) (f (x x))
;        (lambda (x) (f (x x))))))
; => (f (Y f))
```

> What lisp is is the fixed point of the process which says, if i knew what Lisp was and substituted it in for eval and apply and so on, on the right hand sides of all those recursion equations then ... the left hand side would also be Lisp.

## 7B Metacircular Evaluator, Part 2

### Adding language features

when you make syntactic specifications, it's important that it's unambiguous (syntactically distinguishable). neither of them should be confused with a representation we already have.

```scheme
; fixed number of named formal parameters
(lambda (x y z) ())

; fixed number of named formal parameters followed by something to pick up the rest of them
(lambda (x . y) ())

; list of all the arguments which will be named against the formal argument x
((lambda x x) 'p 'q 'r) 
```

to support these, we modify `pair-up`

```diff       
(define pair-up
  (lambda (vars vals)
    (cond
      ((eq? vars '())
       (cond ((eq? vals '()) '())
             (else (error TMA))))
+     ((symbol? vars)               ; symbolic tail
+      (cons (cons vars vals) '()))
      ((eq? vals '()) (error TFA))
      (else
       (cons (cons (car vars) (car vals))
             (pair-up (cdr vars)
                      (cdr vals)))))))
```

### Dynamic binding

dynamic binding: a free variable in a procedure has its value defined inthe chain of callers, rather than where the procedure is defined

```scheme
(define x 10)

(define f (lambda () x))

(define g (lambda (x) (f)))

(g 20)
; dynamic binding => 20
; lexical binding (scheme) => 10
```

to support this

```diff
(define eval
  (lambda (exp env)
    (cond
      ((number? exp) exp)
      ((symbol? exp) (lookup exp env))
      ((eq? (car exp) 'quote) (cadr exp))
-     ((eq? (car exp) 'lambda)
-      (list 'closure (cdr exp) env))
+     ((eq? (car exp) 'lambda) exp)        ; if we don't have to have the environment be the environment of definition for a procedure, the procedure need not capture the environment at the time it's defined  
      ((eq? (car exp) 'cond)
       (evcond (cdr exp) env))
      (else
       (apply (eval (car exp) env)
-             (evlist (cdr exp) env))))))
+             (evlist (cdr exp) env)      ; apply must be able to get the environment of the caller
+             env)))))

(define apply
- (lambda (proc args)
+ (lambda (proc args env)
    (cond
      ((primitive? proc)
       (apply-primop proc args))
-     ((eq? (car proc) 'closure)
+     ((eq? (car proc) 'lambda)
       (eval
         (cadadr proc)
         (bind (caadr proc)
               args
-              (caddr proc))))
+              env)))
      (else
       (error "Unknown procedure" proc)))))
```

> The reason why the first Lisps were implemented this way, is it's the sort of obvious, accidental implementation. And, of course, as usual, people got used to it and liked it. And there were some people said, this is the way to do it. Unfortunately that causes some serious problems. The most important, serious problem in using dynamic binding is that there's a modularity crisis that's involved in it. If two people are working together on some big system, then an important thing to want is that the names used by
each one don't interfere with the names of the other. It's important that when I invent some segment of code that no one can make my code stop working by using my names that I use internal to my code, internal to his code. However, dynamic binding violates that particular modularity constraint in a clear way ... So I no longer have a quantifier ... The lambda symbol is supposed to be a quantifier

> The thing is that returning procedures as values cover all of those problems. And so it's the simplest mechanism that gives you the best modularity, gives you all of the known modularity mechanisms.

### Delayed arguments

```scheme
(define (unless predicate consequent alternative)
  (cond ((not predicate) consequent)
    (else alternative)))

(unless (= 1 0) 2 (/ 1 0))
```

we want this to evaluate to 2, i.e.

```scheme
(cond ((not (= 1 0)) 2)
      (else (/1 0)))
; => 2
```

however the alternative `(/ 1 0)` will evaluate first due to applicative order evaluation, which will result in an error. this would not have happened if the substitution to `cond` worked. we will add a language feature for delayed function arguments so that we can

```scheme
(define (unless predicate (name consequent) (name alternative))
  (cond ((not predicate) consequent)
    (else alternative)))
```

```diff
(define eval
  (lambda (exp env)
    (cond
      ((number? exp) exp)
      ((symbol? exp) (lookup exp env))
      ((eq? (car exp) 'quote) (cadr exp))
      ((eq? (car exp) 'lambda)
       (list 'closure (cdr exp) env))
      ((eq? (car exp) 'cond)
       (evcond (cdr exp) env))
      (else
-      (apply (eval (car exp) env)
-             (evlist (cdr exp) env))))))
+      (apply (undelay (eval (car exp) env))
+             (cdr exp)
+             env)))))

(define apply
- (lambda (proc args)
+ (lambda (proc args env)
    (cond
      ((primitive? proc)
-      (apply-primop proc args))
+      (apply-primop proc
+                    (evlist args env)))     ; primitive operations should get the actual operands by forcing
      ((eq? (car proc) 'closure)
       (eval
         (cadadr proc)
-        (bind (caadr proc)
-              args
+        (bind (vnames (caadr proc))         ; strip off declarations to get names of variables
+              (gevlist (caadr proc)         ; process declarations, deciding which operands to evaluate or encapsulate with delays
+                       args
+                       env)
               (caddr proc))))
      (else
       (error "Unknown procedure" proc)))))

(define evlist
  (lambda (l env)
    (cond
      ((eq? l '()) '())
-     (else (cons (eval (car l) env)
+     (else (cons (undelay (eval (car l) env))
                  (evlist (cdr l) env))))))

+ (define gevlist
+   (lambda (vars exps env)
+     (cond
+       ((eq? exps '()) '())
+       ((symbol? (car vars))
+        (cons (eval (car exps) env)
+              (gevlist (cdr vars)
+                       (cdr exps)
+                       env)))
+       ((eq? (caar vars) 'name)
+        (cons (make-delay (car exps) env)
+              (gevlist (cdr vars)
+                       (cdr exps)
+                       env)))
+       (else 
+        (error "Unknown procedure")))))

(define evcond
  (lambda (clauses env)
    (cond
      ((eq? clauses '()) '())
      ((eq? (caar clauses) 'else)
       (eval (cadar clauses) env))
-     ((false? (eval (caar clauses) env))
+     ((false? (undelay (eval (caar clauses) env)))) ; conditionals have to know whether the answer is true or false
       (evcond (cdr clauses) env))
      (else
       (eval (cadar clauses) env)))))

+ ; data-structures which contain an expression, environment, and a thunk type
+ (define make-delay
+   (lambda (exp env)
+     (cons 'thunk (cons exp env))))
+ 
+ ; recursively undelay thunks until they are no longer thunks
+ (define (undelay v)
+   (cond ((pair? v)
+          (cond ((eq? (car v) 'thunk)
+                 (undelay
+                  (eval (cadr v)
+                        (cddr v))))
+                (else v)))
+         (else v)))
```

## 8A Logic Programming, Part 1

> The other thing that you saw is once you have the interpreter in your hands, you have all this power to start playing with the language. So you can make it dynamically scoped, or you can put in normal order evaluation, or you can add new forms to the language, whatever you like. Or more generally, there's this notion of metalinguistic abstraction, which says that part of your perspective as an engineer, as a software engineer, but as an engineer in general is that you can gain control of complexity by inventing new languages sometimes. See, one way to think about computer programming is that it only incidentally has to do with getting a computer to do something. Primarily what a computer program has to do with, it's a way of expressing ideas with communicating ideas. And sometimes when you want to communicate new kinds of ideas, you'd like to invent new modes of expressing that.

even in a very different language you can still have eval unwinding the means of abstraction, and apply unwinding the means of combination

in logic programming we have declarative knowledge of relations which don't have directionality:
- express what is true e.g.
  - lists x and y merge-to-form list z when z is the ordered merge of x and y
- check what is true e.g.
  - does (1 3) and (2 5) merge-to-form (1 2 3 5)
- find out what is true (imperative knowledge has directionality, so each of those would have to be it's own procedure) e.g.
  - (1 3) and (2 5) merge-to-form ?
  - (1 3) and ? merge-to-form (1 2 3 5)
  - ?x and ?y merge-to-form (1 2 3 5)

we have a collection of facts

```scheme
(job (Alice) (computer programmer))
(supervisor (Alice) (Bob))

(job (Bob) (computer technician trainee))
(supervisor (Bob) (Charlie))

(job (Charlie) (computer programmer))
```

and only one primitive: a query

```scheme
; check what is true
(job Alice (computer programmer))
; matches
(job Alice (computer programmer))

; find out what is true
(job ?x (computer programmer))
; matches
(job (Alice) (computer programmer))
(job (Charlie) (computer programmer))

; find out what is true
(job ?x (computer ?type))
; doesn't match
(job (Bob) (computer technician trainee))

; find out what is true
(job ?x (computer . ?type))
; matches
(job (Bob) (computer technician trainee))
```

means of combination: logical operations (`not`, `and`, `or`), `lisp-value`

```scheme
; the shared `?x` must refer to the same person
(and (job ?x (computer . ?type))
     (not (supervisor ?x ?z))
     (salary ?x ?annum)
     (lisp-value > ?annum 30000)) ; call underlying lisp inside query
```

means of abstraction: rules (rule-body ⇒ rule-conclusion)

```scheme
(rule
  ; rule-conclusion
  (bigshot ?x ?department)
  ; rule-body
  (and
    (job ?x (?department . ?y))
    (not (and (supervisor ?x ?z)
              (job ?z (?department . ?w))))))
```

now with `merge-to-form`

```scheme
(rule (merge-to-form () ?y ?y))
(rule (merge-to-form ?y () ?y))

(rule
  (merge-to-form (?a . ?x) (?b . ?y) (?b . ?z))
  (and
    (merge-to-form (?a . ?x) ?y ?z)
    (lisp-value > ?a ?b)))

(rule
  (merge-to-form (?a . ?x) (?b . ?y) (?a . ?z))
  (and
    (merge-to-form ?x (?b . ?y) ?z)
    (lisp-value > ?b ?a)))
```

## 8B Logic Programming, Part 2

### Implementation

the logic programming language is implemented with a pattern matcher

queries implementation: take the input dictionary and for each fact in the database, call the matcher with (pattern fact dictionary). for each match, output an extended dictionary

importantly, combined queries have the same shape as individual queries: 2 inputs streams (which can be fanned out to subqueries) and 1 output stream, and so we have closure and achieved a means of abstraction — rules. e.g.

```scheme
(rule (boss ?z ?d)
  (and (job ?x (?d . ?y))
       (supervisor ?x ?z)))

(boss ?who computer)
```

a simple implementation would look like

```
database stream        input stream
        |                    | ((?d computer) (?z ?who))
   +-------------------------+--------------------------------------------------------------------+
   |    |                    |                                                    (boss ?z ?d)    |
   |    |                    v                                                                    |
   |    |         +--------------------+                                                          |
   |    |-------->| (job ?x (?d . ?y)) |                                                          |
   |    |         +--------------------+                                                          |
   |    |                    | ((?x Alice) (?d computer) (?y (programmer)))                       |
   |    |                    | ((?x Bob) (?d computer) (?y (technician trainee)))                 |
   |    |                    | ((?x Charlie) (?d computer) (?y (programmer)))                     |
   |    |                    v                                                                    |
   |    |         +--------------------+                                                          |
   |    |-------->| (supervisor ?x ?z) |                                                          |
   |              +--------------------+                                                          |
   |                         | ((?x Alice) (?d computer) (?y (programmer)) (?z Bob))              |
   |                         | ((?x Bob) (?d computer) (?y (technician trainee)) (?z Charlie))    |
   +-------------------------+--------------------------------------------------------------------+
                             |
                             v
                       output stream
```

our matcher can handle matching a pattern against data (e.g. `(?d computer)`). to match a pattern against a pattern (e.g. `(?who ?z)`) we need a **unifier** (it should also support local variables to avoid naming conflicts i.e. with an environment model). e.g.

```scheme
(unify '(?x ?x)
       '((a ?y c) (a b ?z)))
; => ((?x (a b c))
;     (?y b)
;     (?z a))

(unify '(?x ?x)
       '((?y a ?w) (b ?v ?z)))
; => ((?y b)
;     (?v a)
;     (?w ?zl)
;     (?x (b a ?w)))

(unify '(?x ?x)
       '(?y (a . ?y)))
; => ((?x y)
;     (?y (a a a ...))
```

to apply a rule: evaluate the rule body relative to an environment formed by unifying the rule conclusion with the given query

to apply a procedure: evaluate the procedure body relative to an environment formed by binding the procedure parameters to the arguments

this is very similar to the eval/apply loop, even though there are no procedures in the logic programming language. this is because the means of combination and means of abstraction unwind in a similar way

### Differences to logic

unlike logic, our implementation is not commutative e.g. `(and p q)` ≠ `(and q p)` and we can get infinite loops

```scheme
; checks supervisor, then recurses on smaller subproblem
(rule (outranked-by ?s ?b)
  (or (supervisor ?s ?b)
      (and (supervisor ?s ?m)
           (outranked-by ?m ?b))))

; recurses, then checks supervisor. so can enter infinite loop
(rule (outranked-by ?s ?b)
  (or (supervisor ?s ?b)
      (and (outranked-by ?m ?b)
           (supervisor ?s ?m))))
```

different answers

```scheme
(Greek Socrates)
(Greek Plato)
(Greek Zeus)
(god Zeus)

(rule (mortal ?x) (human ?x))
(rule (fallible ?x) (human ?x))

(rule (human ?x)
  (and (Greek ?x)
       (not (god ?x))))

(rule (address ?x Olympus)
  (and (Greek ?x)
       (god ?x)))

(rule (perfect ?x)
  (and (not (mortal ?x))
            (fallible ?x)))

(and (address ?x ?y)
     (perfect ?x))
; => (Olympus)

(and (perfect ?x)
     (address ?x ?y))
; => ()
; `not` (through `perfect`) can't generate values, it only filters them out
; a way around this is to do `not` filtering at the end
```

and incorrect conclusions because `not` works under the **closed world assumption**: anything not deducible from known facts is not true e.g. not knowing anything about x implies 'not x'. this is problematic because this would extend to 'not not x', and so x would be true without any knowledge

sometimes we want the closed world assumption so that we don't have to explicitly declare all of the things which are not true. e.g. reasoning about connectivity: let x<>y denote a connection between x and y, A<>B and B<>C. we want the A<>C check to fail. this is even more poignant if we have many nodes in the graph for which there would be lots of 'not' truths.

## 9A Register Machines

### Transforming lisp programs into hardware

a program can be described as a machine

single core processor computers will have 2 parts
- datapaths: registers (that remember things) and operations
- (finite state machine) controller: sequences operations

> Use what you learn from studying the problem you want to solve to put in the mechanisms needed to solve it in the computer you're building, no more no less. In may be that the problem you're trying to solve is everybody's problem, in which case you have to build in a universal interpreter of some language. But you shouldn't put any more in than required to build the universal interpeter.

### Linear iteration

```scheme
(define (gcd a b)
  (if (= b 0)
      a
      (gcd (remainder a b))))
```

any individual part may itself be a machine (e.g. `remainder`)

```
         DATAPATHS         |          CONTROLLER          
----------------------------------------------------------
        START              |
          |                | 
+-------->|                |
|         v                |
|     +--------+ YES       |
| (1) | b = 0? | --> DONE  |
|     +--------+           |
|         | NO             |
|         v                |
|     +--------+           |  +---+ (3) +---+     +------+
| (2) | t <- r |           |  | a | <-- | b | --> | b=0? |
|     +--------+           |  +---+     +---+     +------+
|         |                |    \        / ^        (1)
|         v                |     \      /  |
|     +--------+           |      |    |   |
| (3) | a <- b |           |      V    V   |
|     +--------+           |    +-------+  |
|         |                |     \ rem /   | (4)
|         v                |      +---+    |
|     +--------+           |        | (2)  |
| (4) | b <- t |           |        V      |
|     +--------+           |      +---+    |
|         |                |      | t |----+
+---------+                |      +---+
```

written representation (in a language embedded in lisp)

machine instructions
- `assign`: put a value into a register
- `goto`: unconditional jump to a label (e.g. `loop`, `done`)

```scheme
(define-machine gcd
  (registers a b t)
  (controller
    loop (branch (zero? (fetch b)) done)
         (assign t (remainder (fetch a) (fetch b)))
         (assign a (fetch b))
         (assign b (fetch t))
         (goto loop)
    done))
```

adding IO

```diff
(define-machine gcd
  (registers a b t)
  (controller
+   main (assign a (read))
+   main (assign b (read))
    loop (branch (zero? (fetch b)) done)
         (assign t (remainder (fetch a) (fetch b)))
         (assign a (fetch b))
         (assign b (fetch t))
         (goto loop)
-   done))
+   done (perform (print (fetch a)))
+    (goto main)))

which can also be represented in the datapaths / controller
```

### Linear recursion

```scheme
(define (factorial n)
  (if (= n 1)
      1
      (* n (factorial (- n 1)))))
```

since this is not an iteration, we require a factorial machine which includes itself to infinity. instead we introduce into the datapaths an in memory LIFO stack to capture two things
- procedure call values
- continue register values — can be assigned two states: `aftr` and `done` in order to know when to recurse vs when we are done

we introduce instructions

- `save`: push a value from a register into the stack
- `restore`: pop a value from the stack into a register
- `branch`: conditional jump to label

```scheme
(define-machine factorial
  (registers n value continue)
  (controller
    (assign continue done)
    loop (branch (= 1 (fetch n)) base)
         (save continue) 
         (save n)
         (assign n (-1+ (fetch n)))
         (assign continue aftr)
         (goto loop)
    aftr (restore n)
         (restore continue)
         (assign value (* (fetch n) (fetch value)))
         (goto (fetch (continue)))
    base (assign value (fetch n))
         (goto (fetch continue))
    done))
```

the stack will build up to

```
2 (last)
aft
3
done (first)
```

which will unwind into the value register

### Tree recursion

```scheme
(define (fib n)
  (if (< n 2)
      1
      (+ (fib (- n 1))
         (fib (- n 2)))))
```

we use a label for each recursive case: `(fib (- n 1))` and `(fib (- n 2))`

```scheme
(define-machine fibonacci
  (registers n value continue)
  (controller
    (assign continue done)
    loop                                     ; n contains arg, continue is recipient
      (branch (< (fetch n) 2) base)
      (save continue)
      (assign continue after-fib-n-1)
      (save n)
      (assign n (- (fetch n) 1))
      (goto loop)
    after-fib-n-1
      (restore n)
      (restore continue)                     ; can be removed
      (assign n (- (fetch n) 2))
      (save continue)                        ; can be removed
      (assign continue after-fib-n-2)
      (save val)
      (goto loop)                            ; compute (fib (- n 2))
    after-fib-n-2
      (assign n (fetch val))                 ; (fib (- n 2))
      (restore val)                          ; matches (save val) in after-fib-n-1
      (restore continue)                     ; matches (save continue) in loop
      (assign val (+ (fetch val) (fetch n)))
      (goto (fetch continue))
    base
      (assign val (fetch n))
      (goto (fetch continue))
    done
  ))
```

the two instructions indicated can be removed since the `restore` then `save` leaves the stack unchanged, and the `continue` register value is not used in between. this is an example of peephole optimisation.

## 9B Explicit-control Evaluator

> LISP is not good for solving any particular problems. What LISP is good for is contructing within it the right language to solve the problems you want to solve.

> If we implement lisp in terms of a register machine, then everything ought to become, at this point, completely concrete. All the magic should go away.

```
+--> user
|     |
|     | characters
|     v
|   reader ----> list structure memory
|     |
|     | list structure
|     v
|    eval -----> primitive operations
|     |
|     | answer
|     v
|   printer
+-----+
```

register usage in evaluator machine

- `exp` - expression to be evaluated (eval)
- `env` - evaluation environment (eval)
- `fun` - procedure to be applied (apply)
- `argl` - list of evaluated arguments (apply)
- `continue` - place to go to next (recursion/done)
- `val` - result of evaluation
- `unev` - temporary register for expressions

> A lot of people think [that] the reason you need a stack and recursion in an evaluator is because you might be evaluating recursive procedures ... the reason that you need recursion in the evaluator is because the evaluation process, itself, is recursive.

> We've reduced evaluating F,X,Y in environment E0 to evaluate plus A B in E1. And notice, nothing's on the stack, right? It's a reduction. At this point, the machine does not contain, as part of its state, the fact that it's in the middle of evaluating some procedure called F ... There's no accumulated state ... That's the meaning of, when we used to write in the substitution model, this expression reduces to that expression. 

> You have to make these new environment frames but you dont't have to hang onto them when you're done. They can be garbage collected or the space can be reused automatically ... so these procedures really are iterative procecdures

### Recursion

```
fourth call to fact-rec

EXP: (fact-rec n)
ENV: E4

CONTINUE: accumulate-last-arg

STACK: 
  (3)                  <ARGL>
  <primitive-*>        <FUN>
  accumulate-lats-arg  <CONTINUE>
  (4)                  <ARGL>
  <primitive-*>        <FUN>
  accumulate-lats-arg  <CONTINUE>
  (5)                  <ARGL>
  <primitive-*>        <FUN>
  accumulate-lats-arg  <CONTINUE>
```

> ... this evaluator is managing to take these procedures and execute some of them iteratively and some of them recursively, even though, as syntactically, they look like recursive procedures. How's it managing to do that? Well, the basic reason it's managing to do that is the evaluator is set up to save only what it needs later. So, for example, at the point where you've reduced evaluating an expression and an environment to applying a procedure to some arguments, it doesn't need that original environment anymore because any environment stuff will be packaged inside the procedures where the application's going to happen.

> Here's the actual thing that's making it [the evaluator] tail recursive. Remember, it's the restore of continue. It's saying when I go off to evaluate the procedure body, I should tell eval to come back to the place where that original evaluation was supposed to come back to.

## 10A Compilation

### Interpretation vs Compilation

> In interpretation, we're raising the machine to the level of our language, like Lisp. In compilation we're taking our program and lowering it to the language that's spoken by the machine.

> The compiler can produce code that will execute more efficiently. The essential reason for that is that if you think about the register operations that are running, the interpreter has to produce register operations which, in principle, are going to be general enough to execute any Lisp procedure. Whereas the compiler only has to worry about producing a special bunch of register operations for, for doing the particular Lisp procedure that you've compiled.

> Or another way to say that is that the interpreter is a general purpose simulator, that when you read in a Lisp procedure, then those can simulate the program described by that, by that procedure. So the interpreter is worrying about making a general purpose simulator, whereas the compiler, in effect, is configuring the thing to be the machine that the interpreter would have been simulating. So the compiler can be faster.

the lisp interpreter (implemented as a register-machine simulator running the explicit-control evaluator plus primitive operations) takes a Lisp program like factorial and executes it. the combined system behaves like a factorial machine, but it is still a general-purpose evaluator interpreting the program.

the lisp compiler takes a lisp program like factorial and translates it into instructions for the target register machine. That compiled code is then combined with the runtime support / primitive operations, and when run on the register machine it behaves like a specialized factorial machine.

if interpreted and compiled code have the same register conventions  then they can interop (allowing them to call eachother)

to compile some program `(f x)` we could run it through the interpreter and save the machine operations instead of running them, except that is if there is a predicate you don't know which branch you would have gone down. for that you can transform `(if P A B)` to

```scheme
<interpeted code for P, result goes in VAL>
(branch (true? VAL) labelA)
<interpreted code for B>
(goto label-after-conditional)
(labelA <interpreted code for A>)
(label-after-conditional)
```

> already that's going to be more efficient than the evaluator. if you watch the evaluator run, it's not only generating the register operations we wrote down, it's also doing things to decide which ones to generate

> what the evaluator's doing is simultaenously analyzing the code to see what to do and running these operations ... in the compiler, it's happened once.

### Compiling (F X)

register operations in interpreting `(F X)`

```scheme
(assign unev (operands (fetch exp)))                  ; X
(assign exp (operator (fetch exp)))                   ; this is just F, and we can replace subsequent (fetch exp) by just F
(save continue)
(save env)
(save unev)
(assign continue eval-args)                           ; irrelevant to the compiler because we don't need a post-analysis phase
(assign val (lookup-var-val (fetch exp) (fetch env)))
(restore unev)
(restore env)
(assign fun (fetch val))
(save fun)
(assign argl '())
(save argl)
(assign exp (first-operand (fetch unev)))
(assign continue accumulate-last-arg)
(assign val (lookup-var-val (fetch exp) (fetch env)))
(restore argl)
(assign argl (cons (fetch val) (fetch argl)))
(restore fun)
; computation proceeds at apply-dispatch
```

> So in some sense, you don't want unev and exp at all. See what they really are in some sense, those aren't registers of the actual machine that's supposed to run, those are registers that have to do with arranging the thing that can simulate that machine.

register operations in compiling (F X)

```scheme
(save env)
(assign val (lookup-var-val 'f (fetch env)))
(restore env)
(assign fun (fetch val))
(save fun)
(assign argl '())
(save argl)
(assign val (lookup-var-val 'x (fetch env)))
(restore argl)
(assign argl (cons (fetch val) (fetch argl)))
(restore fun)
; computation proceeds at apply-dispatch
```

by going to `apply-dispatch` when applying procedures , we allow interpreted code and compiled code to call each other.

there are still redundant instructions. the environment didn't change between the save and restore, and the argument list didn't change between the save and restore.

> ... the evaluator has to be maximally pessimistic, because as far from its point of view it's just going off to evaluate something so it better save what it's going to need later. But once you've done the analysis, the compiler is in a position to say, well, what actually did I need to save? ... it doesn't need to be as careful as the evaluator, because it knows what it actually needs.

eliminating unnecessary stack procedures further (like saving registers that aren't used at all)

```scheme
(assign fun (lookup-var-val 'f (fetch env)))
(assign val (lookup-var-val 'x (fetch env)))
(assign argl (cons (fetch val) '()))
; computation proceeds at apply-dispatch
```

### Compiler Basic Structure

have some strategies for what needs to be preserved

```
; for (op A B)

1 {compile OP; result in FUN}
2 {compile A; result in VAL}
3 (assign ARGL (cons (fetch VAL) '()))
4 {compile A2; result in VAL}
5 (assign ARGL (cons (fetch VAL) (fetch ARGL)))
6 (goto apply-dispatch)

; 1 preserving ENV
; 2-3 preserving ENV
; 4 preserving ARGL
; 2-5 preserving FUN
```

which depends on the operation of what it means to append two code sequences while preserving registers

```
; append seq1 and seq2 preserving REGISTER

; (the interpreter must always take this option)
; if seq1 needs REGISTER and seq2 modifies REGISTER
(save REGISTER)
<SEQ1>
(restore REGISTER)
<SEQ2>

; otherwise
<SEQ1>
<SEQ2>
```

which depends on what it means to have sequences of instructions that know which registers are needed and modified. if we have the syntax

`<sequence of instructions; set of registers modified; set of registers needed>`

e.g. 

`<(assign R1 (fetch R2)); {R1}; {R2}>`

then we can combine two sequences

`<S1; M1; N1> and <S2; M2; N2>`

to form 

`<S1 and S2; M1 ∪ M2; N1 ∪ [N2-M2]>`

## 10B Storage Allocation and Garbage Collection

### Storage Allocation

we could encode cons in other ways, e.g. Gödel numbering, a valid but inefficient scheme
- `cons x y` => 2^x * 3^y
- `car z` => number of factors of 2 in `z`
- `cdr z` => number of factors of 3 in `z`

in hardware we have linear memory — fixed size continguous blocks of memory with addresses.

```
; lisp
((1 2) 3 4)

; box and pointer (number in box is the pair number)
>[1| ]------->[2| ]->[4|/]
  ↓            ↓      ↓
 [5| ]->[7|/]  3      4
  ↓      ↓
  1      2

; memory
index  00  01  02  03  04  05  06  07
cars   xx  p5  n3  xx  n4  n1  xx  n2
cdrs   xx  p2  p4  xx  e0  p7  xx  e0

; freelist allocation scheme — free memory is linked together in a linked list 
; (e.g. free = f6 i.e. index 6 is free and next one is in 8)
index  00  01  02  03  04  05  06  07
cars   e0  p5  n3  e0  n4  n1  e0  n2
cdrs  f15  p2  p4  f0  e0  p7  f8  e0
```

we need some way to address the elements in memory

```scheme
(vector-ref vector index)

(assign a (car (fetch b)))
; => (assign a (vector-ref) (fetch cars)
;                           fetch b)))

(assign a (cdr (fetch b)))
; => (assign a (vector-ref) (fetch cdrs)
;                           fetch b)))
```

and we can do a similar thing for assignment.

to do allocation (ignoring setting the type to be a pair)

```scheme
(assign a (cons (fetch b) (fetch c)))

; =>

; get the freelist
(assign a (fetch free))
; make the freelist be its cdr
(assign free (vector-ref (fetch the-cdrs) (fetch free)))
; change the cars of a to be c
(perform (vector-set! (fetch the-cars) (fetch a) (fetch b)))
; change the cdrs of a to be c
(perform (vector-set! (fetch the-cdrs) (fetch a) (fetch c)))
```

### Garbage Collection

if we take index 1 as the root and follow the cars/cdrs in a depth-first search, we can mark the referenced/used memory

```
; lisp structure memory
index   00  01  02  03  04  05  06  07
cars    p3  p5  n3  p0  p7  n1  n4  n2
cdrs    p2  p2  p4  p6  e0  p7  n2  e0
marks    0   1   1   0   1   1   0   1
```

the unreferenced/unmarked memory can be linked together into the free list (mark and sweep garbage collected), though this gets slow with large amounts of memory.

[Origins of Garbage Collection by Jason Goodman](https://groups.seas.harvard.edu/courses/cs252/2016fa/16.pdf)
