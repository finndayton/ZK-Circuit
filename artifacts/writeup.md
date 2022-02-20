Name: [Finn Dayton]

## Question 1

In the following code-snippet from `Num2Bits`, it looks like `sum_of_bits`
might be a sum of products of signals, making the subsequent constraint not
rank-1. Explain why `sum_of_bits` is actually a _linear combination_ of
signals.

```
        sum_of_bits += (2 ** i) * bits[i];
```

## Answer 1

`sum_of_bits` is actually a _linear combination_ of signals because (2 ** i) * bits[i] is a linear expression. I.e., it is only the addition of vars and multiplication by contants. For a given i, 2^i is a constant and bits[i] is a variable. These variables are added together to create the total `sum_of_bits`.

## Question 2

Explain, in your own words, the meaning of the `<==` operator.

## Answer 2

It assigns the value on the right to the variable on the left AND implies basically adding an assert statement in teh witness code generation that the two are equal. This assertion will fail if the right side is not quadratic. 

## Question 3

Suppose you're reading a `circom` program and you see the following:

```
    signal input a;
    signal input b;
    signal input c;
    (a & 1) * b === c;
```

Explain why this is invalid.

## Answer 3

When assigning a constraint, the expression must be quadratic. The expression on the left (a&b) is not quadratic.
