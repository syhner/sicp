(define (sum-of-squares x y) (+ (square x) (square y)))

(define (f a) (sum-of-squares (+ a 1) (* a 2)))

(f 5)
; => (sum-of-squares (+ 5 1) (* 5 2))
; => (+ (square 6) (square 10))
; => 136

;                 _____________________
; global env --> | sum-of-squares: ... |
;                | square: ...         |
;                | f: ...              |<------------+
;                |_____________________|<+           |
;   (f 5)        ^           ^           |           |
;                |           |           |           |
;          E1->[a: 5]  E2->[x: 6]  E3->[x: 6]  E4->[x:10]
;                          [y: 7]
;   (sum-of-squares  (+ (square x)   (* x x)     (* x x)
;     (+ a 1)           (square y))
;     (* a 2)
