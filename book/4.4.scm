; > Because matching is generally very expensive, we would like to avoid applying the full matcher to every element of the data base. This is usually arranged by breaking up the process into a fast, coarse match and the final match. The coarse match filters the data base to produce a small set of candidates for the final match. With care, we can arrange our data base so that some of the work of coarse matching can be done when the data base is constructed rather then when we want to select the candidates. This is called indexing the data base.

; we could formulate a query in either of two logically equivalent forms:
(and (job ?x (computer programmer)) (supervisor ?x ?y))
(and (supervisor ?x ?y) (job ?x (computer programmer)))
; if there are more supervisors than programmers, it is better to use the first form rather than the second because the database must be scanned for each intermediate result (frame) produce by the first clause of the and
