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

; --- simulating digital circuits

; event-driven simulation, in which actions (events) trigger further events that happen at a later time

; constructors: wires which will 'hold' the signal
(define (make-wire)
(let ((signal-value 0) (action-procedures '()))
  (define (set-signal! s)
    (if (not (= signal-value s))
        (begin (set! signal-value s)
               (call-each action-procedures))))
  (define (add-action! proc)
    (set! action-procedures (cons proc action-procedures))
    (proc))
  (define (dispatch m)
    (cond ((eq? m 'get-signal) signal-value)
          ((eq? m 'set-signal!) set-signal!)
          ((eq? m 'add-action!) add-action!)
          (else (error "Unknown operation: WIRE" m))))
  dispatch))

; selectors
(define (get-signal wire) (wire 'get-signal))

; mutators
(define (get-signal wire) (wire 'get-signal))
(define (set-signal! wire s) ((wire 'set-signal!) s))
(define (add-action! wire a) ((wire 'add-action!) a))

; logic gates (procedures) will enforce the correct relationships between signals in wires

(define (logical-not a) (- 1 a))
(define inverter-delay 2)
(define (inverter input output)
(define (action)
  (let ((new-signal (logical-not (get-signal input))))
    (after-delay
     inverter-delay
     (lambda () (set-signal! output new-signal)))))
(add-action! input action))

(define (logical-and a b) (* a b))
(define and-gate-delay 3)
(define (and-gate a b out)
(define (action)
  (let ((new-signal (logical-and (get-signal a) (get-signal b))))
    (after-delay
     and-gate-delay
     (lambda () (set-signal! out new-signal)))))
(add-action! a action)
(add-action! b action))

(define (logical-or a b) (- (+ a b) (* a b)))
(define or-gate-delay 5)
(define (or-gate a b out)
(define (action)
  (let ((new-signal (logical-or (get-signal a) (get-signal b))))
    (after-delay
     or-gate-delay
     (lambda () (set-signal! out new-signal)))))
(add-action! a action)
(add-action! b action))

; helpers
(define (call-each procs) (for-each (lambda (f) (f)) procs))

; agenda

; add to agenda
(define (after-delay delay-time action)
(add-to-agenda! (+ delay-time (simulation-time the-agenda))
                action
                the-agenda))

; for as long as there are procedures in the agenda, execute them in sequence
(define (propagate)
(unless (empty-agenda? the-agenda)
  (let ((first-item (first-agenda-item the-agenda)))
    (first-item)
    (remove-first-agenda-item! the-agenda)
    (propagate))))

; debugging
(define (probe name wire)
(add-action!
 wire
 (lambda ()
   (display (format "\n~a ~a New-value = ~a"
                    name (simulation-time the-agenda) (get-signal wire))))))

; ---- digital circuit example

(define the-agenda (make-agenda))
(define inverter-delay 2)
(define and-gate-delay 3)
(define or-gate-delay 5)

(define input-1 (make-wire))
(define input-2 (make-wire))
(define sum (make-wire))
(define carry (make-wire))

(probe 'sum sum)
; sum 0 New-value = 0
(probe 'carry carry)
; => carry 0 New-value = 0

(define a (make-wire))
(define b (make-wire))
(define c (make-wire))
(define d (make-wire))
(define e (make-wire))
(define s (make-wire))

(define (half-adder a b s c)
(let ((d (make-wire)) (e (make-wire)))
  (or-gate a b d)
  (and-gate a b c)
  (inverter c e)
  (and-gate d e s)))

(half-adder input-1 input-2 sum carry)
(set-signal! input-1 1)
(propagate)
; sum 8 New-value = 1

(set-signal! input-2 1)
(propagate)
; carry 11 New-value = 1
; sum 16 New-value = 0

; --- implementing the agenda

; each time segment is a pair of time and the queue of procedures to be run at that time
(define make-time-segment cons)
(define segment-time car)
(define segment-queue cdr)

(define (make-agenda) (list 0))
(define (current-time agenda) (car agenda))
(define (set-current-time! agenda time)
(set-car! agenda time))
(define (segments agenda) (cdr agenda))
(define (set-segments! agenda segments)
(set-cdr! agenda segments))
(define (first-segment agenda) (car (segments agenda)))
(define (rest-segments agenda) (cdr (segments agenda)))

(define (empty-agenda? agenda) (null? (segments agenda)))

(define (add-to-agenda! time action agenda)
(define (belongs-before? segments)
  (or (null? segments)
      (< time (segment-time (car segments)))))
(define (make-new-time-segment time action)
  (let ((q (make-queue)))
    (insert-queue! q action)
    (make-time-segment time q)))
(define (add-to-segments! segments)
  (if (= (segment-time (car segments)) time)
      (insert-queue! (segment-queue (car segments)) action)
      (let ((rest (cdr segments)))
        (if (belongs-before? rest)
            (set-cdr! segments
                      (cons (make-new-time-segment time action)
                            (cdr segments)))
            (add-to-segments! rest)))))
(let ((segments (segments agenda)))
  (if (belongs-before? segments)
      (set-segments!
       agenda
       (cons (make-new-time-segment time action) segments))
      (add-to-segments! segments))))

(define (remove-first-agenda-item! agenda)
(let ((q (segment-queue (first-segment agenda))))
  (delete-queue! q)
  (if (empty-queue? q)
      (set-segments! agenda (rest-segments agenda)))))

(define (first-agenda-item agenda)
(if (empty-agenda? agenda)
    (error "Agenda is empty: FIRST-AGENDA-ITEM")
    (let ((first-seg (first-segment agenda)))
      (set-current-time! agenda
                         (segment-time first-seg))
      (front-queue (segment-queue first-seg)))))

; ---- propagation of constraints

; modelling relations e.g. 9C = 5(F-32) so that the same network is being used to compute C given F and F given C. this nondirectionality of computation is the distinguishing feature of constraint-based systems.

; primitive elements: primitive constraints
; means of combination: constraint networks in which constraints are joined by connectors (objects that hold a value in one or more constraints)
; means of abstraction: achieved through procedures as values

(define C (make-connector))
(define F (make-connector))
(celsius-fahrenheit-converter C F)

(define (celsius-fahrenheit-converter c f)
(let ((u (make-connector))
      (v (make-connector))
      (w (make-connector))
      (x (make-connector))
      (y (make-connector)))
  (multiplier c w u)
  (multiplier v x u)
  (adder v y f)
  (constant 9 w)
  (constant 5 x)
  (constant 32 y)))

(probe "Celsius temp" C)
(probe "Fahrenheit temp" F)
(set-value! C 25 'user)
; Probe: Celsius temp = 25
; Probe: Fahrenheit temp = 77

(set-value! F 212 'user)
; Error! Contradiction (77 212)

(forget-value! C 'user)
; Probe: Celsius temp = ?
; Probe: Fahrenheit temp = ?

(set-value! F 212 'user)
; Probe: Fahrenheit temp = 212
; Probe: Celsius temp = 100

; implementation can be found in the book
