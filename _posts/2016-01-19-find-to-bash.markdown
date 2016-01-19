---
layout: post
title:  "bash sucks"
---

One of the reasons why bash is a pain to work with is that its
bottlenecks are very non obvious.  Here's an example problem, one that
looks suitable for a shell script.  This question is also often asked in
`#bash` on freenode:

> how do i put into an array the list of files i get from `find`?

There's a list of files and we want to process them.  Pretty much exactly
what shells do all the time.

Let's see several ways.

* toc
{:toc}

* * *



the `while` loop way
--------------------

The most common answer is always this (or trivial variations of it):

{% highlight bash %}
while read -rd ""; do
  arr+=("$REPLY")
done < <(find … -print0)
{% endhighlight %}

This looks pretty solid:

- it's very easy to write
- it can safely handle any filename, even with newlines or special
  characters in it
- `find -print0` + `read -d ""` looks like the perfect tool for the job

Let's see how well it performs in a relatively large directory such as
the linux kernel's git tree with 56380 files:
(note: all the examples have been timed on my laptop's slow hdd)

{% highlight bash %}
$ find > /dev/null                                    # cache issues

$ time find > /dev/null                               # base case

real    0m0.121s
user    0m0.050s
sys     0m0.067s

$ time while read -rd ""; do
>   arr_while+=("$REPLY")
> done < <(find -print0)

real    0m3.403s
user    0m2.973s
sys     0m0.523s

$ echo "arr_while contains ${#arr_while[@]} files"    # checking
arr_while contains 56380 files
{% endhighlight %}

3.4s is a bit much.  Let's dig deeper with the almighty `strace`:

{% highlight bash %}
$ strace bash -c 'read -rd "" < <(echo xyz)'
...
lseek(0, 0, SEEK_CUR)                   = -1 ESPIPE (Illegal seek)
read(0, "x", 1)                         = 1
read(0, "y", 1)                         = 1
read(0, "z", 1)                         = 1
read(0, "\n", 1)                        = 1
read(0, "", 1)                          = 0
...
{% endhighlight %}

Ouch, this is painful.  `read` tried to `lseek`, failed, so it decided to
disable buffering and read a byte at a time.  Clearly very inefficient for
large input.  This is not what we want!

`read` can't buffer its input, because of the very nature of the shell:
it's often used along with other commands, and an unbuffered `read` lets
us write stuff like:

{% highlight bash %}
# chop off a line before piping it to sort
cmd | { read -r; sort; }
{% endhighlight %}

What can we do to improve our `find` problem?  We cannot change how
`read` works, but maybe we should use a different tool.

* * *




the `mapfile` way
-----------------

So, we need a way to add elements to an array without using `read`. A
different builtin, `mapfile` would be handy but sadly it doesn't provide
a way to choose our own delimiter… until bash 4.4 (currently beta),
which finally solves this long-standing issue.

Let's try this fancy toy:
{% highlight bash %}
$ time mapfile -d "" arr_mapfile < <(find -print0)

real    0m0.468s
user    0m0.093s
sys     0m0.467s

$ echo "arr_mapfile contains ${#arr_mapfile[@]} files"
arr_mapfile contains 56380 files
{% endhighlight %}

Neat!  Impressive improvement, from 3.4s to 0.4s, less that 1/7 of the
`while` loop way!  At least part of the improvement is due to the fact
that we're now using a builtin written in C rather than a bash loop, but
that's not important.  We're now pretty confident that `mapfile` does
something different, maybe it buffers its input:

{% highlight bash %}
$ strace bash4.4 -c 'mapfile arr < <(echo xyz)'
...
lseek(0, 0, SEEK_CUR)                   = -1 ESPIPE (Illegal seek)
read(0, "x", 1)                         = 1
read(0, "y", 1)                         = 1
read(0, "z", 1)                         = 1
read(0, "\n", 1)                        = 1
read(0, "", 1)                          = 0
...
{% endhighlight %}

Dammit!  Again?!

It's not immediately clear why `mapfile` can't or doesn't buffer.  After
all, it always slurps all the input and there's no way to stop it, other
than killing the shell.

Oh, right, `mapfile` lets us specify a callback function that will be
called after reading N lines, so we can write something like this:

{% highlight bash %}
$ mapfile -tc1 -C 'read _ #' < <(seq 10); echo "${MAPFILE[@]}"
1 3 5 7 9
{% endhighlight %}

This makes at least *some* sense, but it's a pretty convoluted example and
it feels like we're justifying a bug: it would be reasonable to assume
that the callback can't (or shouldn't) read from the same file descriptor
as `mapfile`.  One would think that the purpose of that callback is to
process the data it *already* read, and it doesn't need to read more…

* * *



the `eval` way
--------------

One way that comes to mind is to use `eval`: if `find` could produce valid
code, we could just wrap it in something like:

{% highlight bash %}
eval "arr=( $(find . -print-bash-code) )"
{% endhighlight %}

Too bad `find` doesn't: It can only produce a list of files separated by
newlines, or by `NUL`s, or by any custom separator if we use `-printf`.

A custom separator probably isn't too useful, but the `NUL` one is
intriguing: maybe we can pipe our file list to a program that splits its
input on `NUL` bytes, then use that to produce valid code.

Our loyal friend, `sed`, comes in handy.  GNU `sed` can do this with its
`-z` option.  We only need to wrap each filename in `'...'` and convert
`'` to `'\''`.  Easy as cake:

{% highlight bash %}
find . -print0 | sed -z "s/'/'\\''/g;s/.*/'&'/"
{% endhighlight %}

The problem of course is that we still have embedded `NUL`s in the output.
We want to convert them to a separator that bash can use, like a space.
Again, pretty easy task with very common tools.

{% highlight bash %}
find . -print0 | sed -z "s/'/'\\''/g;s/.*/'&'/" | tr "\0" " "
{% endhighlight %}

Done!  Now let's create a function for this, and feed it to `eval`:

{% highlight bash %}
evallablefind () {
  find "$@" -print0 | sed -z "s/'/'\\''/g;s/.*/'&'/" | tr "\0" " "
}

eval "arr=( $(evallablefind) )"
{% endhighlight %}

But, is this faster?

{% highlight bash %}
$ time eval "arr_eval=( $(evallablefind) )"

real    0m0.839s
user    0m0.830s
sys     0m0.123s

$ echo "arr_eval contains ${#arr_eval[@]} files"
arr_eval contains 56380 files
{% endhighlight %}

Aww… what a let down!

From 3.4s to 0.8s, it now takes less than a quarter of the `while` loop's
time, but longer than `mapfile`.

What can we do about it?  Perhaps we can notice that bash will happily
ignore `NUL`s in command substitutions, so maybe there's a way to skip the
`tr` step.  Let't change our code to add a space after each element:
{% highlight bash %}
evallablefind () {
  find "$@" -print0 | sed -z "s/'/'\\''/g;s/.*/'&' /"
}
{% endhighlight %}

And let's test it:
{% highlight bash %}
$ time eval "arr_eval2=( $(evallablefind) )"


real    0m0.831s
user    0m0.830s
sys     0m0.123s

$ echo "arr_eval2 contains ${#arr_eval2[@]} files"
arr_eval2 contains 56380 files
{% endhighlight %}

Nope, `tr` was fast and removing it didn't change much.

Of course, `sed` is also fast and the problem is elsewhere:

{% highlight bash %}
$ time evallablefind > /dev/null

real    0m0.165s
user    0m0.157s
sys     0m0.077s
{% endhighlight %}

But where?  Of course, it's bash's fault.  Bash is notoriously dog-slow at
handling long strings, and `$( )` is capturing a > 2MiB string (which of
course isn't "long" in any other programming language).

### dalias' way

Rich Felker, aka dalias, addressed a similar problem a few years ago in
this famous page:
[http://www.etalabs.net/sh_tricks.html](http://www.etalabs.net/sh_tricks.html)

That method is pretty similar, but it provides a safe way to handle
`find`'s output even when `read` can't stop at `NUL`s.  Basically you
prepend `././` or `/./` to any directory, then you can use this to split the
list it generates.

Let's give it a try: `\n././` will separate files, `awk` will split and
format.

{% highlight bash %}
daliasway () {
  find ././ |
  awk 'BEGIN { q = "'\''"; getline; gsub(q, q "\\" q q); old = $0; printf q }
       { gsub(q, q "\\" q q) }
       /^\.\/\.\// { printf "%s" q " " q, old; old = $0; next }
       { old = old RS $0 }
       END { printf "%s" q, old }'
}
{% endhighlight %}
(…that wasn't too easy).

And now let's test it
{% highlight bash %}
$ time eval "arr_dalias=( $(daliasway) )"

real    0m0.932s
user    0m0.933s
sys     0m0.110s

$ echo "arr_dalias contains ${#arr_dalias[@]} elements"
arr_dalias contains 56380 elements
{% endhighlight %}

There's a lot more processing now, and this method is slower than our
previous attempt.  Anyway it's still more than 3x faster than the naïve
bash loop.

But… maybe we can use bash's `${var//pattern/replacement}` instead of
`awk` and it will be faster!

{% highlight bash %}
$ time {
>   tmp=$(find ././)
>   tmp=${tmp//"'"/"'\''"}
>   tmp=${tmp//$'\n././'/"' '"}
>   eval "arr_lasthope=( '${tmp%?}' )"
> }

real:   5m59.131s
user:   5m58.527s
sys:    0m0.123s

$ echo "arr_lasthope contains ${#arr_lasthope[@]} elements"
arr_lasthope contains 56380 elements
{% endhighlight %}

NOPE, definitely *not* faster.  bash is extremely slow at replacing
patterns in long strings.

* * *




extra
-----

It's worth noting that in simple cases like this, `find` is overkill.
Globs can do it safely and efficiently.


{% highlight bash %}
$ shopt -s globstar dotglob

$ time arr_glob=(**)

real    0m0.351s
user    0m0.253s
sys     0m0.097s

$ echo "arr_glob contains ${#arr_glob[@]} elements"
arr_glob contains 56379 elements
{% endhighlight %}
(56379 because `**` doesn't expand to `.`)

* * *



conclusion
----------

Today we learned that:

- bash loops are slow
- bash is slow at capturing long strings with `$( )`
- processing strings with bash can be unreasonably slow
- trying to let bash do as little as possible is probably a good idea
- if globs are enough for your problem, they're often your best bet
- bottlenecks are entirely non obvious
  - `mapfile` is still reading a byte at a time and there's nothing we
    can do about it, but it's faster than any other way to put `find`'s
    output into an array
  - seemingly innocent commands such as `${var//pat/rep}` can take *ages*
