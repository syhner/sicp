; conventional computer memory can be thought of as an array of cubbyholes, each of which can contain a piece of information. each cubbyhole has a unique name, called its address/location

; to model memory we use a vector — a compound data object whose individual elements can be accessed by means of an integer index in an amoun t of time that is independent of the index.

; returns the nth element of the vector
(vector-ref <vector> <n>)

; sets the nth element of the vector to the designated value
(vector-set! <vector> <n> <value>) 

; this access can be implemented through the use of address arithmetic to combine a base address that specifies the beginning location of a vector in memory with an index that specifies the oﬀset

; we need a representation for objects other than pairs (i.e. numbers, symbols) to distinguish data types. the different ways to do this reduce to using typed pointers (pointer with data types where the data types are included at the primitive machine level rather than through lists)

; two data objects are considered the same (eq?) if their pointers are identical (some consideration if we want to consider the same number with different pointers equal, or to guarantee never storing the same number at more than one address)

; numbers too large for the space allocated for a single pointer can have a different data type (e.g. bignum) for which the pointer designates a list i which the parts of the number are stored
