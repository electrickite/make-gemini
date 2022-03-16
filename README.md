# Make Gemini
A simple static site generator for the Gemini protocol. Requires only GNU Make
and a POSIX-like environment.

## Requirements
* GNU Make
* POSIX shell
* POSIX core utilities

The Makefile makes heavy use of GNU Make syntax and functions, so other
make implementations will not work. The project uses uses at least a few
non-POSIX command options (ex: the `-i` flag for `sed`) but tries to be as
cross-platform as possible. It has been tested on GNU/Linux and BSD/Mac.

## Use
Create a directory to house your site source files and copy the Makefile to
it. Alternately, you can clone the project git repository. Then:

    $ cd mysite
    $ make init
    $ make

A number of source directories and templates will be created as well as the
`output` directory that contains the processed site files. The contents of
`output` can then be copied to your Gemini server document root.

To remove all files created in `output`, run:

    $ make clean

Optionally, as a shortcut for deployment commands, the `deploy` target will
execute the command(s) specified in the `DEPLOY_CMD` configuration variable.

    $ make deploy

### Configuration
Configuration variables are read from `config.mk` and override the default
values set in the Makefile. Any variable defined before the `include config.mk`
statement can be overridden - the `config.mk` file generated during init shows
several examples. Common variables are:

* `SITE_NAME` - A string that will be availble in the `%%SITE_NAME%%`
  placeholder
* `DOMAIN` - The domain name of the site. Defaults to `localhost`
* `BASE_PATH` - The base path to use in full URLs
* `TAG_TEXT` - Replacement text for TAGS: line in posts
* `INDEX` - Space separated list of index pages. Defaults to `index.gmi`

Other variables that can be overridden include shell command paths, source
directories, and default templates.

## Site layout
The system supports pages, posts, templates, and static files.

### Pages
Gemtext files with a `.gmi` extension can be added to the `pages` directory
and subdirectories. These files will be processed as described below and added
to the `output` directory, preserving file names and path structure.

### Posts
Posts are intended to be used as a gemlog. Each post is a gemtext file with a
`.gmi` extension added to the `posts` directory. Posts must use the following
naming convention:

    YYYY-MM-DD_post-name.gmi

Where `YYYY-MM-DD` is the publishing date, and `post-name` is the file name
that will appear in the URL path. Posts will be processed as described below
and added to the `output` directory at the following path:

    /posts/YYYY/MM/post-name.gmi

#### Tags
Posts may be "tagged" by adding a line anywhere in the post source file
beginning with `TAGS: ` and followed by a space-separated list of tags. For
example:

    TAGS: foo bar baz

The TAGS line will be replaced during processing by a list of links to tag
index pages. The tag index pages will be created automatically. For the `foo`
tag in the example above, the index will be placed at:

    /posts/foo.gmi

### Templates
Templates are used to build pages and posts and as described below and are
placed in the `templates` directory.

### Static files
Files and directories placed in `static` will be copied to `output` with no
modification.

## Processing
Gemtext files ending with `.gmi` in `pages` and `posts` will be processed
before be written to the `output` directory.

### Templates
Each output file is built using a template from the `templates` directory.
The default templates are:

* `page` - Used for pages
* `post` - Used for posts
* `index` - Used to generate index pages (defined in the `INDEX` variable)
* `tag` - Used to generate tag indexes

A page, post, or index page can override the default template by including a
line beginning with `TEMPLATE: ` followed by the template name anywhere in the
file. This line will be removed during processing.

A placeholder string (or strings) within the template will be replaced by the
content of the file being processed (or other content as described below).
These template placeholders are:

* `%%CONTENT%%` - Content of the source file is inserted at this point
* `%%POSTS%%` - Index pages will insert their list of posts at this point

Default templates are created during `init` that show how these placeholders
are used.

### Placeholders
In addition to the template placeholder strings described above, the folliwing
placeholders can be used in either templates or source files.

* `%%TITLE%%` - The page/post title (text of the first level one heading)
* `%%SITE_NAME%%` - The configured site name
* `%%DOMAIN%%` - The configured site domain
* `%%BASE_PATH%%` - The configured base path
* `%%URL%%` - Full URL of site

### Indexes
Two types of post index pages are supported: a general index page that lists
all posts and the automatically generated indexes for any post tags. The
general post index (often serves as the site home page) is `index.gmi` by
default but may be configured in the `INDEX` config variable.

Each index is built with a list of post links sorted by date in descending
order. The links have the following format:

    => POST_URL DATE: TITLE

Where `POST_URL` is the full URL of the post, `DATE` is the publication date
from the post file name, and `TITLE` is taken from the first level one
heading line.

## License and Copyright
Copyright (c) 2022 Corey Hinshaw

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
