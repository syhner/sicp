# SICP Quotes

## [1A Overview and Introduction to Lisp](lectures/1A.md)

> The real problems come when we try to build very, very large systems … nobody can really hold them in their heads all at once … the only reason that that’s possible is because there are techniques for controlling the complexity of these large systems.

> So in that sense, computer science is like an abstract form of engineering. It’s the kind of engineering where you ignore the constraints that are imposed by reality.

## [1B Procedures and Processes; Substitution Model](lectures/1B.md)

> The key to understanding complicated things is to know what not to look at, and what not compute, and what not to think.

## [2B Compound Data](lectures/2B.md)

> The real power is that you can pretend that you’ve made the decision and then later on figure out which one is right, which decision you ought to have made. And when you can do that, you have the best of both worlds.

> Once you have two things, you have as many things as you want.

## [3A Henderson Escher Example](lectures/3A.md)

> The set of data objects in Lisp is closed under the operation of forming pairs

> Lisp is a lousy language for doing any particular problem. What it’s good for is figuring out the right language that you want and embedding that in Lisp. That’s the real power of this approach to design.

> So what you have is, at each level, the objects that are being talked about are the things that were erected at the previous level.

> The design process is not so much implementing programs as implementing languages. And that’s really the power of Lisp.

## [3B Symbolic Differentiation; Quotation](lectures/3B.md)

> In order to make a system that’s robust, it has to be insensitive to small changes, that is, a small change in the problem should lead to only a small change in the solution. There ought to be a continuity. The space of solutions ought to be continuous in this space of problems.

## [4A Pattern Matching and Rule-based Substitution](lectures/4A.md)

> Instead of bringing the rules to the level of the computer by writing a program that is those rules ... we're going to bring the computer to the level of us

## [4B Generic Operators](lectures/4B.md)

> It's called data-directed programming ... the data objects themselves ... are carrying with them the information about how you should operate on them

## [6A Streams, Part 1](lectures/6A.md)

> Going back to this fundamental principle of computer science that in order to control something, you need the name of it.

> The thing that delay did for us was to de-couple the apparent order of events in our programs from the actual order of events that happen in the machine

## [7A Metacircular Evaluator, Part 1](lectures/7A.md)

> Defintions are inessential in a mathematical sense for doing all the things we need to do for computing

> The number of solutions is not in the form of the equations. All three sets have the same form. The number of solutions is in the content ... I can't tell by the form of a definition if it makes sense, only by its detailed content.

> What lisp is is the fixed point of the process which says, if i knew what Lisp was and substituted it in for eval and apply and so on, on the right hand sides of all those recursion equations then ... the left hand side would also be Lisp.

## [7B Metacircular Evaluator, Part 2](lectures/7B.md)

> The reason why the first Lisps were implemented this way, is it's the sort of obvious, accidental implementation. And, of course, as usual, people got used to it and liked it. And there were some people said, this is the way to do it. Unfortunately that causes some serious problems. The most important, serious problem in using dynamic binding is that there's a modularity crisis that's involved in it. If two people are working together on some big system, then an important thing to want is that the names used by each one don't interfere with the names of the other. It's important that when I invent some segment of code that no one can make my code stop working by using my names that I use internal to my code, internal to his code. However, dynamic binding violates that particular modularity constraint in a clear way ... So I no longer have a quantifier ... The lambda symbol is supposed to be a quantifier

> The thing is that returning procedures as values cover all of those problems. And so it's the simplest mechanism that gives you the best modularity, gives you all of the known modularity mechanisms.

## [8A Logic Programming, Part 1](lectures/8A.md) 

> The other thing that you saw is once you have the interpreter in your hands, you have all this power to start playing with the language. So you can make it dynamically scoped, or you can put in normal order evaluation, or you can add new forms to the language, whatever you like. Or more generally, there's this notion of metalinguistic abstraction, which says that part of your perspective as an engineer, as a software engineer, but as an engineer in general is that you can gain control of complexity by inventing new languages sometimes. See, one way to think about computer programming is that it only incidentally has to do with getting a computer to do something. Primarily what a computer program has to do with, it's a way of expressing ideas with communicating ideas. And sometimes when you want to communicate new kinds of ideas, you'd like to invent new modes of expressing that.

## [9A Register Machines](lectures/9A.md)

> Use what you learn from studying the problem you want to solve to put in the mechanisms needed to solve it in the computer you're building, no more no less. In may be that the problem you're trying to solve is everybody's problem, in which case you have to build in a universal interpreter of some language. But you shouldn't put any more in than required to build the universal interpeter.

## [9B Explicit-control Evaluator](lectures/9B.md)

> LISP is not good for solving any particular problems. What LISP is good for is contructing within it the right language to solve the problems you want to solve.

> If we implement lisp in terms of a register machine, then everything ought to become, at this point, completely concrete. All the magic should go away.

> A lot of people think [that] the reason you need a stack and recursion in an evaluator is because you might be evaluating recursive procedures ... the reason that you need recursion in the evaluator is because the evaluation process, itself, is recursive.

> We've reduced evaluating F,X,Y in environment E0 to evaluate plus A B in E1. And notice, nothing's on the stack, right? It's a reduction. At this point, the machine does not contain, as part of its state, the fact that it's in the middle of evaluating some procedure called F ... There's no accumulated state ... That's the meaning of, when we used to write in the substitution model, this expression reduces to that expression. 

> You have to make these new environment frames but you dont't have to hang onto them when you're done. They can be garbage collected or the space can be reused automatically ... so these procedures really are iterative procecdures

> ... this evaluator is managing to take these procedures and execute some of them iteratively and some of them recursively, even though, as syntactically, they look like recursive procedures. How's it managing to do that? Well, the basic reason it's managing to do that is the evaluator is set up to save only what it needs later. So, for example, at the point where you've reduced evaluating an expression and an environment to applying a procedure to some arguments, it doesn't need that original environment anymore because any environment stuff will be packaged inside the procedures where the application's going to happen.

> Here's the actual thing that's making it [the evaluator] tail recursive. Remember, it's the restore of continue. It's saying when I go off to evaluate the procedure body, I should tell eval to come back to the place where that original evaluation was supposed to come back to.

## [10A Compilation](lectures/10A.md)

> In interpretation, we're raising the machine to the level of our language, like Lisp. In compilation we're taking our program and lowering it to the language that's spoken by the machine.

> The compiler can produce code that will execute more efficiently. The essential reason for that is that if you think about the register operations that are running, the interpreter has to produce register operations which, in principle, are going to be general enough to execute any Lisp procedure. Whereas the compiler only has to worry about producing a special bunch of register operations for, for doing the particular Lisp procedure that you've compiled.

> Or another way to say that is that the interpreter is a general purpose simulator, that when you read in a Lisp procedure, then those can simulate the program described by that, by that procedure. So the interpreter is worrying about making a general purpose simulator, whereas the compiler, in effect, is configuring the thing to be the machine that the interpreter would have been simulating. So the compiler can be faster.

> already that's going to be more efficient than the evaluator. if you watch the evaluator run, it's not only generating the register operations we wrote down, it's also doing things to decide which ones to generate

> what the evaluator's doing is simultaenously analyzing the code to see what to do and running these operations ... in the compiler, it's happened once.

> So in some sense, you don't want unev and exp at all. See what they really are in some sense, those aren't registers of the actual machine that's supposed to run, those are registers that have to do with arranging the thing that can simulate that machine.

> ... the evaluator has to be maximally pessimistic, because as far from its point of view it's just going off to evaluate something so it better save what it's going to need later. But once you've done the analysis, the compiler is in a position to say, well, what actually did I need to save? ... it doesn't need to be as careful as the evaluator, because it knows what it actually needs.
