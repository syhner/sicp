; system structure - objects vs streams

; objects that can change and yet maintain their identity
; substitution model -> environment model
; grappling with time and concurrent execution
; state => behaviour changes due to history (e.g. storing current balance instead of entire history of transactions)
; "closely coupled subsystems that are only loosely coupled to other subsystems"

(define balance 100)
(define (withdraw amount)
  (if (>= balance amount)
    (begin (set! balance (- balance amount))
           balance)
    "Insufficient funds"))

(withdraw 25) ; => 75
(withdraw 25) ; => 50
(withdraw 60) ; => "Insufficient funds"
(withdraw 15) ; => 35

(define new-withdraw
  (let ((balance 100))
    (lambda (amount)
      (if (>= balance amount)
          (begin (set! balance (- balance amount))
                 balance)
          "Insufficient funds"))))

(define (make-account balance)
  (define (withdraw amount)
    (if (>= balance amount)
        (begin (set! balance (- balance amount))
               balance)
        "Insufficient funds"))
  (define (deposit amount)
    (set! balance (+ balance amount))
    balance)
  (define (dispatch m)
    (cond ((eq? m 'withdraw) withdraw)
          ((eq? m 'deposit) deposit)
          (else (error 'make-account "unknown request" m))))
  dispatch)

(define acc (make-account 100))
((acc 'withdraw) 50) ; => 50
((acc 'withdraw) 60) ; => "Insufficient funds"
((acc 'deposit) 40) ; => 90
((acc 'withdraw) 60) ; => 30
((acc 'foo)) ; =!> "unknown request: foo"

; functional programming is without assignments
; imperative programming makes exstensive use of assignments
; programming with assignment forces us to carefully consider the relative orders of the assignments to make sure that each statement is using the correct version of the variables that have been changed
; referentially transparent => “equals can be substituted for equals” in an expression without changing the value of it e.g. (+ 4 2) = 6\

; not the same (only because data gets modified in the data object)
(define peter-acc (make-account 100)) 
(define paul-acc (make-account 100))

; same through aliasing
(define peter-acc (make-account 100))
(define paul-acc peter-acc)

