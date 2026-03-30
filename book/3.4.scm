; > by introducing assignment we are forced to admit time into our computational models

; one possible restriction on concurrency would stipulate that no twooperations that change any shared state variables can occur at the same time

; a less stringent restriction on concurrency would ensure that a concurrent system produces the same result as if the processes had run sequentially in some order (as there can be >1 possible correct results from different orders)

(define x 10)
(parallel-execute
  (lambda () (set! x (* x x)))
  (lambda () (set! x (+ x 1))))
; x =?> [11 100 101 110 121] ; 5 possible values

; P events (a<b<c<d in time)
; P1: read x for first x
; P2: read x for second x
; P3: compute product x * x
; P4: write result

; Q events (x<y<z in time)
; Q1: read x
; Q2: compute sum x + 1
; Q3: write result

; 7C4 * 4C4 = 35 possible orderings of events
; e.g. (P1,Q1,Q2,P2,P3,P4,Q3) => x=11

; serialization creates distinguished sets of procedures such that only one execution of a procedure in each serialized set is permitted to happen at a time
(define x 10)
(let ((s (make-serializer)))
  (parallel-execute
   (s (lambda () (set! x (* x x))))
   (s (lambda () (set! x (+ x 1))))))
; x =?> [101 121] ; 2 possible values

; 2! = 2 possible orderings of events 

; implementing serializers

; acquire mutex, run p, release mutex
(define (make-serializer)
  (let ((mutex (make-mutex)))
    (lambda (p)
      (define (serialized-p . args)
        (mutex 'acquire)
        (let ((val (apply p args)))
          (mutex 'release)
          val)))
        serialized-p))

; cell is initalised to (false)
; to acquire the mutex, we test the cell
;   cell is (false) => mutex is available => acquire mutex (set to true)
;   cell is (true) => mutex is unavailable => wait in a loop
; to release the mutex, cell is set back to (false)
(define (make-mutex)
  (let ((cell (list #f)))
    (define (the-mutex m)
      (cond ((eq? m 'acquire)
            (if (test-and-set! cell)
                (the-mutex 'acquire))) ; retry
            ((eq? m 'release) (clear! cell))))
      the-mutex))

; cell is a 1 element list mutex
(define (clear! cell) (set-car! cell #f))

; naively
(define (test-and-set! cell)
  (if (car cell) true (begin (set-car! cell true) #f)))

; if executing concurrent processes on a sequential processor using a time-slicing mechanism that cycles through the processes, permitting each process to run for a short time before interrupting it and moving on to the next process. in that case, we can disable time slicing during the testing and setting
(define (test-and-set! cell)
  (without-interrupts
    (lambda ()
      (if (car cell)
          true
          (begin (set-car! cell true)
                 false)))))

; multiprocessing computers provide instructions that support atomic operations directly in hardwar

; multi-process mutex (semaphore)
(define (make-semaphore n)
  (let ((count n)
        (count-mutex (make-mutex))
        (queue-mutex (make-mutex)))
    (queue-mutex 'acquire) ; starts out locked
    (lambda (m)
      (cond ((eq? m 'acquire)
             (count-mutex 'acquire)
             (set! count (- count 1))
             (when (< count 0)
               (count-mutex 'release)
               (queue-mutex 'acquire))
             (count-mutex 'release))
            ((eq? m 'release)
             (count-mutex 'acquire)
             (set! count (+ count 1))
             (if (<= count 0)
                 (queue-mutex 'release)
                 (count-mutex 'release)))
            (else (error 'make-semaphore "unexpected message" m))))))e

; avoiding some deadlocks by numbering and selectively acquiring
; deadlock recovery by selectively backing out then retrying

; > there may be cases where the “real” value (e.g. account balance) are irrelevant or meaningless except at special synchronization points
; > the complexities we encounter in dealing with time and state in our computational models may in fact mirror a fundamental complexity of the physical universe
