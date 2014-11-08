izablog
==

An experimental blog platform written in bash


Features
--

- Generates a static website from Markdown files, with no need for a database
- Disqus integration
- Apache ModRewrite support
- Publish with git


Installation
--

`git clone https://github.com/izabera/izabera.github.io blog`

`cd blog && ./configure`

Tada! Your blog is now ready. Your settings are saved in `blog/settings` and your post in `src/indexed` (and `src/unindexed`).

When you add a new post, run `makeblog` to update your index page.

If you enable the git plugin, `makeblog [message]` will add all the changes, commit them with that message and push to a remote. In order to use it, you have to set up a repo on your own.

