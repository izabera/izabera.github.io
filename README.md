izablog
=======

An experimental blog platform written in bash


Features
--------

- Generates a static website from Markdown files, with no need for a database
- Disqus integration
- Apache ModRewrite support
- Publish with git


Requirements
------------

The only true requirement outside of bash is an external markdown converter.
By default, it uses the python pip markdown module. If you absolutely cannot
use it, you'll have to edit `makeblog` and substitute it with yours.


Installation
------------

Run the following:

`git clone https://github.com/izabera/izabera.github.io blog`  
`cd blog && chmod +x configure && ./configure`

_Tada!_ Your blog is ready.

Your settings are saved in `blog/settings` and your posts in `src/indexed`
(and `src/unindexed`).

When you add a new post, run `makeblog [message]` to update your index page.

Enabling the git plugin, you'll be prompted whether to clone a repo or create a
new one. Then, when you run `makeblog`, it will add all the changes, commit
them and push to the remote if you selected it.

