# ghettopt

[![Build Status](https://travis-ci.com/agriffis/ghettopt.svg?branch=master)](https://travis-ci.com/github/agriffis/ghettopt)

This is simple Bash command-line parsing. No loops, no shifting, no
worrying about quoting. Just declare some variables and call ghettopt:

```bash
opt_config=$HOME/.myconfig
opt_proxy=
opt_force=false

ghettopt "$@" || exit
```

After calling ghettopt, the results can be found in the variables. For
example, if the user specified `--config=/dev/null` then `$opt_config` now
contains `/dev/null`.

Any non-option parameters on the command-line can be found in the array
`$params`. If you'd like these back in `$@`, do it like this:

```bash
ghettopt "$@" || exit
set -- "${params[@]}"
```

# Reference

There are four kinds of declarations that ghettopt understands:

 * strings, including blank: `opt_string=default` or `opt_string=`.
   These require an argument on the command-line.

 * booleans: `opt_bool=true` or `opt_bool=false`. These automatically get
   a corresponding `--no-` prefixed option. Specifying `--option` sets the
   variable to true; specifying the `--no-option` sets the variable to
   false, regardless whether the default was true or false.

 * arrays: `opt_array=()`. This accumulates when specified multiple times
   on the command-line, for example `--array=one --array=two` results in
   `opt_array=( one two )`.

 * functions, which are called: `opt_func() { echo hi; }`. To accept
   (require) an argument, use a colon: `opt_func:() { echo "$1"; }`. (It
   looks strange, but yes, colon is a valid character in a function name.)

## Short options

To support short options, ghettopt looks at a variable called `shortopts`.
This is a list of associations between short and long options. It's
impossible to have a short option without a long option equivalent.

For example, to add short options to the example program:

```bash
shortopts=( c:config p:proxy f:force )
```

## Results of parsing

The results can be found in three places: parsed option values are in the
variables, non-options are in the array `$params`, and for reference you
can find the normalized parsed options in the array `$parsed_opts`.

If ghettopt encounters a parsing error, such as an unrecognized option, it
will emit an error message and return non-zero status.

# FAQ

 1. Does ghettopt provide automatic help?

    No, ghettopt does not provide automatic help.  You can declare
    a function for it, though.  Don't forget to exit at the bottom. See the
    full example below which does this.

 2. Is ghettopt pure Bash?

    Yes, except it depends on external GNU getopt. For maximum portability,
    for example to OS X, you can avoid this dependency by using
    [pure-getopt](https://github.com/agriffis/pure-getopt).  See the
    full example below which does this.

 3. What Bash versions does ghettopt support?

    ghettopt is compatible with Bash versions >= 2.05b

 4. Does ghettopt have a test suite?

    Yes, just clone the repo and run `test.bash`.

 5. How do you pronounce "ghettopt?"

    The "pt" is silent, so it's pronounced like "ghetto" or "get-o".
    That way it's not confused with "getopt" in conversation.

# Full example

See [example.bash](example.bash) for a full example with some best
practices. Or use this function whenever you want to start a new script:

```bash
ghettopt-new() {
    [[ -n $1 ]] || { echo "need script name" >&2; return 1; }
    [[ ! -s $1 ]] || { echo "won't clobber $1, aborting" >&2; return 2; }
    curl -s https://raw.githubusercontent.com/agriffis/ghettopt/master/example.bash > "$1"
}
```

Now you can initialize a new script with:


```bash
ghettopt-new myscript.bash
```
