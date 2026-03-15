(load "2.2.scm")

(define a 1)
; syntactic entity and semantic entity
(list 'a a) ; => (a 1)

(car '(a b c)) ; => 'a
(cdr '(a b c)) ; => '(b c)

'() ; the empty list

; returns sublist of the list beginning with the first occurence of item
(define (memq item x)
  (cond ((null? x) #f)
        ((eq? item (car x)) x)
        (else (memq item (cdr x)))))

(memq 'apple '(pear banana prune)) ; #f
(memq 'apple '(x (apple sauce) y apple pear)) ; (apple pear)

(car ''abracadabra)
; => (car (quote (quote abracadabra)))
; => (car '(quote abracadabra))
; => 'quote

; ----

; symbolic differentiation through codifying rules

(define (deriv expr var)
  (cond ((number? expr) 0)
        ((variable? expr)
        (if (same-variable? expr var) 1 0))
        ((sum? expr)
        (make-sum (deriv (addend expr) var)
                  (deriv (augend expr) var)))
        ((product? expr)
        (make-sum (make-product (multiplier expr)
                                (deriv (multiplicand expr) var))
                  (make-product (deriv (multiplier expr) var)
                                (multiplicand expr))))
        (else (error 'deriv "unknown expr type" expr))))

; ----

; representing sets

(define (element-of-set? x set)
  (and (not (null? set))
      (or (equal? x (car set))
          (element-of-set? x (cdr set)))))

(define (adjoin-set x set)
  (if (element-of-set? x set)
      set
      (cons x set)))

(define (intersection-set set1 set2)
  (cond ((null? set1) '())
        ((null? set2) '())
        ((element-of-set? (car set1) set2)
        (cons (car set1)
              (intersection-set (cdr set1) set2)))
        (else (intersection-set (cdr set1) set2))))

(define (union-set set1 set2)
  (accumulate adjoin-set set2 set1))

; ----

; representing trees

(define (entry tree) (car tree))
(define (left-branch tree) (cadr tree))
(define (right-branch tree) (caddr tree))
(define (make-tree entry left right)
  (list entry left right))
; or simply
(define make-tree list)
(define entry car)
(define left-branch cadr)
(define right-branch caddr)

(define (element-of-set? x set)
  (cond ((null? set) false)
        ((= x (entry set)) true)
        ((< x (entry set))
            (element-of-set? x (left-branch set)))
        ((> x (entry set))
            (element-of-set? x (right-branch set)))))

; ----

(define (lookup given-key set-of-records)

(cond ((null? set-of-records) #f)
      ((equal? given-key (key (car set-of-records)))
       (car set-of-records))
      (else (lookup given-key (cdr set-of-records)))))

(define key car)
(lookup 3 '((1 flour) (2 water) (3 salt))) ; => '(3 salt)

; ----

; huffman encoding trees

(define (make-leaf symbol weight) (list 'leaf symbol weight))
(define (leaf? object) (eq? (car object) 'leaf))
(define symbol-leaf cadr)
(define weight-leaf caddr)

(define (make-code-tree left right)
  (list left
        right
        (append (symbols left) (symbols right))
        (+ (weight left) (weight right))))
(define left-branch car)
(define right-branch cadr)

(define (symbols tree)
  (if (leaf? tree)
      (list (symbol-leaf tree))
      (caddr tree)))
(define (weight tree)
  (if (leaf? tree)
      (weight-leaf tree)
      (cadddr tree)))
