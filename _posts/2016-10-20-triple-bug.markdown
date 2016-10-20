---
layout: post
title:  "triple bug"
---

[https://godbolt.org/g/gdXLeZ](https://godbolt.org/g/gdXLeZ)

[![godbolt](http://i.imgur.com/QqNZNg6.png)](http://i.imgur.com/QqNZNg6.png)

gcc bug
---

gcc is ignoring `__builtin_expect(..., 1)`

clang bug
---

clang is producing suboptimal code:
lifting `xorl` makes a branch longer than it needs to be

godbolt bug
---

godbolt is coloring clang's `xorl` with the same color as the function's name,
instead of the `return 0`
