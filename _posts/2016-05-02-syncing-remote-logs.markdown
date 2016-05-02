---
layout: post
title:  "syncing remote logs (leveraging old *nix tools)"
---

Like many others I have a vps where I run a weechat relay.

Hey wouldn't it be nice to have those logs on my local machine?

Ok so how to do it?  Well there's `rsync`.

~~~
rsync -az izabera@myhost:/home/izabera/.weechat/logs/ /home/izabera/.weechat/remote_logs
~~~

Neat, all my logs are now synced.  It'd be nice to have them always in sync...

What about... a `fuse` filesystem?  Something that calls `rsync` every time you
`open()` a file maybe...

Wait, does `rsync` have a library?  Calling the actual executable from c seems
weird...  Oh nice, there are a few projects, like
[http://librsync.sourceforge.net](http://librsync.sourceforge.net) and
[https://github.com/librsync/librsync](https://github.com/librsync/librsync)

Aww bummer, they only do the delta thingy one file at a time.  So I'll have to
write my own directory tree walker.  Ok, there are `ftw()` and `fts()`...

And...  do I have to handle the compression myself?  And decompressing on the
client...  This is starting to look like a huge amount of work...

And when to sync?  On `open()` seems ok but actually I'd rather have an
asynchronous request that syncs my file but lets me open the local file anyway
immediately.

If i have to do this in c with `fuse`, well, C isn't exactly well suited for
async programming...  Maybe it'd be enough to just `fork()` off and sync in one
process...  Well this still doesn't look too good, I want to be able to open a
file 10 times to check things or with `grep` or whatever, that shouldn't call
the whole sync thing every time.  It'd be ideal to just sync every once in a
while and on `open()` you just check if it was synced in the last X minutes...
Maybe with a way to force an immediate sync if needed...

Actually this doesn't need `fuse` at all, something like a regular daemon will
do.  A simple signal handler to force a sync on `SIGUSR1`...

Wait, can this be done in `bash`?  That'd be great, I would just call `rsync`
itself, with no need to mess with directory walking and compression, no
depending on external libraries, and it's gonna be 1/100 as long as in c.

This doesn't actually need a daemon...  A `cron` job will do...

---

Work:

- added a single line in `crontab`
- made a shell function called `logsync` with that same single line of code

Result:

- super fast local directory with all my logs
- updated every 5 minutes

Execution time:

- thought process: 20 minutes
- code: 20 seconds
