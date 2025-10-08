; linear recurisve
(define (factorial n)
  (if (= n 1)
    1
    (* n (factorial (- n 1)))))

(factorial 6)
; => (* 6 (factorial 5))
; => (* 6 (* 5 (factorial 4)))
; => (* 6 (* 5 (* 4 (factorial 3))))
; => (* 6 (* 5 (* 4 (* 3 (factorial 2)))))
; => (* 6 (* 5 (* 4 (* 3 (* 2 (factorial 1))))))
; => (* 6 (* 5 (* 4 (* 3 (* 2 1)))))
; => (* 6 (* 5 (* 4 (* 3 2))))
; => (* 6 (* 5 (* 4 6)))
; => (* 6 (* 5 24))
; => (* 6 120)
; => 720

; linear iterative
(define (factorial n)
  (define (iter product counter)
    (if (> counter n)
      product
      ; tail recursive since the last step in the evaluation (which is applicative) is the recursion step
      (iter (* counter product)
            (+ counter 1))))
  (iter 1 1))


(factorial 6)
; => (iter 1 1 6)
; => (iter 1 2 6)
; => (iter 2 3 6)
; => (iter 6 4 6)
; => (iter 24 5 6)
; => (iter 120 6 6)
; => (iter 720 7 6)
; => 720

; ----

; tree recursive
(define (fib n)
  (cond ((= n 0) 0)
    ((= n 1) 1)
    (else (+ (fib (- n 1))
          (fib (- n 2))))))

(fib 4)
; => (+ (fib 3) (fib 2))
; => (+ (+ (fib 2) (fib 1)) (+ (fib 1) (fib 0)))
; => (+ (+ (+ (fib 1) (fib 0)) 1) (+ 1 0))
; => (+ (+ 1 1) 1)
; => (+ 2 1)
; => 3

; In general, for a given recursive tree
; space is O(node depth)
; time is O(node count)

; linear iterative
(define (fib n)
  (define (iter a b counter)
    (if (= counter 0)
        b
        (iter (+ a b) 
              a 
              (- counter 1))))
  (iter 1 0 n))

(fib 4)
; => (iter 1 0 4)
; => (iter 1 1 3)
; => (iter 2 1 2)
; => (iter 3 2 1)
; => (iter 5 3 0)
; => 3

; ---

(define (inc x) (+ x 1))
(define (dec x) (- x 1))

; recursive addition
(define (r+ a b)
  (if (= a 0) b (inc (r+ (dec a) b))))

(r+ 4 5)
; => (inc (r+ 3 5))
; => (inc (inc (r+ 2 5)))             ; expanding
; => (inc (inc (inc (r+ 1 5))))
; => (inc (inc (inc (inc (r+ 0 5))))) ; 4 deferred operations
; => (inc (inc (inc (inc 5))))
; => (inc (inc (inc 6)))              ; contracting
; => (inc (inc 7))
; => (inc 8)
; => 9

; iterative addition
(define (i+ a b)
  (if (= a 0) b (i+ (dec a) (inc b))))

(i+ 4 5)
; => (i+ 3 6)
; => (i+ 2 7)
; => (i+ 1 8)
; => (i+ 0 9)
; => 9

; ----

(define (count-change amount)
  (define (cc a kinds-of-coins)
    (cond ((< a 0) 0)
          ((= a 0) 1)
          ((= kinds-of-coins 0) 0)
          (else (+ (cc a (- kinds-of-coins 1))
                   (cc (- a (first-denomination kinds-of-coins)) kinds-of-coins)))))
  (cc amount 5))

(define (first-denomination kinds-of-coins)
(cond ((= kinds-of-coins 1) 1)
((= kinds-of-coins 2) 5)
((= kinds-of-coins 3) 10)
((= kinds-of-coins 4) 25)
((= kinds-of-coins 5) 50)))

(count-change 100)
; 292

; ----

; recursive
(define (f n)
  (if (< n 3)
    n
    (+ (f (- n 1))
      (* 2 (f (- n 2)))
      (* 3 (f (- n 3))))))

; iterative, counter decrementing
(define (f n)
  ; a = f(n-3), b = f(n-2), c = f(n-1)
  (define (iter a b c counter)
    (if (= counter 0)
        a
        ; on the next iteration
        (iter b                     ; f(n-2) = b
              c                     ; f(n-1) = c
              (+ c (* 2 b) (* 3 a)) ; f(n) = c + 2b + 3a
              (- counter 1))))      ; decrement counter
  (iter 0 1 2 n)) ; f(0) = 0, f(1) = 1, f(2) = 2

; iterative, counter incrementing
(define (f n)
  (define (iter n-1 n-2 n-3 counter)
    (if (= counter n)
        n-1 ; final result of the computation
        (iter (+ n-1 (* 2 n-2) (* 3 n-3)) ; f(n)
              n-1
              n-2 
              (+ 1 counter))))
  (iter 2 1 0 2)) ; n-1 = f(2) = 2, n-2 = f(1) = 1, n-3 = f(0) = 0, last computed term = f(2)

(f 5)
; 25

; ----

(define (pascal i j)
(if (or (= j 0) (= j i))
    1
    (+ (pascal (- i 1) (- j 1))
       (pascal (- i 1) j))))

; (pascal 3 0) => 1
; (pascal 3 1) => 3
; (pascal 3 2) => 3
; (pascal 3 3) => 1

; ----

; linear recursive
(define (expt b n)
  (if (= n 0)
    1
    (* b (expt b (- n 1)))))
; O(n) time, O(n) space

; linear iterative
(define (expt b n)
  (define (iter counter prod)
    (if (= counter 0)
        prod
        (iter (- counter 1) (* prod b))))
  (iter n 1))
; O(n) time, O(1) space

; recursive optimised
(define (fast-expt b n)
  (cond ((= n 0) 1)
    ((= (remainder n 2) 0) (square (fast-expt b (/ n 2))))
    (else (* b (fast-expt b (- n 1))))))
(define (square x) (* x x))
; O(log n) time, O(log n) space

(fast-expt 2 10)
; => (square (fast-expt 2 5))
; => (square (* 2 (fast-expt 2 4)))
; => (square (* 2 (square (fast-expt 2 2))))
; => (square (* 2 (square (square (fast-expt 2 1)))))
; => (square (* 2 (square (square (* 2 (fast-expt 2 0))))))
; => (square (* 2 (square (square (* 2 1))))))
; => (square (* 2 (square (square 2))))
; => (square (* 2 (square 4)))
; => (square (* 2 16))
; => (square 32)
; => 1024

; iterative optimised
(define (fast-expt b n)
  (define (iter a b n)
    (cond ((= n 0) a)
          ((even? n) (iter a (square b) (/ n 2)))
          (else (iter (* a b)
                b
                (- n 1)))))
  (iter 1 b n))
; O(log n) time, O(1) space

(fast-expt 2 10)
; => (iter 1 2 10)
; => (iter 1 4 5)
; => (iter 4 4 4)
; => (iter 4 16 2)
; => (iter 4 256 1)
; => (iter 1024 256 0)
; => 1024
