hedgehog
========

<img src="hedgehog-logo.png" width="307" align="right"/>

> Hedgehog will eat all your bugs.

[Hedgehog](http://hedgehog.qa/) is a modern property based testing
system in the spirit of QuickCheck, originally written in Haskell,
but now also available in R. One of the key benefits of Hedgehog is
integrated shrinking of counterexamples, which allows one to quickly
find the cause of bugs, given salient examples when incorrect
behaviour occurs.

Features
========

- Integrated shrinking, shrinks obey invariants by construction.
- Generators can be combined to build complex and interesting
  structures
- Abstract state machine testing.

Example
=======

To get a quick look of how Hedgehog feels, here's an example
showing some of the properties a function which reverses a vector
should have. We'll be testing the `rev` function from
`package:base`.


```r
forall( gen.c( gen.sample(1:100) ), function(xs) identical ( rev(rev(xs)), xs))
```

```
## Passed after 100 tests
```

The property above tests that if I reverse a vector twice, the
result should be the same as the vector that I began with.
Hedgehog has generated 100 examples, and checked that this
property holds in all of these cases.

We use the term forall (which comes from predicate logic) to say
that we want the property to be true no matter what the input to
the tested function is. The first argument to forall is function
to generate random values (the generator); while the second is
the property we wish to test.

The property above doesn't actually completely specify that the
`rev` function is accurate though, as one could replace `rev` with
the identity function and still observe this result. We will therefore
write one more property to thouroughly test this function.


```r
forall( list( as = gen.c( gen.sample(1:100) )
            , bs = gen.c( gen.sample(1:100) ))
      , function(as,bs) identical ( rev(c(as, bs)), c(rev(bs), rev(as)))
)
```

```
## Passed after 100 tests
```

This is now a well tested reverse function. Notice that the property
function now accepts two arguments: `as` and `bs`. A list of generators
in Hedgehog is treated as a generator of lists, and shrinks both sides
independently. We do however do our best to make sure that properties
can be specified naturally if the generator is specified in this manner
as a list of generators.

Now let's look at an assertion which isn't true so we can see what a
counterexamples looks like


```r
forall( gen.c( gen.sample(1:100) ), function(xs) identical ( rev(xs), xs))
```

```
##
## Falsifiable after 1 tests, and 8 shrinks
## Predicate is falsifiable
##
## Counterexample:
## [1] 1 2
```

This test says that the reverse of a vector should equal the vector,
which is obviously not true for all vectors. Here, the counterexample
is shrunk from an original test value. The smallest possible value
for which this doesn't hold is shown to the user.

Generators
==========

Hedgehog exports some basic generators and plenty combinators for
making new generators. Here's an example which produces a floating
point value between -10 and 10, shrinking to the median 0.


```r
gen.unif( from = -10, to = 10 )
```

```
## Hedgehog generator:
## A generator is a function which produces random trees
## using a size parameter to scale it.
##
## Example:
## [1] -2.085815
## Shrinks:
## [1] 0
## [1] -0.08581477
## [1] -1.085815
```

Although only three possible shrinks are shown above, these are
actually just the first layer of a rose tree of possible shrinks.
This integrated shrinking property is a key component of hedgehog,
and gives us a substantial change of reducing to a minimum possible
counterexample.


```r
forall(list(a = gen.sample(1:100), b = gen.sample(1:100)), function(a, b) a < b + 1)
```

```
##
## Falsifiable after 2 tests, and 10 shrinks
## Predicate is falsifiable
##
## Counterexample:
## $a
## [1] 2
##
## $b
## [1] 1
```

The generators `gen.c`, `gen.sample`, and `gen.unif`, are related to
standard R functions: `c`, to create a vector; `sample`, to sample
from a list or vector; and `runif`, to sample from a uniform
distribution. We try to maintain a relationship to R's well known
functions inside Hedgehog.

Generators are also monads, meaning that one can use the result of a
generator to build a generator. An example of this is a list generator,
which first randomly chooses a length, then builds a list of said
length.

The `gen.map` function can be used to apply an arbitrary function to
the output of a generator, while `gen.with` is useful in chaining the
results of a generator.

In the following example, we'll create a generator which builds two
lists of length `n`, then turn them into a `data.frame` with `gen.map`.


```r
gen.df.of <- function ( n )
  gen.map (
    as.data.frame,
    list( as = gen.c.of(n, gen.sample(1:10) )
        , bs = gen.c.of(n, gen.sample(10:20) )
        )
    )

forall( gen.df.of(5), function(df) nrow(df) == 5)
```

```
## Passed after 100 tests
```

While this is good, but we would also like to be able to create
`data.frames` with a varying number of rows. Here, we'll again
test a property which is false in order to show how hedgehog
will find the minimum shrink.


```r
gen.df <-
  gen.with (
    gen.sample (1:100)
    , gen.df.of
  )

forall( gen.df, function(x) nrow(x) == 1)
```

```
##
## Falsifiable after 1 tests, and 9 shrinks
## Predicate is falsifiable
##
## Counterexample:
##   as bs
## 1  1 10
## 2  1 10
```

State Machine Testing
=====================

R is a multi-paradigm programming language, while all the tests we
have seen so far have tested functions which have no side effects
(pure functions).

To deal with more complex situations which might arise in practice,
Hedgehog also supports testing stateful system using a state machine
model under random actions.

The general idea is that we can generate a model of the system, with
requirements and post-conditions for every action we can take. With
a random sequence of actions, we can test our model of the system
against the true implementation. Hedgehog will then be able to
identify inconsistencies between the true implementation and the
model, from which the programmer can ask whether this is a bug in the
model or a true bug in the system.

John Hughes has a serious of excellent [talks][jh-dropbox] regarding
testing of state based and non-deterministic systems using QuviQ's
proprietary QuickCheck implementation, which has been using these
techniques to great effect for many years.

Hedgehog's current implementation in R is still quite young, and
not nearly as feature rich, but does still allow for interesting
properties in stateful systems to be investigated.

  [jh-dropbox]: https://www.youtube.com/watch?v=H18vxq-VsCk
