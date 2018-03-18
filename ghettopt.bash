#!/bin/bash

ghettopt() {
  # ghettopt, simple command-line processing in pure Bash.
  # version 1.0.1
  #
  # Copyright 2008, 2012 Aron Griffis <aron@arongriffis.com>
  #
  # Permission is hereby granted, free of charge, to any person obtaining
  # a copy of this software and associated documentation files (the
  # "Software"), to deal in the Software without restriction, including
  # without limitation the rights to use, copy, modify, merge, publish,
  # distribute, sublicense, and/or sell copies of the Software, and to
  # permit persons to whom the Software is furnished to do so, subject to
  # the following conditions:
  #
  # The above copyright notice and this permission notice shall be included
  # in all copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  # OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  # IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  # CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  # TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  # SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  _ghettopt_main() {
    declare -a longs shorts
    declare go_long go_short i o v

    # Extract long options from variable declarations.
    for o in $(compgen -A variable opt_); do
      v=${!o}; o=${o#opt_}; o=${o//_/-}
      if [[ $v == false || $v == true ]]; then
        longs=( "${longs[@]}" "${o//_/-}" "no-${o//_/-}" )
      else
        longs=( "${longs[@]}" "${o//_/-}:" )
      fi
    done

    # Extract long options from function declarations.
    # These are allowed to have colons on the end.
    for o in $(compgen -A function opt_); do
      longs=( "${longs[@]}" "${o#opt_}" )
    done

    # Make it a comma-separated list.
    go_long="${longs[*]}"
    go_long="${go_long// /,}"

    # Extract short options from $shortopts, add takes-a-value colon.
    # shellcheck disable=SC2154
    if [[ -n $shortopts ]]; then
      shorts=( "${shortopts[@]%%:*}" )
      for ((i=0; i<${#shortopts[@]}; i++)); do
        o=${shortopts[i]#?:}
        if [[ ,$go_long, == *,"$o":,* ]]; then
          shorts[i]=${shorts[i]}:
        fi
      done
    fi

    # Make it a simple string.
    go_short="${shorts[*]}"
    go_short="${go_short// /}"

    # Call getopt!
    declare args
    args=$(getopt -o "$go_short" --long "$go_long" -n "$0" -- "$@") || return
    eval set -- "$args"

    # Figure out what getopt returned...
    declare opt var val
    parsed_opts=()
    while true; do
      [[ $1 != -- ]] || { shift; break; }

      # Translate short options to long.
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

      # Figure out $var and $val; shift positional params.
      var=opt_${opt//-/_}
      case ,"$go_long", in
        # Make sure to handle opt_no_something (--no-something)
        # which has a (silly) negation of --no-no-something
        (*,"no-$opt",*)
          val=true
          parsed_opts=( "${parsed_opts[@]}" "$1" )
          shift ;;
        (*,"$opt",*)
          if [[ $opt == no-* ]]; then
            var=${var/no_/}
            val=false
          else
            val=true
          fi
          parsed_opts=( "${parsed_opts[@]}" "$1" )
          shift ;;
        (*,"$opt:",*) 
          val=$2
          parsed_opts=( "${parsed_opts[@]}" "$1" "$2" )
          shift 2 ;;
        (*)
          echo "error processing $1: not in \$go_long?" >&2
          return 1 ;;
      esac

      if _ghettopt_is_function "$var"; then
        "$var"
      elif _ghettopt_is_function "$var:"; then
        "$var:" "$val"
      elif _ghettopt_is_array "$var"; then
        # shellcheck disable=SC1087
        eval "$var=( \"\${$var[@]}\" \"\$val\" )"
      elif _ghettopt_is_var "$var"; then
        eval "$var=\$val"
      else
        echo "error processing $var: no func/array/var?" >&2
        return 1
      fi
    done

    # shellcheck disable=SC2034
    params=( "$@" )
  }

  _ghettopt_is_function() {
    [[ $(type -t "$1") == function ]]
  }

  _ghettopt_is_array() {
    # shellcheck disable=SC2046
    set -- $(declare -p "$1" 2>/dev/null)
    [[ $2 == -*a* ]]
  }

  _ghettopt_is_var() {
    declare -p "$1" &>/dev/null
  }

  _ghettopt_version_check() {
    if [[ -z $BASH_VERSION ]]; then
      echo "ghettopt: unknown version of bash might not be compatible" >&2
      return 1
    fi

    # This is a lexical comparison that should be sufficient forever.
    if [[ $BASH_VERSION < 2.05b ]]; then
      echo "ghettopt: bash $BASH_VERSION might not be compatible" >&2
      return 1
    fi

    return 0
  }

  _ghettopt_version_check
  _ghettopt_main "$@"
  declare status=$?
  unset -f _ghettopt_main _ghettopt_version_check \
    _ghettopt_is_function _ghettopt_is_array _ghettopt_is_var
  return $status
}

# vim:sw=2
