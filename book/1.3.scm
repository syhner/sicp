; linear recursive
(define (sum term a next b)
(if (> a b)
    0
    (+ (term a)
       (sum term (next a) next b))))

; linear iterative
(define (sum term a next b)
  (define (iter a acc)
    (if (> a b)
        acc
        (iter (next a) (+ acc (term a)))))
  (iter a 0))

(define (inc n) (+ n 1))
(define (cube n) (* n n n))
(define (sum-cubes a b) (sum cube a inc b))
(sum-cubes 1 10) ; => 3025

(define (identity x) x)
(define (sum-integers a b) (sum identity a inc b))
(sum-integers 1 10) ; => 55

(define (integral f a b dx)
  (define (add-dx x)
    (+ x dx))
  (* (sum f
          (+ a (/ dx 2.0))
          add-dx 
          b)
    dx))

; or, using lambda
(define (integral f a b dx)
  (* (sum f
          (+ a (/ dx 2.0))
          (lambda (x) (+ x dx))
          b)
     dx))

(integral cube 0 1 0.01) ; => .24998750000000042
(integral cube 0 1 0.001) ; => .249999875000001

; recursive
(define (product term a next b)
  (if (> a b)
      1
      (* (term a)
         (product term (next a) next b))))

; iterative
(define (product term a next b)
  (define (iter a acc)
    (if (> a b)
        acc
        (iter (next a) (* acc (term a)))))
  (iter a 1))

; sum and product can be written in terms of a lower abstraction 'accumulate'
; the null-value is the identity for the operator

; recursive
(define (accumulate combiner null-value term a next b)
  (if (> a b)
      null-value
      (combiner (term a)
              (accumulate combiner null-value term (next a) next b))))

; iterative
(define (accumulate combiner null-value term a next b)
  (define (iter a acc)
    (if (> a b)
        acc
        (iter (next a) (combiner (term a) acc))))
  (iter a null-value))

(define (sum term a next b)
  (accumulate + 0 term a next b))

(define (product term a next b)
  (accumulate * 1 term a next b))

; ----

; the folllwing are equivalent

(define (multiply-then-add-five a b) 
  (let ((c (* a b)))
    (+ c 5)))

(define (multiply-then-add-five a b)
  ((lambda (c) (+ c 5)) (* a b))) ; IIFE

; ----

(define tolerance 0.00001)
(define (close-enough? x y) (< (abs (- x y)) tolerance))

(define (fixed-point f first-guess)
  (define (try guess)
    (let ((next (f guess)))
      (if (close-enough? guess next)
          next
          (try next))))
  (try first-guess))

(fixed-point cos 1.0) ;  => 0.7390822985224023

(fixed-point (lambda (x) (+ (sin x) (cos x)))
1.0)

; computational sqrt
(define (sqrt x)
  (fixed-point (lambda (y) (/ x y)) 1.0))
; (sqrt 2) ; does not converge

; computational sqrt with average damping
(define (average x y) (/ (+ x y) 2))
(define (sqrt x)
  (fixed-point (lambda (y) (average y (/ x y))) 1.0))
(sqrt 2) ; 1.4142135623746899

(define golden-ratio (/ (+ 1 (sqrt 5)) 2))
golden-ratio ; 1.6180339887498950
(fixed-point (lambda (x) (+ 1 (/ x))) 1.0) ; 1.6180327868852458

; procedure as returned values
(define (average-damp f)
  (lambda (x) (average x (f x))))

((average-damp square) 10) ; 55

; computational sqrt with average damping abstraction
(define (sqrt x)
  (fixed-point (average-damp (lambda (y) (/ x y))) 1.0))

(define dx 0.00001)
(define (deriv f)
  (lambda (x) (/ (- (f (+ x dx)) (f x)) dx)))

((deriv cube) 5) ; 75.00014999664018

(define (newton-transform g)
  (lambda (x) (- x (/ (g x) ((deriv g) x)))))
(define (newtons-method g guess)
  (fixed-point (newton-transform g) guess))

(define (sqrt x)
  (newtons-method (lambda (y) (- (square y) x)) 1.0))

; using a higher level abstraction

(define (fixed-point-of-transform g transform guess)
  (fixed-point (transform g) guess))

(define (sqrt x)
  (fixed-point-of-transform (lambda (y) (/ x y)) average-damp 1.0))

(define (sqrt x)
  (fixed-point-of-transform (lambda (y) (- (square y) x)) newton-transform 1.0))

; ----

(define (double f)
  (lambda (x)
    (f (f x))))

(define (compose f g)
  (lambda (x)
    (f (g x))))

(define (repeated f n)
  (if (= n 1)
      f
      (compose (repeated f (- n 1)) f)))

; ----

(define (nth-root x n)
  (fixed-point
    ((repeated average-damp
               (floor (/ (log n) (log 2))))
      (lambda (y) (/ x (expt y (- n 1)))))
    1.0))

; ----

; new abstraction
(define (iterative-improve good-enough? improve)
  (define (iter guess)
    (if (good-enough? guess)
        guess
        (iter (improve guess))))
  iter)

(define (sqrt x)
  ((iterative-improve
    (lambda (guess)
      (< (abs (- (square guess) x)) tolerance))
    (lambda (guess)
      (average guess (/ x guess))))
  1.0))

(define (fixed-point f first-guess)
  ((iterative-improve
    (lambda (guess)
      (< (abs (- guess (f guess))) tolerance))
    f)
  first-guess))
