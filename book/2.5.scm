(load "2.1.scm") ; rational number operations
(load "2.4.scm") ; complex number operations
(load "optable.scm") ; operation table

(define (add x y) (apply-generic 'add x y))
(define (sub x y) (apply-generic 'sub x y))
(define (mul x y) (apply-generic 'mul x y))
(define (div x y) (apply-generic 'div x y))

(define (scheme-number-pkg)
  (define (tag x) (attach-tag 'scheme-number x))
  (put 'add '(scheme-number scheme-number) (lambda (x y) (tag (+ x y))))
  (put 'sub '(scheme-number scheme-number) (lambda (x y) (tag (- x y))))
  (put 'mul '(scheme-number scheme-number) (lambda (x y) (tag (* x y))))
  (put 'div '(scheme-number scheme-number) (lambda (x y) (tag (/ x y))))
  (put 'make 'scheme-number tag))

(define (make-scheme-number n)
  (apply-specific 'make 'scheme-number n))

(define (rational-pkg)
  (define (tag x) (attach-tag 'rational x))
  (put 'add '(rational rational) (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational) (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational) (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational) (lambda (x y) (tag (div-rat x y))))
  (put 'make 'rational (lambda (n d) (tag (make-rat n d)))))

(define (make-rational n d)
  (apply-specific 'make 'rational n d))

(define (complex-pkg)
  (define (tag z) (attach-tag 'complex z))
  (rectangular-pkg)
  (polar-pkg)
  (put 'add '(complex complex) (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex) (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex) (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex) (lambda (z1 z2) (tag (div-complex z1 z2))))
  (put 'make-from-real-imag 'complex
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex
       (lambda (r a) (tag (make-from-mag-ang-polar r a)))))

; two-level tag system where the outer tag (complex) is first stripped and the next tag (rectangular) directs the number to the rectangular package
(define (make-complex-from-real-imag x y)
  (apply-specific 'make-from-real-imag 'complex x y))
(define (make-complex-from-mag-ang r a)
  (apply-specific 'make-from-mag-ang 'complex r a))

(define (numeric-pkg)
  (scheme-number-pkg)
  (rational-pkg)
  (complex-pkg))

(using numeric-pkg)

(add (make-scheme-number 1) (make-scheme-number 2)) ; => (make-scheme-number 3)

(mul (make-rational 1 2) (make-rational 3 4)) ; => (make-rational 3 8)

(sub (make-complex-from-mag-ang 1 0) (make-complex-from-real-imag 1 1)) ; => (make-complex-from-real-imag 0 -1)

; ----

; wrapper type over rectangular and polar representations

(define (complex-components-pkg)
  (put 'real-part '(complex) real-part)
  (put 'imag-part '(complex) imag-part)
  (put 'magnitude '(complex) magnitude)
  (put 'angle '(complex) angle))

(using complex-pkg complex-components-pkg)
(define z (make-complex-from-real-imag 3 4))
(magnitude z)
; => (magnitude '(complex rectangular 3 . 4))
; => (apply-generic 'magnitude '(complex rectangular 3 . 4))    ; 1st call
; => (apply (get 'magnitude '(complex)) '((rectangular 3 . 4)))
; => (magnitude '(rectangular 3 . 4))
; => (apply-generic 'magnitude '(rectangular 3 . 4))            ; 2nd call
; => (apply (get 'magnitude '(rectangular)) '((3 . 4)))
; => (sqrt (+ (square 3) (square 4)))
; => (sqrt (+ 9 16))
; => (sqrt 25)
; => 5

; ; ----

; all lisp implementations have a type system which is used internally
; primitive predicates such as symbol? and number? determine whether data objects have particular types
; so instead of representing scheme numbers as pairs ('scheme-number 1)
; we can take advantage of scheme's internal type-system

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

(attach-tag 'scheme-number 1) ; => 1
(type-tag 1) ; => 'scheme-number
(contents 1) ; => 1

(attach-tag 'foo 'a) ; => '(foo . a)
(type-tag '(foo . a)) ; => 'foo
(contents '(foo . a)) ; => 'a

; ----

; generic predicate

(define (equ-pkg)
  (put 'equ? '(scheme-number scheme-number) =)
  (put 'equ? '(rational rational)
       (lambda (x y)
         (and (= (numer x) (numer y))
              (= (denom x) (denom y)))))
  (put 'equ? '(complex complex)
       (lambda (z1 z2)
         (and (= (real-part z1) (real-part z2))
              (= (imag-part z1) (imag-part z2))))))

(define (equ? x y) (apply-generic 'equ? x y))

(using numeric-pkg equ-pkg)

(equ? (make-scheme-number 1) (make-scheme-number 2)) ; => #f
(equ? (make-rational 1 2) (make-rational 2 4)) ; => #t

; ----

; combining data of different types (generic over different types of arguments)
; e.g. add complex number to rational number

(define (get-coercion type1 type2)
  (get 'coerce (list type1 type2)))
(define (put-coercion type1 type2 coerce)
  (put 'coerce (list type1 type2) coerce))

(define (apply-generic op . args)
  (let* ((type-tags (map type-tag args))
         (proc (get op type-tags)))
    (define (err)
      (error 'apply-generic "no method for types" op type-tags))
    (if proc
        (apply proc (map contents args))
        (if (= (length args) 2)
            (let ((type1 (car type-tags))
                  (type2 (cadr type-tags)))
              (if (eq? type1 type2) ; don't coerce arguments of the same type
                  (err)
                  (let ((a1 (car args))
                        (a2 (cadr args))
                        (t1->t2 (get-coercion type1 type2))
                        (t2->t1 (get-coercion type2 type1)))
                    (cond (t1->t2 (apply-generic op (t1->t2 a1) a2))
                          (t2->t1 (apply-generic op a1 (t2->t1 a2)))
                          (else (err))))))
            (err)))))

(define (scheme-number-to-complex-pkg)
  (define (coerce n)
    (make-complex-from-real-imag (contents n) 0))
  (put-coercion 'scheme-number 'complex coerce))

(using numeric-pkg scheme-number-to-complex-pkg)

(add (make-scheme-number 1) (make-complex-from-real-imag 0 1))
; => (add (make-complex-from-real-imag 0 1) (make-scheme-number 1))
; => (make-complex-from-real-imag 1 1)
