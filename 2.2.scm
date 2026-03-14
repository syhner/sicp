(define one-through-four (list 1 2 3 4))
; (cons 1 (cons 2 (cons 3 nil)))
; (1 2 3)

(car one-through-four) ; 1 = "get first element of list"
(cadr one-through-four) ; 2 = car(cdr(...))
(caddr one-through-four) ; 3 = car(cdr(cdr(...)))
(cadddr one-through-four) ; 4 = car(cdr(cdr(cdr(...))))
(cdr one-through-four) ; (2 3 4) = "get rest of list"
(cddr one-through-four) ; (3 4)
(cdddr one-through-four) ; (4)
; (cdar one-through-four) ; error = cdr(car(...)) = cdr(1)

(define (list-ref items n)
  (if (= n 0)
    (car items)
    (list-ref (cdr items) (- n 1))))

(list-ref one-through-four 2) ; 3

; tree-recursive
(define (length items)
  (if (null? items) ; check if it's the empty list
    0
    (+ 1 (length (cdr items)))))

(length one-through-four) ; 4

(define (append list1 list2)
  (if (null? list1)
      list2
      (cons (car list1)
            (append (cdr list1) list2))))

; tree-recursive
(define (reverse items)
  (if (null? items)
      items
      (append (reverse (cdr items)) (list (car items)))))

; variadic parameter list <> with lambda
; (define (f . w) (...)) <> (define f (lambda w (...)))
; (define (f x y . z) (...)) <> (define f (lambda (x y . z) (...)))
; (define (f x y . z) (...)) and (f 1 2 3 4 5 6) => x=1, y=2, z=(3 4 5 6)
(define (list . x) x)
(define list (lambda x x)) ; all arguments are collected into x as a list

; ----

(define (map proc items)
  (if (null? items)
    '() ; nil
    (cons (proc (car items))
          (map proc (cdr items)))))

(map (lambda (x) (* x x)) one-through-four) ; 1 4 9 16

(define (for-each proc items)
  (cond ((null? items)
    (newline))
  (else
    (proc (car items))
    (for-each proc (cdr items)))))

(for-each (lambda (x) (newline) (display x)) (list 57 321 88))

; ----

(define (count-leaves x)
  (cond ((null? x) 0)
    ((not (pair? x)) 1)
    (else (+ (count-leaves (car x))
             (count-leaves (cdr x))))))

; direct recursion
(define (tree-map f t)
  (cond ((null? t) '())
    ((not (pair? t)) (f t))
    else (cons (tree-map f (car t))
               (tree-map f (cdr t)))))

; using map
(define (tree-map f t)
  (map (lambda (t)
         (if (pair? t)
             (tree-map f t)
             (f t)))
       t))
        
(define (square-tree tree) (tree-map square tree))
; (square-tree tree) => squared-tree

(define (subsets s)
  (if (null? s)
      (list '())
      (let ((first-item (car s))
            (subsets-rest (subsets (cdr s))))
        (append subsets-rest
                (map (lambda (set) (cons first-item set))
                     subsets-rest)))))

(subsets '(1 2 3)) ; => '(() (3) (2) (2 3) (1) (1 3) (1 2) (1 2 3))

; ----

(define (filter predicate sequence)
  (cond ((null? sequence) '())
    ((predicate (car sequence))
      (cons (car sequence)
            (filter predicate (cdr sequence))))
    (else (filter predicate (cdr sequence)))))

(filter odd? (list 1 2 3 4 5)) ; => ( 1 3 5 )

(define (accumulate op initial sequence)
  (if (null? sequence)
    initial
    (op (car sequence)
        (accumulate op initial (cdr sequence)))))
      
(accumulate + 0 (list 1 2 3 4 5)) ; => 15

(define (enumerate-interval low high)
  (if (> low high)
    '()
    (cons low (enumerate-interval (+ low 1) high))))

(enumerate-interval 2 7) ; => ( 2 3 4 5 6 7 )

(define (enumerate-tree tree)
  (cond ((null? tree) '())
        ((not (pair? tree)) (list tree))
        (else (append (enumerate-tree (car tree))
                      (enumerate-tree (cdr tree))))))

(enumerate-tree (list 1 (list 2 (list 3 4)) 5)) ; => ( 1 2 3 4 5 )

(define (map f xs) ; xs is typically used to indicate a list
  (accumulate (lambda (x y) (cons (f x) y)) '() xs))
(define (append xs ys)
  (accumulate cons ys xs))
(define (length xs)
  (accumulate (lambda (x n) (+ n 1)) 0 xs))

; ----

(define (horner-eval x coefs)
  (accumulate (lambda (coef higher-terms)
                (+ (* higher-terms x) coef))
              0
              coefs))

; 1 + 3x + 5x^3 + x^5 at x=2
(horner-eval 2 (list 1 3 0 5 0 1)) ; => 79

(define (count-leaves t)
  (accumulate + 0 (map (lambda (x) 1)
                       (enumerate-tree t))))

; ----

(define (accumulate-n op init seqs)
  (if (null? (car seqs))
      '()
      (cons (accumulate op init (map car seqs))
            (accumulate-n op init (map cdr seqs)))))

(accumulate-n + 0 '((1 2 3) (4 5 6) (7 8 9) (10 11 12))) ; => (22 26 30)

(define (dot-product v w)
  (accumulate + 0 (map * v w)))

(define (matrix-*-vector m v)
  (map (lambda (u) (dot-product u v)) m))

(define (transpose mat)
  (accumulate-n cons '() mat))

(define (matrix-*-matrix m n)
  (let ((cols (transpose n)))
    (map (lambda (r)
          (map (lambda (c)
                  (dot-product r c))
                cols))
        m)))

(define mat '((1 2 3) (4 5 6) (7 8 9)))
(define identity '((1 0 0) (0 1 0) (0 0 1)))
(matrix-*-vector mat (car identity)) ; => (map car mat)
(matrix-*-matrix mat identity) ; => mat
(matrix-*-matrix identity mat) ; => mat

; ----

(define fold-right accumulate)

(define (fold-left op initial sequence)
  (define (iter result rest)
    (if (null? rest)
      result
      (iter (op result (car rest))
            (cdr rest))))
  (iter initial sequence))

(fold-right / 1 (list 1 2 3)) ; => 3/2
(fold-left / 1 (list 1 2 3)) ; => 1/6
(fold-right list '() (list 1 2 3)) ; => '(1 (2 (3 ())))
(fold-left list '() (list 1 2 3)) ; => '(((() 1) 2) 3)

; O(n^2)
(define (reverse xs)
  (fold-right (lambda (x y) (append y (list x))) '() xs))

; O(n)
(define (reverse xs)
  (fold-left (lambda (x y) (cons y x)) '() xs))

(reverse (list 1 2 3 4 5)) => '(5 4 3 2 1)
