(load "3.3.scm") ; operation table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define make-datum cons)
(define datum-type car)
(define datum-contents cdr)

(define (using . installers)
  (reset)
  (for-each (lambda (f) (f)) installers))

(define (apply-generic op . args)
  (let ((type-tags (map datum-type args)))
    (let ((proc (get op type-tags)))
      (if proc
          (apply proc (map datum-contents args))
          (error "No method for these types: APPLY-GENERIC"
                (list op type-tags))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PACKAGES - constructors, selectors, operators
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (scheme-number-pkg)
  (define (tag x) (make-datum 'scheme-number x))
  ; interface
  (put 'make 'scheme-number (lambda (x) (tag x)))
  (put 'add '(scheme-number scheme-number)
    (lambda (x y) (tag (+ x y))))
  (put 'sub '(scheme-number scheme-number)
    (lambda (x y) (tag (- x y))))
  (put 'mul '(scheme-number scheme-number)
    (lambda (x y) (tag (* x y))))
  (put 'div '(scheme-number scheme-number)
    (lambda (x y) (tag (/ x y)))))

(define (rectangular-pkg)
  (define (tag x) (make-datum 'rectangular x))
  ; internal
  (define (real-part z) (car z))
  (define (imag-part z) (cdr z))
  (define (make-from-real-imag x y) (cons x y))
  (define (magnitude z)
    (sqrt (+ (square (real-part z))
             (square (imag-part z)))))
  (define (angle z)
    (atan (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a)
    (cons (* r (cos a)) (* r (sin a))))
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
  (define (tag x) (make-datum 'polar x))
  ; internal
  (define (magnitude z) (car z))
  (define (angle z) (cdr z))
  (define (make-from-mag-ang r a) (cons r a))
  (define (real-part z) (* (magnitude z) (cos (angle z))))
  (define (imag-part z) (* (magnitude z) (sin (angle z))))
  (define (make-from-real-imag x y)
    (cons (sqrt (+ (square x) (square y)))
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
  (define (tag z) (make-datum 'complex z))
  ; imported
  (rectangular-pkg)
  (polar-pkg)
  ; internal selectors (on inner representation)
  (define (real-part z) (apply-generic 'real-part z))
  (define (imag-part z) (apply-generic 'imag-part z))
  (define (magnitude z) (apply-generic 'magnitude z))
  (define (angle z) (apply-generic 'angle z))
  ; internal constructors (from lower representation)
  (define (make-from-real-imag x y)
    ((get 'make-from-real-imag 'rectangular) x y))
  (define (make-from-mag-ang r a)
    ((get 'make-from-mag-ang 'polar) r a))
  ;; internal operations
  (define (add-complex z1 z2)
    (make-from-real-imag (+ (real-part z1) (real-part z2))
                         (+ (imag-part z1) (imag-part z2))))
  (define (sub-complex z1 z2)
    (make-from-real-imag (- (real-part z1) (real-part z2))
                         (- (imag-part z1) (imag-part z2))))
  (define (mul-complex z1 z2)
    (make-from-mag-ang (* (magnitude z1) (magnitude z2))
                       (+ (angle z1) (angle z2))))
  (define (div-complex z1 z2)
    (make-from-mag-ang (/ (magnitude z1) (magnitude z2))
                       (- (angle z1) (angle z2))))
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
(define (make-complex-from-real-imag x y)
  ((get 'make-from-real-imag 'complex) x y))
(define (make-complex-from-mag-ang r a)
  ((get 'make-from-mag-ang 'complex) r a))
; helpers around apply-generic
(define (add x y) (apply-generic 'add x y))
(define (sub x y) (apply-generic 'sub x y))
(define (mul x y) (apply-generic 'mul x y))
(define (div x y) (apply-generic 'div x y))
(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))

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
