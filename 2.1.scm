(define x (cons 1 2))
(car x) ; 1
(cdr x) ; 2

(define y (cons x 3))
(car y) ; (1 . 2)
(cdr y) ; 3

(define (make-rat n d) (cons n d))
; or, to avoid the extra procedure call 
(define make-rat cons)

(define (numer x) (car x))
(define (denom x) (cdr x))

(define (print-rat x)
(newline)
(display (numer x))
(display "/")
(display (denom x)))

(define half (make-rat 1 2))
(print-rat half)

; ----

(define (add-rat x y)
  (make-rat (+ (* (numer x) (denom y))
               (* (numer y) (denom x)))
            (* (denom x) (denom y))))
(define (sub-rat x y)
  (make-rat (- (* (numer x) (denom y))
               (* (numer y) (denom x)))
            (* (denom x) (denom y))))
(define (mul-rat x y)
  (make-rat (* (numer x) (numer y))
            (* (denom x) (denom y))))
(define (div-rat x y)
  (make-rat (* (numer x) (denom y))
            (* (denom x) (numer y))))
(define (equal-rat? x y)
  (= (* (numer x) (denom y))
     (* (numer y) (denom x))))

; ----

(define (sgn x)
  (cond ((< x 0) -1)
        ((= x 0) 0)
        ((> x 0) 1)))

(define (make-rat n d)
  (let ((g (gcd n d))
        (s (* (sgn n) (sgn d))))
    (cons (* s (/ (abs n) g))
          (/ (abs d) g))))

(make-rat 2 -4) ; (-1 . 2)

; ----

; we can define cons, car, cdr as procedures without using the data structures

; 1 way to do it
(define (cons x y)
  (define (dispatch m)
    (cond ((= m 0) x)
      ((= m 1) y)
    (else (error "Argument not 0 or 1: CONS" m))))
      dispatch)
(define (car z) (z 0))
(define (cdr z) (z 1))

; another way to do it
(define (cons x y) (lambda (selector) (selector x y))) ; wraps its two values into a closure
(define (car pair) (pair (lambda (x y) x)))
(define (cdr pair) (pair (lambda (x y) y)))

(car (cons 'a 'b))
; (car ((lambda (m) (m 'a 'b))))
; (car (lambda (m) (m 'a 'b)))
; ((lambda (m) (m 'a 'b)) (lambda (x y) x))
; ((lambda (x y) x) 'a 'b)
; 'a

; ----

; lambda calculus

(define zero (lambda (f) (lambda (x) x)))
(define one  (lambda (f) (lambda (x) (f x))))
(define two  (lambda (f) (lambda (x) (f (f x)))))

(define (add-1 n)
  (lambda (f) (lambda (x) (f ((n f) x)))))

(add-1 zero)
; (add-1 (lambda (f) (lambda (x) x)))
; (lambda (f) (lambda (x) (f (((lambda (f) (lambda (x) x))) f) x)))
; (lambda (f) (lambda (x) (f (lambda (x) x) x)))
; (lambda (f) (lambda (x) (f x))) ; = `one`

(define (add a b)
  (lambda (f) (lambda (x) ((a f) ((b f) x)))))

(define (church->number n)
  ((n (lambda (x) (+ x 1))) 0))

(church->number zero) ; 0
(church->number one) ; 1
(church->number two) ; 2
