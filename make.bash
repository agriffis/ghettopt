#!/bin/bash
#
# make.bash -- generate example.bash, inserting the latest getopt and
#              ghettopt functions

main() {
    declare ghettopt_script getopt_script example_script
    declare ghettopt_function getopt_function

    set -e

    if [[ ! -f getopt.bash ]]; then
        curl -O https://raw.githubusercontent.com/agriffis/pure-getopt/master/getopt.bash
    fi

    ghettopt_script=$(<ghettopt.bash)
    getopt_script=$(<getopt.bash)

    ghettopt_function=$(extract_function ghettopt "$ghettopt_script")
    getopt_function=$(extract_function getopt "$getopt_script")

    example_script=$(<example.bash)
    example_script=$(replace_function "$ghettopt_function" "$example_script")
    example_script=$(replace_function "$getopt_function" "$example_script")
    echo "$example_script"
}

extract_function() {
    declare name="$1" script="$2" inner
    inner=${script#*$'\n'$name() \{$'\n'}
    inner=${inner%%$'\n'\}*}
    echo "$name() {"
    echo "$inner"
    echo "}"
}

replace_function() {
    declare function="$1" script="$2" name before after
    name=${function%%(*}
    before=${script%$'\n'$name() \{*}
    after=${script:${#before}}
    after=${after#*$'\n'\}$'\n'}
    echo "$before"
    echo "$function"
    echo "$after"
}

[[ $BASH_SOURCE != "$0" ]] || main "$@"
