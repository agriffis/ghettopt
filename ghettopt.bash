#!/bin/bash
#=============================================================================
# simple bash command-line processing
#
# (c) Copyright 2008 Aron Griffis <agriffis@n01se.net>
# Released under the GNU GPL v2
#=============================================================================

parse_cmdline() {
    # extract long options from variable declarations
    declare getopt_long=$(set | \
        sed '/^opt_/!d; s/^opt_//; s/_/-/g;
            s/\(.*\)=false$/\1 no-\1/;
            s/\(.*\)=true$/\1 no-\1/;
            s/=.*/:/; s/()//;' | xargs | sed 's/ /,/g')

    # augment the shortopts array with takes-a-value colon;
    # for example f:file becomes f::file
    declare shortopts=( "${shortopts[@]}" )
    declare i x
    for ((i=0; i<${#shortopts[@]}; i++)); do
        x=${shortopts[i]}
        if [[ ",$getopt_long," == *,"${x#?:}":,* ]]; then
            shortopts[i]=${x/:/::}
        fi
    done
    declare getopt_short=$(IFS=''; echo "${shortopts[*]%:*}")

    declare args
    args=$(getopt -o "$getopt_short" \
        --long "$getopt_long" -n "$0" -- "$@") || return
    eval set -- "$args"

    declare opt var val
    parsed_opts=()
    while true; do
        [[ $1 == -- ]] && { shift; break; }

        # translate short options to long
        if [[ $1 == -? ]]; then
            opt=${1#-}
            for x in "${shortopts[@]}"; do
                if [[ $x == "$opt":* ]]; then
                    opt=${x##*:}
                    break
                fi
            done
        else
            opt=${1#--}
        fi

        # figure out $var and $val; shift positional params
        var=opt_${opt//-/_}
        case ",$getopt_long," in
            # make sure to handle opt_no_something (--no-something) 
            # which has a (silly) negation of --no-no-something
            *",no-$opt,"*)
                val=true
                parsed_opts=( "${parsed_opts[@]}" "$1" )
                shift ;;
            *",$opt,"*)
                if [[ $opt == no-* ]]; then
                    var=${var/no_/}
                    val=false
                else
                    val=true
                fi
                parsed_opts=( "${parsed_opts[@]}" "$1" )
                shift ;;
            *",$opt:,"*) 
                val=$2
                parsed_opts=( "${parsed_opts[@]}" "$1" "$2" )
                shift 2 ;;
            *)
                echo "error processing $1: not in getopt_long?" >&2
                return 1 ;;
        esac

        if [[ $(type -t "$var") == function ]]; then
            $var
        elif [[ $(type -t "$var:") == function ]]; then
            $var: "$val"
        elif is_array "$var"; then
            eval "$var=( \"\${$var[@]}\" $(printf %q "$val") )"
        elif is_var "$var"; then
            eval "$var=\$val"
        else
            echo "error processing $var: no func/array/var?" >&2
            return 1
        fi
    done

    parsed_params=( "$@" )
}

is_var() {
    declare -p "$1" &>/dev/null
}

is_array() {
    set -- $(declare -p "$1" 2>/dev/null)
    [[ $2 == -*a* ]]
}

# vim:sw=2
