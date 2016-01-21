---
layout: post
title:  "find to bash - part 2"
---

I've received this reply from D630 (the author of [fzf][1]) to my previous post:

[1]: https://github.com/D630/fzf-fs

> There is one more answer, I guess. Something like:
>
> ~~~ bash
> unset -v a;
> time source <(
>          find "$@" -printf "a+=('%p')\0" \
>          | sed -z "s/'/'\\\''/g" \
>          | tr "\0" " ";
> );
> printf 'a has\t%d\n' ${#a[@]};
> ~~~
>

D630 also pointed out that 3 (or 4, because `"\\'"` is the same as `"\'"`)
backslashes are needed with `sed`.

- kinda ashamed that I made that typo
- someone actually read that post?  D: *shocked*

Soooo, without further ado, let's give this a try!

* toc
{:toc}

* * *




print arrays with find
----------------------

The problem is that `'` is a valid character in a filename, like `Shakira -
Hips don't lie.mp3`.

So we'd need to replace each `'` in the filename with `'\''`.

But we also need to leave the outer ones intact, the ones find added:

{% highlight bash %}
         find "$@" -printf "a+=('%p')\0" \
                                ^  ^
                           keep these two
{% endhighlight %}

It's probably easier to just not have them in the first place, and then use
`sed` to add them.  By the same reasoning, it's also probably easier to also
add the `a+=( )` part with `sed`.  The final result would look like this:

{% highlight bash %}
find "$@" -print0 | sed -z "s/'/'\\\''/g;s/.*/a+=('&')/" | tr "\0" " "
{% endhighlight %}

This is starting to look exactly like the [eval][2] way…  but here's the
catch: `<( )` is an external file, so bash doesn't have to read the whole
content of it at once like with `$( )`.

[2]: https://izabera.github.io/2016/01/19/find-to-bash.html#the-eval-way

Actually, it probably does…  The parser is line based, so it won't execute
commands until it parsed a whole line.  Changing the `tr` command to `tr "\0"
"\n"` should fix this (probably?)…

Test time!

{% highlight bash %}
$ time source <(find -print0 |
>               sed -z "s/'/'\\\''/g;s/.*/arr_source+=('&')/" |
>               tr "\0" "\n")

real    0m1.140s
user    0m1.130s
sys     0m0.087s

$ echo "arr_source contains ${#arr_source[@]} elements"
arr_source contains 56380 elements
{% endhighlight %}

Bummer.  1.1s is slow.  Bash is still running over 50k commands so this
approach is not viable.

* * *



one line to rule them all
-------------------------

What if it's everything in one line?  Do multiple assignments count as one
command according to bash?

{% highlight bash %}
$ time source <(find -print0 |
>               sed -z "s/'/'\\\''/g;s/.*/arr_source2+=('&')/" |
>               tr "\0" " ")

real    0m0.954s
user    0m0.943s
sys     0m0.103s

$ echo "arr_source2 contains ${#arr_source2[@]} elements"
arr_source2 contains 56380 elements
{% endhighlight %}

Aww…  It's faster than before, but still rather slow… :(

* * *




put it all together
-------------------

One last attempt: combine the good parts of both approaches by printing code
that creates an array in a single step.

{% highlight bash %}
$ time source <(echo "arr_source3=("
>               find -print0 |
>               sed -z "s/'/'\\\''/g;s/.*/'&'/" |
>               tr "\0" " "
>               echo ")")

real    0m0.747s
user    0m0.757s
sys     0m0.083s

$ echo "arr_source3 contains ${#arr_source3[@]} elements"
arr_source3 contains 56380 elements
{% endhighlight %}

(no idea why `user` is reported to be more than `real`…)

This was *slightly* faster than the previous attempts, but it didn't save too
much time.

* * *




ending
------

This was a long travel.  We learned that

- it looks like code that sets all the elements at once is faster than adding
  them with `a+=( )`
- trying to use `<( )` instead of `$( )` whenever possible makes sense
- anyway `mapfile` still beats everything that involves parsing and executing
  bash code
