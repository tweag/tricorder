# Features of Tricorder

Tricorder has various features that warrant further explanation for those who
are interested.

## Eval comments

Tricorder supports evaluating expressions in comments.

Currently, 3 forms of eval comments are supported. All eval comments are
evaluated in the context of the module where it is located, and all top-level
bindings of that module will be available to the expression of the eval
comment.

### Single-line comments

```haskell
-- $> <expr>

-- $> 2 + 2

-- $> someFunc 12 >> someOtherFunc
```

Single-line eval comments must be at the start of a line comment, and are
denoted by a `$>` marker. Excluding non-newline whitespace directly following
the `$>` token, the rest of the eval comment is evaluated as-is.

### Multi-line eval comment in line comments

```haskell
-- $$>
-- <expr>
-- <$$

-- $$>
-- 2 + 2
-- <$$

-- $$>
-- someFunc 12
-- >> someOtherFunc
-- <$$
```

Multi-line eval comments within line comments are denoted by the `$$>` and
`<$$` pair. A newline _must_ follow the `$$>` marker, and a newline _must_
precede the `<$$` marker. Everything between the `$$>` and `<$$` marker is
evaluated as-is.

### Block eval comment

```haskell
{- $$>
<expr>
<$$ -}

{- $$>
2 + 2
<$$ -}

{- $$>
someFunc 12
>> someOtherFunc
<$$ -}
```

Block eval comments reside within a multi-line comment, and are denoted by the
`$$>` and `<$$` pair, much like for multi-line eval comments in line comments.
The `$$>` token _must_ be followed by a newline, and the `<$$` token _must_ be
preceded by a newline.

They are effectively the equivalent to multi-line eval comments in line
comments, but might be more ergonomic for many cases.

## Rebindable keys

All key shortcuts in Tricorder can be remapped. See [Configuring Tricorder's
"Custom Key Bindings" section](./configuring-tricorder.md#custom-key-bindings)
for more information.
