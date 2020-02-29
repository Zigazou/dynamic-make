Dynamic make in Bash
====================

Goal
----

When you have a lot of files to run a script on, Bash is inherently mono-threaded. It also does not keep track of what has already been done in case of an interruption in the process unless you coded it.

There is though one widely available tool that does just that: `make`.

Most often you use it by creating a `Makefile` that has rules for every file in one directory, meaning you have to create a `Makefile` in each subdirectory.

Here comes GNU `make`!

GNU `make` is able to:

- read a `Makefile` from the standard input,
- run rules even if targets are outside of the current directory.

How to do it
------------

The script [genmakefile.bash](genmakefile.bash) is a model which you can adapt to your needs.

Here’s how it works.

### Escaping strings

The first two functions are helper functions which escape a full file path. `escape_make` prepares a string for the `make` utility and `escape_shell` prepares a string the any shell command.

They use the `%q` placeholder of the `printf` command. It escapes any string for the shell.

The main difference reside in the escaping of the `'` character which is special for Bash but not for the `make` command.

```Bash
escape_make() { printf '%q' "${1:2}" | sed "s/\\\\'/'/g"; }
escape_shell() { printf '%q' "${1:2}"; }
```

### Generating a filter for the `find` command

The `make_filter` function is also an helper function which helps you to generate a filter for several extensions.

It generates a string of the following form:

```Shell
$ make_filter ext1 ext2 ext3
-type f ( -name *.ext1 -o -name *.ext2 -o -name *.ext3 )
```

It is very useful since such a string needs to be escaped for Bash:

```Shell
find . -type f \( -name \*.ext1 -o -name \*.ext2 -o -name \*.ext3 \)
```

vs

```Shell
find . -type f $(make_filter ext1 ext2 ext3)
```

Here’s the source code of this function:

```Bash
make_filter() {
    local filters

    printf -- '-type f ( '
    filters="$(for ext in $*; do printf -- '-name *.%s -o ' "$ext"; done)"
    printf '%s )' "${filters% -o }"
}
```

### Generating the all target

The `make` utility needs to know what to build. If it is not directed, it uses the first rule.

Generating the `all` target means you have to travel through the file system looking for files, which can be done with the `find` command.

The `set -o noglob` instructs Bash not to expands strings like `*.html`.

In this example, we are looking the all html, css, js, svg, xml and json files. These are highly compressible text files that later will be compressed with Zopfli (.gz) and Brotli (.br).

```Bash
set -o noglob
compressible="$(make_filter html css js svg xml json)"

printf 'all:'
find . -type f $compressible | while read filepath
do
    fem="$(escape_make "$filepath")"
    printf ' %s.gz %s.br' "$fem" "$fem"
done
printf '\n'
```

### Generating each rule

For each compressible file, there will be two rules: one for the Zopfli compression and one for the Brotli compression. This allows parallelization of jobs.

```Bash
find . $compressible | while read filepath
do
    fem="$(escape_make "$filepath")"
    fes="$(escape_shell "$filepath")"

    printf '%s.gz: %s\n' "$fem" "$fem"
    printf '\tzopfli --i127 %s\n' "$fes"
    printf '\n'

    printf '%s.br: %s\n' "$fem" "$fem"
    printf '\tbrotli --quality 15 --input %s --output %s.br\n' "$fes" "$fes"
    printf '\n'
done
```

How to use it
-------------

The script only generates a `Makefile` on the standard output.

You use it like that:

```Shell
bash genmakefile.bash | make -f- -j4
```

Adjust the `j` parameter to the number of parallel jobs you want to run.    

Output example
--------------

Here’s an example of what the `genmakefile.bash` script can generate.

```Makefile
    all: about.html.gz about.html.br faq.html.gz faq.html.br blog.html.gz blog.html.br blog-post.html.gz blog-post.html.br css/all.css.gz css/all.css.br css/style.css.gz css/style.css.br css/jquery.fancybox.min.css.gz css/jquery.fancybox.min.css.br css/owl.carousel.min.css.gz css/owl.carousel.min.css.br js/owl.carousel.min.js.gz js/owl.carousel.min.js.br js/contact_me.js.gz js/contact_me.js.br js/jquery.appear.js.gz js/jquery.appear.js.br js/jquery.fancybox.min.js.gz js/jquery.fancybox.min.js.br js/script.js.gz js/script.js.br js/jqBootstrapValidation.js.gz js/jqBootstrapValidation.js.br js/imagesloaded.pkgd.min.js.gz js/imagesloaded.pkgd.min.js.br js/filter.js.gz js/filter.js.br js/isotope.pkgd.min.js.gz js/isotope.pkgd.min.js.br contact.html.gz contact.html.br webfonts/fa-brands-400.svg.gz webfonts/fa-brands-400.svg.br webfonts/fa-regular-400.svg.gz webfonts/fa-regular-400.svg.br webfonts/fa-solid-900.svg.gz webfonts/fa-solid-900.svg.br index.html.gz index.html.br services.html.gz services.html.br 404.html.gz 404.html.br portfolio-4-col.html.gz portfolio-4-col.html.br vendor/jquery/jquery.min.js.gz vendor/jquery/jquery.min.js.br vendor/bootstrap/css/bootstrap.min.css.gz vendor/bootstrap/css/bootstrap.min.css.br vendor/bootstrap/js/bootstrap.bundle.min.js.gz vendor/bootstrap/js/bootstrap.bundle.min.js.br portfolio-3-col.html.gz portfolio-3-col.html.br pricing.html.gz pricing.html.br portfolio-item.html.gz portfolio-item.html.br

    about.html.gz: about.html
        zopfli --i127 about.html

    about.html.br: about.html
        brotli --quality 15 --input about.html --output about.html.br

    faq.html.gz: faq.html
        zopfli --i127 faq.html

    faq.html.br: faq.html
        brotli --quality 15 --input faq.html --output faq.html.br

    blog.html.gz: blog.html
        zopfli --i127 blog.html

    blog.html.br: blog.html
        brotli --quality 15 --input blog.html --output blog.html.br

    blog-post.html.gz: blog-post.html
        zopfli --i127 blog-post.html

    blog-post.html.br: blog-post.html
        brotli --quality 15 --input blog-post.html --output blog-post.html.br

    css/all.css.gz: css/all.css
        zopfli --i127 css/all.css

    css/all.css.br: css/all.css
        brotli --quality 15 --input css/all.css --output css/all.css.br

    css/style.css.gz: css/style.css
        zopfli --i127 css/style.css

    css/style.css.br: css/style.css
        brotli --quality 15 --input css/style.css --output css/style.css.br

    css/jquery.fancybox.min.css.gz: css/jquery.fancybox.min.css
        zopfli --i127 css/jquery.fancybox.min.css

    css/jquery.fancybox.min.css.br: css/jquery.fancybox.min.css
        brotli --quality 15 --input css/jquery.fancybox.min.css --output css/jquery.fancybox.min.css.br

    css/owl.carousel.min.css.gz: css/owl.carousel.min.css
        zopfli --i127 css/owl.carousel.min.css

    css/owl.carousel.min.css.br: css/owl.carousel.min.css
        brotli --quality 15 --input css/owl.carousel.min.css --output css/owl.carousel.min.css.br

    js/owl.carousel.min.js.gz: js/owl.carousel.min.js
        zopfli --i127 js/owl.carousel.min.js

    js/owl.carousel.min.js.br: js/owl.carousel.min.js
        brotli --quality 15 --input js/owl.carousel.min.js --output js/owl.carousel.min.js.br

    js/contact_me.js.gz: js/contact_me.js
        zopfli --i127 js/contact_me.js

    js/contact_me.js.br: js/contact_me.js
        brotli --quality 15 --input js/contact_me.js --output js/contact_me.js.br

    js/jquery.appear.js.gz: js/jquery.appear.js
        zopfli --i127 js/jquery.appear.js

    js/jquery.appear.js.br: js/jquery.appear.js
        brotli --quality 15 --input js/jquery.appear.js --output js/jquery.appear.js.br

    js/jquery.fancybox.min.js.gz: js/jquery.fancybox.min.js
        zopfli --i127 js/jquery.fancybox.min.js

    js/jquery.fancybox.min.js.br: js/jquery.fancybox.min.js
        brotli --quality 15 --input js/jquery.fancybox.min.js --output js/jquery.fancybox.min.js.br

    js/script.js.gz: js/script.js
        zopfli --i127 js/script.js

    js/script.js.br: js/script.js
        brotli --quality 15 --input js/script.js --output js/script.js.br

    js/jqBootstrapValidation.js.gz: js/jqBootstrapValidation.js
        zopfli --i127 js/jqBootstrapValidation.js

    js/jqBootstrapValidation.js.br: js/jqBootstrapValidation.js
        brotli --quality 15 --input js/jqBootstrapValidation.js --output js/jqBootstrapValidation.js.br

    js/imagesloaded.pkgd.min.js.gz: js/imagesloaded.pkgd.min.js
        zopfli --i127 js/imagesloaded.pkgd.min.js

    js/imagesloaded.pkgd.min.js.br: js/imagesloaded.pkgd.min.js
        brotli --quality 15 --input js/imagesloaded.pkgd.min.js --output js/imagesloaded.pkgd.min.js.br

    js/filter.js.gz: js/filter.js
        zopfli --i127 js/filter.js

    js/filter.js.br: js/filter.js
        brotli --quality 15 --input js/filter.js --output js/filter.js.br

    js/isotope.pkgd.min.js.gz: js/isotope.pkgd.min.js
        zopfli --i127 js/isotope.pkgd.min.js

    js/isotope.pkgd.min.js.br: js/isotope.pkgd.min.js
        brotli --quality 15 --input js/isotope.pkgd.min.js --output js/isotope.pkgd.min.js.br

    contact.html.gz: contact.html
        zopfli --i127 contact.html

    contact.html.br: contact.html
        brotli --quality 15 --input contact.html --output contact.html.br

    webfonts/fa-brands-400.svg.gz: webfonts/fa-brands-400.svg
        zopfli --i127 webfonts/fa-brands-400.svg

    webfonts/fa-brands-400.svg.br: webfonts/fa-brands-400.svg
        brotli --quality 15 --input webfonts/fa-brands-400.svg --output webfonts/fa-brands-400.svg.br

    webfonts/fa-regular-400.svg.gz: webfonts/fa-regular-400.svg
        zopfli --i127 webfonts/fa-regular-400.svg

    webfonts/fa-regular-400.svg.br: webfonts/fa-regular-400.svg
        brotli --quality 15 --input webfonts/fa-regular-400.svg --output webfonts/fa-regular-400.svg.br

    webfonts/fa-solid-900.svg.gz: webfonts/fa-solid-900.svg
        zopfli --i127 webfonts/fa-solid-900.svg

    webfonts/fa-solid-900.svg.br: webfonts/fa-solid-900.svg
        brotli --quality 15 --input webfonts/fa-solid-900.svg --output webfonts/fa-solid-900.svg.br

    index.html.gz: index.html
        zopfli --i127 index.html

    index.html.br: index.html
        brotli --quality 15 --input index.html --output index.html.br

    services.html.gz: services.html
        zopfli --i127 services.html

    services.html.br: services.html
        brotli --quality 15 --input services.html --output services.html.br

    404.html.gz: 404.html
        zopfli --i127 404.html

    404.html.br: 404.html
        brotli --quality 15 --input 404.html --output 404.html.br

    portfolio-4-col.html.gz: portfolio-4-col.html
        zopfli --i127 portfolio-4-col.html

    portfolio-4-col.html.br: portfolio-4-col.html
        brotli --quality 15 --input portfolio-4-col.html --output portfolio-4-col.html.br

    vendor/jquery/jquery.min.js.gz: vendor/jquery/jquery.min.js
        zopfli --i127 vendor/jquery/jquery.min.js

    vendor/jquery/jquery.min.js.br: vendor/jquery/jquery.min.js
        brotli --quality 15 --input vendor/jquery/jquery.min.js --output vendor/jquery/jquery.min.js.br

    vendor/bootstrap/css/bootstrap.min.css.gz: vendor/bootstrap/css/bootstrap.min.css
        zopfli --i127 vendor/bootstrap/css/bootstrap.min.css

    vendor/bootstrap/css/bootstrap.min.css.br: vendor/bootstrap/css/bootstrap.min.css
        brotli --quality 15 --input vendor/bootstrap/css/bootstrap.min.css --output vendor/bootstrap/css/bootstrap.min.css.br

    vendor/bootstrap/js/bootstrap.bundle.min.js.gz: vendor/bootstrap/js/bootstrap.bundle.min.js
        zopfli --i127 vendor/bootstrap/js/bootstrap.bundle.min.js

    vendor/bootstrap/js/bootstrap.bundle.min.js.br: vendor/bootstrap/js/bootstrap.bundle.min.js
        brotli --quality 15 --input vendor/bootstrap/js/bootstrap.bundle.min.js --output vendor/bootstrap/js/bootstrap.bundle.min.js.br

    portfolio-3-col.html.gz: portfolio-3-col.html
        zopfli --i127 portfolio-3-col.html

    portfolio-3-col.html.br: portfolio-3-col.html
        brotli --quality 15 --input portfolio-3-col.html --output portfolio-3-col.html.br

    pricing.html.gz: pricing.html
        zopfli --i127 pricing.html

    pricing.html.br: pricing.html
        brotli --quality 15 --input pricing.html --output pricing.html.br

    portfolio-item.html.gz: portfolio-item.html
        zopfli --i127 portfolio-item.html

    portfolio-item.html.br: portfolio-item.html
        brotli --quality 15 --input portfolio-item.html --output portfolio-item.html.br
```