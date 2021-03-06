% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/state.R
\name{command}
\alias{command}
\title{State based testing commands}
\usage{
command(
  title,
  generator,
  execute,
  require = function(state, ...) T,
  update = function(state, output, ...) state,
  ensure = function(state, output, ...) NULL
)
}
\arguments{
\item{title}{the name of this command, to be shown when
reporting any failing test cases.}

\item{generator}{A generator which provides random arguments
for the command, given the current (symbolic) state.
If nothing can be done with the current state, one
should preclude the situation with a requires and
return NULL. Otherwise, it should be a list of
arguments (the empty list is ok for functions which
take no arguments).}

\item{execute}{A function from the concrete input,
which executes the true function and returns
concrete output.
Function takes the (possibly named) arguments given
by the generator.}

\item{require}{A function from the current (symbolic)
state to a bool, indicating if action is currently
applicable.
Function also takes the (possibly named) arguments
given by the generator (this is mostly used in
shrinking, to ensure after a shrink its still
something which could have been generated by the
function generator).}

\item{update}{A function from state to state, which is
polymorphic over symbolic and concrete inputs and
outputs (as it is used in both action generation and
command execution).
It's critical that one doesn't "inspect" the output
and input values when writing this function.}

\item{ensure}{A post-condition for a command that must be
verified for the command to be considered a success.
This should be a set of testthat expectations.}
}
\value{
a command structure.
}
\description{
This helper function assists one in creating commands
for state machine testing in hedgehog.
}
