---
layout: post
title:  "C generics"
---

C11 introduced generics, which is great, except they suck.

* toc
{:toc}

***

What works
----------

You can use type generic constructs, which is better than regular macros.
They're very handy and often used to *expand* macros.

~~~ c
#define gettype(x) _Generics((x), int:first, char:second, size_t:third, default:none)
enum type = gettype(var);
~~~

***

What doesn't work and/or should have been designed differently
--------------------------------------------------------------

- These look like labels, but there's no way to fallthrough

~~~ c
#define foo(x) _Generic((x), 
                            unsigned int: unsigned char: unsigned ...:
                                 my_unsigned_result,
                            signed int:   signed char:   signed...:
                                 my_signed_result
                       )
~~~

- String concatenation doesn't work

~~~ c
#define printformat(x) _Generics((x), int: "%d", char: "%c")
  printf(printformat(x) "\n", x);
~~~

- Trailing comma is invalid

This is valid with enums or arrays:

~~~ c
enum { foo, bar, baz, } myenum;
int a[] = { 1,2,3,4,5, };
~~~

And doesn't work with generics:

~~~ c
char *x = _Generic(x, int: "x", char: "y",);
~~~

This means that while writing code you have to pay extra care about
irrelevant details.

- Function pointers are incompatible with `void *`

This isn't really a problem with generics, just a major pain in the ass.
It forces you to use `default` for function pointers, which you may want
to use for something else.

~~~ c
#define print(x) printf(_Generics((x),
                                      int: "%d",
                                      char: "%c",
                                      void *: "%p",
                                      default: "error"), (x))
print(main);
~~~

- Clang thinks `"abcd"` is `char[5]` instead of `char *`

Seriously, WTF clang.

[Stackoverflow](https://stackoverflow.com/questions/18857056/c11-generic-how-to-deal-with-string-literals)
suggests to use `_Generic((0,x)` to make it decay to a pointer.  It looks
awful and it's not even obvious if it's going to work in other compilers.
