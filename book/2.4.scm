(load "3.3.scm") ; operation table

; rectangular form representation
(define (real-part z) (car z))
(define (imag-part z) (cdr z))
(define (magnitude z)
  (sqrt (+ (square (real-part z))
           (square (imag-part z)))))
(define (angle z)
        (atan (imag-part z) (real-part z)))
(define (make-from-real-imag x y) (cons x y))
(define (make-from-mag-ang r a)
  (cons (* r (cos a)) (* r (sin a))))

; polar form representation
(define (real-part z) (* (magnitude z) (cos (angle z))))
(define (imag-part z) (* (magnitude z) (sin (angle z))))
(define (magnitude z) (car z))
(define (angle z) (cdr z))
(define (make-from-real-imag x y)
  (cons (sqrt (+ (square x) (square y)))
        (atan y x)))
(define (make-from-mag-ang r a) (cons r a))

; generic operations
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

; ----

; explicit-dispatch approach

; rather than having independent selectors and constructors, data abstraction (through tagged data) ensures generic operations work with multiple representations
; generic operations are unchanged
; constructors attach tags, selectors strip tags

(define (attach-tag type-tag contents)
  (cons type-tag contents))
(define (type-tag datum)
  (if (pair? datum)
      (car datum)
      (error 'type-tag "bad tagged datum" datum)))
(define (contents datum)
  (if (pair? datum)
      (cdr datum)
      (error 'contents "bad tagged datum" datum)))
(define (rectangular? z) (eq? (type-tag z) 'rectangular))
(define (polar? z) (eq? (type-tag z) 'polar))

; rectangular form representation
(define real-part-rectangular car)
(define imag-part-rectangular cdr)
(define (magnitude-rectangular z)
  (sqrt (+ (square (real-part-rectangular z))
           (square (imag-part-rectangular z)))))
(define (angle-rectangular z)
  (atan (imag-part-rectangular z)
        (real-part-rectangular z)))
(define (make-from-real-imag-rectangular x y)
  (attach-tag 'rectangular (cons x y)))
(define (make-from-mag-ang-rectangular r a)
  (attach-tag 'rectangular
              (cons (* r (cos a))
                    (* r (sin a)))))
; polar form representation
(define (real-part-polar z)
  (* (magnitude-polar z) (cos (angle-polar z))))
(define (imag-part-polar z)
  (* (magnitude-polar z) (sin (angle-polar z))))
(define magnitude-polar car)
(define angle-polar cdr)
(define (make-from-real-imag-polar x y)
  (attach-tag 'polar
              (cons (sqrt (+ (square x) (square y)))
                    (atan y x))))
(define (make-from-mag-ang-polar r a)
  (attach-tag 'polar (cons r a)))

; generic selectors - (explicit) dispatch on type
(define (real-part z)
  (cond ((rectangular? z)
         (real-part-rectangular (contents z)))
        ((polar? z)
         (real-part-polar (contents z)))
        (else (error 'real-part "unknown type" z))))
(define (imag-part z)
  (cond ((rectangular? z)
         (imag-part-rectangular (contents z)))
        ((polar? z)
         (imag-part-polar (contents z)))
        (else (error 'imag-part "unknown type" z))))
(define (magnitude z)
  (cond ((rectangular? z)
         (magnitude-rectangular (contents z)))
        ((polar? z)
         (magnitude-polar (contents z)))
        (else (error 'magnitude "unknown type" z))))
(define (angle z)
  (cond ((rectangular? z)
         (angle-rectangular (contents z)))
        ((polar? z)
         (angle-polar (contents z)))
        (else (error 'angle "unknown type" z))))

; generic constructors, choosing the most convenient representation for each
(define make-from-real-imag make-from-real-imag-rectangular)
(define make-from-mag-ang make-from-mag-ang-polar)

(add-complex (make-from-real-imag 3 4) (make-from-mag-ang 5 0))
(mul-complex (make-from-mag-ang 3 4) (make-from-mag-ang 5 0))

; ----

; data-directed approach (dispatch on data type)
; avoids modifying selectors each time a new representation is added/removed
; avoids naming conflicts between representations
; the type is a list to allow for operations with multiple arguments which may be of different types

; +-------------+-------------------+---------------------------+
; | operation   | type list         | procedure                 |
; +-------------+-------------------+---------------------------+
; | real-part   | (rectangular)     | real-part-rectangular     |
; | imag-part   | (rectangular)     | imag-part-rectangular     |
; | magnitude   | (rectangular)     | magnitude-rectangular     |
; | angle       | (rectangular)     | angle-rectangular         |
; | ...         |                   |                           |
; | real-part   | (polar)           | real-part-polar           |
; | imag-part   | (polar)           | imag-part-polar           |
; | magnitude   | (polar)           | magnitude-polar           |
; | angle       | (polar)           | angle-polar               |
; | ...         |                   |                           |
; +-------------+-------------------+---------------------------+

; (put 'real-part '(rectangular) rectangular-real-part)    ; PUT KEY1 KEY2 VALUE
; (get 'real-part '(rectangular)) => rectangular-real-part ; GET KEY1 KEY2 VALUE

(define (rectangular-pkg)
  ;; internal procedures
  (define real-part car)
  (define imag-part cdr)
  (define make-from-real-imag cons)
  (define (magnitude z)
    (sqrt (+ (square (real-part z))
             (square (imag-part z)))))
  (define (angle z)
    (atan (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a)
    (cons (* r (cos a)) (* r (sin a))))
  ;; interface to the rest of the system
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude '(rectangular) magnitude)
  (put 'angle '(rectangular) angle)
  (put 'make-from-real-imag 'rectangular
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular
       (lambda (r a) (tag (make-from-mag-ang r a)))))

(define (polar-pkg)
  ;; internal procedures
  (define magnitude car)
  (define angle cdr)
  (define make-from-mag-ang cons)
  (define (real-part z)
    (* (magnitude z) (cos (angle z))))
  (define (imag-part z)
    (* (magnitude z) (sin (angle z))))
  (define (make-from-real-imag x y)
    (cons (sqrt (+ (square x) (square y)))
          (atan y x)))
  ;; interface to the rest of the system
  (define (tag x) (attach-tag 'polar x))
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude '(polar) magnitude)
  (put 'angle '(polar) angle)
  (put 'make-from-real-imag 'polar
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar
       (lambda (r a) (tag (make-from-mag-ang r a)))))

; helpers
; look up procedure based on operation name and type tags (used outside of package)
(define (apply-generic op . args)
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (if proc
          (apply proc (map contents args))
          (error "No method for these types: APPLY-GENERIC"
                 (list op type-tags))))))
; look up procedure based on operation name and type key (useful inside of package)
(define (apply-specific op type . args)
  (let ((proc (get op type)))
    (if proc
        (apply proc args)
        (error op "no method for type" op type))))

; generic selectors can be rewritten to pull from the table
(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))

; generic constructors can be rewritten to pull from the table
(define (make-from-real-imag x y)
  ((get 'make-from-real-imag 'rectangular) x y))
(define (make-from-mag-ang r a)
  ((get 'make-from-mag-ang 'polar) r a))

; ----

(define (using . installers)
  (reset)
  (for-each (lambda (f) (f)) installers))

(using rectangular-pkg polar-pkg)

(add-complex (make-from-real-imag 1 2) (make-from-real-imag 3 4)) ; => ('rectangular 4 6)
(mul-complex (make-from-mag-ang 5 1) (make-from-mag-ang 6 2))     ; => ('polar 30 3)

; ----

; message-passing approach (dispatch on operation name)
; instead of the data object containing the type, it contains the operations themselves

(define (make-from-real-image-message-passing x y)
  (define (dispatch op)
    (cond ((eq? op 'real-part) x)
          ((eq? op 'imag-part) y)
          ((eq? op 'magnitude) (sqrt (+ (square x) (square y))))
          ((eq? op 'angle) (atan y x))
          (else (error "Unknown op: MAKE-FROM-REAL-IMAGE" op))))
    dispatch)

(define (apply-generic-message-passing op arg) (arg op))

(apply-generic-message-passing 'real-part (make-from-real-image-message-passing 3 4)) ; => 3
(apply-generic-message-passing 'magnitude (make-from-real-image-message-passing 0 1)) ; => 1

; ----

; explicit-dispatch approach works best when mostly adding new operations
; messaging-passing approach works best when mostly adding new types
; data-directed approach works equally well for both
