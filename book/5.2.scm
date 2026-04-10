; this basic machine model constructed by make-new-machine is essentially a container for some registers and a stack, together with an execution mechanism that processes the controller instructions one by one.

; simulator for machines described in the register-machine language. the simulator is a scheme program with four interface procedures:

; constructs and returns a model of the machine with the given registers, operations, and controller.
(make-machine register-names operations controller)

; stores a value in a simulated register in the given machine
(set-register-contents! machine-model
                        register-name
                        value)

; returns the contents of a simulated register in the given machine
(get-register-contents ⟨machine-model⟩ ⟨register-name⟩)

; simulates the execution of the given machine, starting from the beginning of the controller sequence and stopping when it reaches the end of the sequence
(start machine-model)

(define gcd-machine
  (make-machine
    '(a b t)
    (list (list 'rem remainder) (list '= =))
    '(test-b (test (op =) (reg b) (const 0))
             (branch (label gcd-done))
             (assign t (op rem) (reg a) (reg b))
             (assign a (reg b))
             (assign b (reg t))
             (goto (label test-b))
             gcd-done)))


(set-register-contents! gcd-machine 'a 206)
(set-register-contents! gcd-machine 'b 40)
(start gcd-machine)
(get-register-contents gcd-machine 'a)
; 2

; ----

(define (make-machine register-names ops controller-text)
  (let ((machine (make-new-machine)))
    (for-each
      (lambda (register-name)
        ((machine 'allocate-register) register-name))
      register-names)
      ((machine 'install-operations) ops)
      ((machine 'install-instruction-sequence)
       (assemble controller-text machine))
      machine))

(define (make-register name)
  (let ((contents '*unassigned*))
    (define (dispatch message)
      (cond ((eq? message 'get) contents)
            ((eq? message 'set)
             (lambda (value) (set! contents value)))
            (else
             (error "Unknown request: REGISTER" message))))
    dispatch))

(define (get-contents register) (register 'get))
(define (set-contents! register value) ((register 'set) value))

; ----

; the flag register is used to control branching in the simulated machine. test instructions set the contents of flag to the result of the test (true or false). branch instructions decide whether or not to branch by examining the contents of flag

; the pc register determines the sequencing of instructions as the machine runs. this sequencing is implemented by the internal procedure execute. in the simulation model, each machine instruction is a data structure that includes a procedure of no arguments, called the instruction execution procedure, such that calling this procedure simulates executing the instruction. as the simulation runs, pc points to the place in the instruction sequence beginning with the next instruction to be executed. execute gets that instruction, executes it by calling the in-
; struction execution procedure, and repeats this cycle until there are no more instructions to execute (i.e., until pc points to the end of the instruction sequence)

; the assembler transforms the sequence of controller expressions for a machine into a corresponding list of machine instructions, each with its execution procedure. much like the evaluators there is an input language (i.e. the register-machine language) and we must perform an appropriate action for each type of expression in the language

; monitoring performance by measuring the number of stack operations and machine instructions

