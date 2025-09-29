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

(define (abs x)
  (cond ((> x 0) x)
    ((= x 0) 0)
    ((< x 0) (- x))))
(abs -10)
; 10

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

(and (> x 5) (< x 10))

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
(sqrt-iter 1.0 x))

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
