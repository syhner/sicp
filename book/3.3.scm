; already used constructors and selectors
; now we want mutators to have objects with changing state (mutable data objects)

; > admitting change to our language requires that a compound object must have an “identity” that is something diﬀerent from the pieces from which it is composed. In Lisp, we consider this “identity” to be the quality that is tested by eq?, i.e., by equality of pointers. Since in most Lisp implementations a pointer is essentially a memory address, we are “solving the problem” of defining the identity of objects by stipulating that a data object “itself ” is the information stored in some particular set of memory locations in the computer. 

; assignment and mutation are equipotent — each can be implemented in terms of the other
(define (cons x y)
  (define (set-x! v) (set! x v))
  (define (set-y! v) (set! y v))
  (define (dispatch m)
    (cond ((eq? m 'car) x)
          ((eq? m 'cdr) y)
          ((eq? m 'set-car!) set-x!)
          ((eq? m 'set-cdr!) set-y!)
          (else (error 'cons "undefined operation" m))))
  dispatch)

(define (car p) (p 'car))
(define (cdr p) (p 'cdr))
(define (set-car! p v) ((p 'set-car!) v) p)
(define (set-cdr! p v) ((p 'set-cdr!) v) p)

; implementing a queue as a pair of front-pointer and rear-pointer to a list for O(1) insertion

(define front-ptr car)
(define rear-ptr cdr)
(define set-front-ptr! set-car!)
(define set-rear-ptr! set-cdr!)

(define (empty-queue? queue)
(null? (front-ptr queue)))

(define (make-queue) (cons '() '()))
(define (front-queue queue)
(if (empty-queue? queue)
    (error "FRONT called with an empty queue" queue)
    (car (front-ptr queue))))

(define (insert-queue! queue item)
(let ((new-pair (cons item '())))
  (cond ((empty-queue? queue)
        (set-front-ptr! queue new-pair)
        (set-rear-ptr! queue new-pair)
        queue)
        (else
          (set-cdr! (rear-ptr queue) new-pair)
          (set-rear-ptr! queue new-pair)
          queue))))

(define (delete-queue! queue)
(cond ((empty-queue? queue)
       (error "DELETE! called with an empty queue" queue))
      (else (set-front-ptr! queue (cdr (front-ptr queue)))
            queue)))

; 1-dimensional tables

(define (lookup key table)
(let ((record (assoc key (cdr table))))
  (if record
      (cdr record)
      #f)))

(define (assoc key records)
(cond ((null? records) #f)
      ((equal? key (caar records)) (car records))
      (else (assoc key (cdr records)))))

(define (insert! key value table)
(let ((record (assoc key (cdr table))))
  (if record
      (set-cdr! record value)
      (set-cdr! table
                (cons (cons key value)
                      (cdr table))))))

; headed list which allows for inserting a new first-entry
(define (make-table) (list '*table*))

(define t (make-table))
(lookup 'a t) ; => #f
(insert! 'a 1 t)
(lookup 'a t) ; => 1

; 2-dimensional tables

(define (lookup key-1 key-2 table)
  (let ((subtable (assoc key-1 (cdr table))))
    (if subtable
        (let ((record (assoc key-2 (cdr subtable))))
          (if record
              (cdr record)
              #f))
        #f)))

(define (insert! key-1 key-2 value table)
  (let ((subtable (assoc key-1 (cdr table))))
    (if subtable
        (let ((record (assoc key-2 (cdr subtable))))
          (if record
              (set-cdr! record value)
              (set-cdr! subtable
                        (cons (cons key-2 value)
                              (cdr subtable)))))
        (set-cdr! table
                  (cons (list key-1 (cons key-2 value))
                        (cdr table))))))

(define t (make-table))
(lookup 'a 'b t) => ; #f
(insert! 'a 'b 1 t)
(lookup 'a 'b t) => ; 1

; simulating digital circuits and relations (e.g. F=ma where any change in one of the three should cause a change in the other two) with connectors and constraints through a declarative approach
