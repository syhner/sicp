(const "abc") ; is the string "abc"
(const abc) ; is the symbol abc
(const (a b c)) ; is the list (a b c)
(const ()) ; is the empty list

; each input is either (reg register-name) or (const constant-value)

(assign register-name (reg register-name))          ; assign value to a register
(assign register-name (const constant-value))       ; assign value to a register
(assign register-name (op operation-name) . inputs) ; e.g. (assign t (op -) (reg t) (reg b))
(perform (op operation-name) . inputs)              ; perform action (e.g. read/print)
(test (op operation-name) . inputs)                 ; e.g. (test (op =) (reg a) (reg b))
(branch (label label-name))                         ; conditional goto
(goto (label label-name))                           ; unconditional goto

; the use of registers to hold labels
(assign register-name (label label-name)) ; store a label address/reference in a register
(goto (reg register-name))                ; jump to the label stored in a register

; instructions to use the stack
(save register-name)    ; push the register's current value onto the stack
(restore register-name) ; pop the top stack value back into the register
