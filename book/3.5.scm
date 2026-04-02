; we can void identifying time in the computer with time in the modeled world with streams
; > Think about the issue in terms of mathematical functions. We can describe the time-varying behavior of a quantity x as a function of time x(t). If we concentrate on x instant by instant, we think of it as a changing quantity. Yet if we concentrate on the entire time history of values, we do not emphasize change — the function itself does not change.
; > Physicists sometimes adopt this view by introducing the “world lines” of particles as a device for reasoning about motion.

; manipulations on sequences as transformations of lists must construct and copy data structures (which may be huge) at every step of a process, in comparison to an iterative process

; equivalents, but we require a special forms e.g. (cons a b) would cause b to be evaluated
; (define (cons-stream a b) (cons b (delay y)))
; (define (delay expr) (lambda () expr))
; (define (force delayed-object) (delayed-object))

(define the-empty-stream '())
(define stream-null? null?)
(define (stream-car stream) (car stream))
(define (stream-cdr stream) (force (cdr stream)))

(define (stream-ref s n)
  (if (zero? n)
      (stream-car s)
      (stream-ref (stream-cdr s) (- n 1))))
(define (stream-map f s)
  (if (stream-null? s)
      the-empty-stream
      (cons-stream (f (stream-car s))
                   (stream-map f (stream-cdr s)))))
(define (stream-for-each proc s)
  (if (stream-null? s)
    'done
    (begin (proc (stream-car s))
           (stream-for-each proc (stream-cdr s)))))

(define (display-stream s) (stream-for-each display-line s))
(define (display-line x) (newline) (display x))

; ----

(define (stream-enumerate-interval low high)
(if (> low high)
    the-empty-stream
    (cons-stream low (stream-enumerate-interval (+ low 1) high))))

(define (stream-filter pred s)
(cond ((stream-null? s) the-empty-stream)
      ((pred (stream-car s))
       (cons-stream (stream-car s)
                    (stream-filter pred (stream-cdr s))))
      (else (stream-filter pred (stream-cdr s)))))


(define (memo-proc proc)
  (let ((already-run? #f) (result #f))
    (lambda ()
      (if (not already-run?)
        (begin (set! result (proc))
               (set! already-run? true)
               result)
        result))))

; ; call-by-name thunk
; (define (delay expr) (lambda () expr))
; ; call-by-need thunk
; (define (delay expr) (memo-proc (lambda () expr)))
; delay wants to be memoized, which assignment doesn't want since a repeated call might give a different value

; ----

(define (stream-map f . ss)
(if (stream-null? (car ss))
    the-empty-stream
    (cons-stream (apply f (map stream-car ss))
                 (apply stream-map f (map stream-cdr ss)))))

; ---- infinite streams

(define (stream-take s n)
  (cond ((zero? n) '())
        (else (cons (stream-car s) (stream-take (stream-cdr s) (- n 1))))))

(define (integers-starting-from n)
  (cons-stream n (integers-starting-from (+ n 1))))
(define integers (integers-starting-from 1))

(define (fibgen a b) (cons-stream a (fibgen b (+ a b))))
(define fibs (fibgen 0 1))

; sieve of erastothenes
(define (sieve s)
  (cons-stream
   (stream-car s)
   (sieve (stream-filter
           (lambda (x)
             (not (divisible? x (stream-car s))))
           (stream-cdr s)))))
(define primes (sieve (integers-starting-from 2)))

; ---- defining streams implicitly

(define ones (cons-stream 1 ones))

(define (add-streams s1 s2) (stream-map + s1 s2))
(define (mul-streams s1 s2) (stream-map * s1 s2))
(define (scale-stream stream factor)
  (stream-map (lambda (x) (* x factor)) stream))
(define (negate-stream stream) (scale-stream stream -1))

(define integers
  (cons-stream 1 (add-streams ones integers)))

(define fibs
  (cons-stream 0 (cons-stream 1 (add-streams (stream-cdr fibs) fibs))))

(define powers-of-two (cons-stream 1 (scale-stream double 2)))
(define powers-of-two (cons-stream 1 (add-streams s s)))

(define primes
  (cons-stream 2 (stream-filter prime? (integers-starting-from 3))))

(define (prime? n) 
  (define (iter ps)
    (or (> (square (stream-car ps)) n)
        (and (not (divisible? n (stream-car ps)))
             (iter (stream-cdr ps)))))
  (iter primes))

(define factorials
  (cons-stream 1 (mul-streams factorials (integers-starting-from 2))))

(define (partial-sums s)
  (define self (cons-stream (stream-car s) (add-streams self (stream-cdr s))))
  self)
(stream-take (partial-sums integers) 10) ; => '(1 3 6 10 15 21 28 36 45 55)

; decimal expansion without floating-point operations
(define (expand num den radix)
  (cons-stream
   (quotient (* num radix) den)
   (expand (remainder (* num radix) den) den radix)))
(stream-take (expand 1 7 10) 10) ; => '(1 4 2 8 5 7 1 4 2 8)

(define (integrate-series power-series)
  (stream-map / power-series (integers-starting-from 1)))

(define exp-series
  (cons-stream 1 (integrate-series exp-series)))
(define cosine-series
  (cons-stream 1 (negate-stream (integrate-series sine-series))))
(define sine-series
  (cons-stream 0 (integrate-series cosine-series)))

; 2.2
(define (accumulate op initial sequence)
  (if (null? sequence)
    initial
    (op (car sequence)
        (accumulate op initial (cdr sequence)))))

(define (eval-series s x n)
  (let ((terms (stream-map (lambda (c k) (* c (expt x k)))
                           s
                           (integers-starting-from 0))))
    (accumulate + 0.0 (stream-take terms n))))

(eval-series exp-series 1 100) ; => 2.718281828459045

(define (mul-series s1 s2)
  (cons-stream (* (stream-car s1) (stream-car s2))
               (add-streams (scale-stream (stream-cdr s2) (stream-car s1))
                            (mul-series (stream-cdr s1) s2))))
; sin^2(x) + cos^2(x) = 1 for 100 random x 
(eval-series (add-streams (mul-series sine-series sine-series)
                          (mul-series cosine-series cosine-series))
             (random 100)
             15) ; => 1 (precisely, since the identity is satisfied for partial sums too)

; ---- esxploiting streams

(define (sqrt-stream x)
  (define guesses
    (cons-stream
     1.0
     (stream-map (lambda (guess) (improve guess x))
                 guesses)))
  guesses)

(define (pi-summands n)
  (cons-stream (/ 1.0 n) (stream-map - (pi-summands (+ n 2)))))
(define pi-stream
  (scale-stream (partial-sums (pi-summands 1)) 4))

; sequence accelerator
(define (euler-transform s)
  (let ((s0 (stream-ref s 0))  ; S(n-1)
        (s1 (stream-ref s 1))  ; S(n)
        (s2 (stream-ref s 2))) ; S(n+1)
    (cons-stream (- s2 (/ (square (- s2 s1))
                          (+ s0 (* -2 s1) s2)))
                 (euler-transform (stream-cdr s)))))

; s00 s01 s02 s03 s04 ...
;     s10 s11 s12 s13 ...
;         s20 s21 s23 ...
;             s30 s31 ...
;                 ...
(define (make-tableau transform s)
  (cons-stream s (make-tableau transform (transform s))))

; take the first term in each tableau for a 'sequence super-accelerator'
(define (accelerated-sequence transform s)
  (stream-map stream-car (make-tableau transform s))) 

(stream-ref pi-stream 8)                                        ; => 3.2523659347188767
(stream-ref (euler-transform pi-stream) 8)                      ; => 3.1418396189294033
(stream-ref (accelerated-sequence euler-transform pi-stream) 8) ; => 3.1415926535897953 ; we would need 10^13 terms of pi-stream to match this precision

; ln(2) = 1 - 1/2 + 1/3 - 1/4 + ... so we can create a summand stream and use partial sums
(define (ln-2-summands n)
  (cons-stream (/ 1.0 n) (negate-stream (ln-2-summands (+ n 1)))))
(define ln-2-stream
  (partial-sums (ln-2-summands 1)))

; ---- infinite streams of pairs

; we need a way of enumerating all pairs of infinite streams without getting lost in one infinite stream

(define (pairs s t)
  (cons-stream
   (list (stream-car s) (stream-car t))
   (interleave
    (stream-map (lambda (x) (list (stream-car s) x))
                (stream-cdr t))
    (pairs (stream-cdr s) (stream-cdr t)))))

(define (interleave s1 s2)
  (cond ((stream-null? s1) s2)
        (else (cons-stream (stream-car s1)
                           (interleave s2 (stream-cdr s1))))))

(define integer-pairs (pairs integers integers))
(stream-take integer-pairs 10) ; => ((1 1) (1 2) (2 2) (1 3) (2 3) (1 4) (3 3) (1 5) (2 4) (1 6))

(define (triples s t u)
  (cons-stream
   (list (stream-car s) (stream-car t) (stream-car u))
   (interleave
    (stream-map (lambda (x) (cons (stream-car s) x))
                (stream-cdr (pairs t u)))
    (triples (stream-cdr s) (stream-cdr t) (stream-cdr u)))))

(define (merge-weighted s1 s2 weight)
  (define (merge s1 s2)
    (cond ((stream-null? s1) s2)
          ((stream-null? s2) s1)
          (else (let ((x1 (stream-car s1))
                      (x2 (stream-car s2)))
                  (if (<= (weight x1) (weight x2))
                      (cons-stream x1 (merge (stream-cdr s1) s2))
                      (cons-stream x2 (merge s1 (stream-cdr s2))))))))
  (merge s1 s2))

(define (weighted-pairs s t weight)
  (cons-stream
   (list (stream-car s) (stream-car s))
   (merge-weighted
    (stream-map (lambda (x) (list (stream-car s) x))
                (stream-cdr t))
    (weighted-pairs (stream-cdr s) (stream-cdr t) weight)
    weight)))

(define (weight p) (+ (car p) (cadr p)))
(define integer-paris-weighted (weighted-pairs integers integers weight))
(stream-take integer-paris-weighted 10) ; ((1 1) (1 2) (1 3) (2 2) (1 4) (2 3) (1 5) (2 4) (3 3) (1 6))

; ---- streams and delayed evaluation

; introduced an explicit delay for subsequent terms to avoid infinite loops
(define (integral delayed-integrand initial-value dt)
  (define int
    (cons-stream
     initial-value
     (let ((integrand (force delayed-integrand)))
       (add-streams (scale-stream integrand dt) int))))
  int)

; y' = y
(define (solve f y0 dt)
  (define y (integral (delay dy) y0 dt))
  (define dy (stream-map f y))
  y)

; when f(y) = y and y_0 = 1, the solution is e
(stream-ref (solve (lambda (y) y) 1 0.001) 1000) ; => 2.716923932235896

; y’’ - ay’ - by = 0
(define (solve-2nd a b y0 dy0 dt)
  (define y (integral (delay dy) y0 dt))
  (define dy (integral (delay ddy) dy0 dt))
  (define ddy (add-streams (scale-stream dy a)
                           (scale-stream y b)))
  y)

; y’’ = f(y’, y).
(define (solve-2nd f y0 dy0 dt)
  (define y (integral (delay dy) y0 dt))
  (define dy (integral (delay ddy) dy0 dt))
  (define ddy (stream-map f dy y))
  y)

; ---- normal-order evalutaiton

; > the explicit use of delay and force provides great programming flexibility, but the same examples also show how this can make our programs more complex. Our new integral procedure, for instance, gives us the power to model systems with loops, but we must now remember that integral should be called with a delayed integrand, and every procedure that uses integral must be aware of this. In eﬀect, we have created two classes of procedures: ordinary procedures and procedures that take delayed arguments. In general, creating separate classes of procedures forces us to create separate classes of higher-order procedures as well.
; > Maintaining a practical notion of “data type” in the presence of higher-order procedures raises many diﬃcult issues. One way of dealing with this problem is illustrated by the language ML whose “polymorphic data types” include templates for higher-order transformations between data types. Moreover, data types for most procedures in ML are never explicitly declared by the programmer. Instead, ML includes a type-inferencing mechanism that uses information in the environment to deduce the data types for newly defined procedures.
; > Converting to normal-order evaluation provides a uniform and elegant way to simplify the use of delayed evaluation, and this would be a natural strategy to adopt if we were concerned only with stream processing.
; > Unfortunately, including delays in procedure calls wreaks havoc with our ability to design programs that depend on the order of events, such as programs that use assignment, mutate data, or perform input or output.

; some cases where assignment can be avoided by using streams
(define random-numbers
  (cons-stream random-init
               (stream-map rand-update random-numbers)))

; --- a functional programming view of time

; > We can model a changing quantity, such as the local state of some object, using a stream that represents the time history of successive states. In essence, we represent time explicitly, using streams, so that we decouple time in our simulated world from the sequence of events that take place during evaluation.

; > Even though stream-withdraw implements a well-defined mathematical function whose behavior does not change, the user's perception here is one of interacting with a system that has a changing state. One way to resolve this paradox is to realize that it is the user's temporal existence that imposes state on the system. If the user could step back from the interaction and think in terms of streams of balances rather than individual transactions, the system would appear stateless.

; > Similarly in physics, when we observe a moving particle, we say that the position (state) of the particle is changing. However, from the perspective of the particle’s world line in space-time there is no change involved.

; technically “merge” is a relation rather than a function — the answer is not a deterministic function of the inputs. as discussed previously concurrent programs are inherently nondeterministic, and the merge relation illustrates the same essential nondeterminism, from the functional perspective. Ths, in an attempt to support the functional style, the need to merge inputs from diﬀerent agents (e.g. transaction streams from multiple people to a shared account) reintroduces the same problems that the functional style was meant to eliminate.

; > We can model the world as a collection of separate, time-bound, interacting objects with state, or we can model the world as a single, timeless, stateless unity. Each view has powerful advantages, but neither view alone is completely satisfactory. A grand unification has yet to emerge. The object model approximates the world by dividing it into separate pieces. The functional model does not modularize along object boundaries. 

; > The object model is useful when the unshared state of the “objects” is much larger than the state that they share. An example of a place where the object viewpoint fails is quantum mechanics, where thinking of things as individual particles leads to paradoxes and confusions. Uni- fying the object view with the functional view may have little to do with programming, but rather with fundamental epistemological issues.
