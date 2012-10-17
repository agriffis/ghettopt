# ghettopt

This is simple Bash command-line parsing. No loops, no shifting, no
worrying about quoting. Just declare some variables and call ghettopt:

    :::bash
    opt_config=$HOME/.myconfig
    opt_proxy=
    opt_force=false

    ghettopt "$@" || exit

After calling ghettopt, the results can be found in the variables. For
example, if the user specified `--config=/dev/null` then `$opt_config` now
contains `/dev/null`.

Any non-option parameters on the command-line can be found in the array
`$params`. If you'd like these back in `$@`, do it like this:

    :::bash
    ghettopt "$@" || exit
    set -- "${params[@]}"

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

    :::bash
    shortopts=( c:config p:proxy f:force )

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
    [pure-getopt](https://bitbucket.org/agriffis/pure-getopt).  See the
    full example below which does this.

 3. What Bash versions does ghettopt support?

    ghettopt is compatible with Bash versions >= 2.05b

 3. Does ghettopt have a test suite?

    Yes, just clone the repo and run `test.bash`.

# Full example

Here's a full example with some best practices:

    #!/bin/bash

    main() {
        # Clear inadvertent options from the environment
        unset ${!opt_*}

        declare opt_config=$HOME/.myconfig
        declare opt_proxy=
        declare opt_force=false
        declare shortopts=( c:config p:proxy f:force )

        ghettopt "$@" || exit
        set -- "${params[@]}"

        echo "Config file is $opt_config"
        
        if [[ -n $opt_proxy ]]; then
            echo "Proxy is $opt_proxy"
        fi

        if $opt_force; then
            echo "May the force be with you"
        fi

        if [[ $# -gt 0 ]]; then
            echo "Non-option parameters are:"
            for f; do
                echo "   $f"
            done
        fi

        exit 0
    }

    opt_help() {
        echo "usage: $0 [options] [files]"
        echo
        echo "  -c --config FILE  Read an alternate config,"
        echo "                    default: $opt_config"
        echo "  -f --force        Clobber existing files"
        echo "  -p --proxy PROXY  Use a network proxy"
        exit 0
    }

    opt_version() {
        echo "$0 version 0.4"
        exit 0
    }

    # INSERT ghettopt function here
    ghettopt() {
        ...
    }

    # INSERT getopt function here (optional, from pure-getopt)
    getopt() {
        ...
    }

    # CALL main at very bottom, passing script args
    main "$@"
