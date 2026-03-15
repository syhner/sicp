486
; 486

(+ 21 35 12 7)
; 75

(+ (* 3 5) (- 10 6))
; 19

(define size 2)
size
; 2

(define (square x) (* x x))
(square 21)
; 441

(define (sum-of-squares x y) (+ (square x) (square y)))
(sum-of-squares 3 4)
; 25

; ----

(define (p) (p))
(define (test x y) (if (= x 0) 0 y))

; (test 0 (p))

; With applicative-order evaluation (eager / evaluate arguments first / evaluate arguments then apply)
; the expression will never return a value because the interpreter tries to evaluate (p) and enters endless recursion.
; this is what the scheme interpreter uses
; interpreter doesn’t have to manage unevaluated expressions (thunks)
; => (test 0 (p))
; => (p)
; => (p)
; => ...

; With normal-order evaluation (lazy / evaluate only when needed / fully expand and then reduce)
; the expression will evaluate to zero. The (p) expression is never evaluated because it is not necessary to do so.
; (test 0 (p))
; => (if (= 0 0) 0 (p))
; => (if #t 0 (p))
; => 0


; opt-in to lazy evaluation with
(define (delay expr) (lambda () expr))
(define (force thunk) (thunk))

; (delay (+ 1 2)) returns a procedure, and (+ 1 2) is not computed yet
; (force (delay (+ 1 2))) evaluates to 3

; ----

(define (abs x)
  (cond ((< x 0) (- x))
    (else x)))
(abs -10)
; 10

(define (abs x)
  (if (< x 0)
    (- x)
    x))
(abs -10)
; 10

(and (> 2 5) (< 2 10))
; #f

(define (>= x y) (or (> x y) (= x y)))
(>= 1 0)
; #t

(define (>= x y) (not (< x y)))
(>= 1 0)
; #t

(define (a-plus-abs-b a b)
  ((if (> b 0) + -) a b))
(a-plus-abs-b 1 (- 2))
; 3

; ----

(define (square x) (* x x))

(define (sqrt-iter guess x)
(if (good-enough? guess x)
guess
(sqrt-iter (improve guess x) x)))

(define (improve guess x)
(average guess (/ x guess)))

(define (average x y)
(/ (+ x y) 2))

(define (good-enough? guess x)
(< (abs (- (square guess) x)) 0.001))

(define (sqrt x)
(sqrt-iter 1.0 x)) ; 1.0 is the initial guess

(sqrt 9)
; 3.00009155413138

; ---- block structure

(define (sqrt x)
  (define (good-enough? guess x)
    (< (abs (- (square guess) x)) 0.001))
  (define (improve guess x)
    (average guess (/ x guess)))
  (define (sqrt-iter guess x)
    (if (good-enough? guess x)
        guess
        (sqrt-iter (improve guess x) x)))
  (sqrt-iter 1.0 x))

(sqrt 9)
; 3.00009155413138

; ---- lexical scoping

(define (sqrt x)
  (define (good-enough? guess)
    (< (abs (- (square guess) x)) 0.001))
  (define (improve guess)
    (average guess (/ x guess)))
  (define (sqrt-iter guess)
    (if (good-enough? guess)
      guess
      (sqrt-iter (improve guess))))
  (sqrt-iter 1.0))
