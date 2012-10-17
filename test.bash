#!/bin/bash

source ghettopt.bash

main() {
  fails=0

  test <<<''
  test --foo <<<'status=1'
  test --foo=x <<<'opt_foo=x'
  test --foo x <<<'opt_foo=x'
  test --foo='x y' <<<'opt_foo="x y"'
  test --bar=two <<<'opt_bar=two'
  test --bool <<<''
  test --no-bool <<<'opt_bool=false'
  test --bule <<<'opt_bule=true'
  test --no-bule <<<''
  test --arr=x --arr=y <<<'opt_arr=(x y)'
  test --help <<<'help_called=1'
  test --help= <<<'status=1'
  test --colon=value <<<'colon_value=value'
  test x 'y z' <<<'params=(x "y z")'
  test -- --bool <<<'params=(--bool)'

  echo
  printf "%d pass, %d fail\n" "$passes" "$fails"
  exit $((!!fails))
}

reset() {
  unset ${!opt_*}
  opt_foo=
  opt_bar=one
  opt_bool=true
  opt_bule=false
  opt_arr=()
  help_called=0
  opt_help() { help_called=1; }
  colon_value=
  opt_colon:() { colon_value=$1; }
  parsed_opts=()
  params=()
  status=0
}

check() {
  # "parsed_opts" omitted intentionally... just makes things verbose
  set | egrep '^(opt_.*|help_called|colon_value|params|status)='
}

test() {
  read -rd '' expected
  reset
  expected=$(eval "$(check); $expected"; check)

  if [[ $# -gt 0 ]]; then
    printf '%q ' "$@"
  else
    echo -n '(nothing) '
  fi
  echo -n '... '

  ghettopt "$@" 2>/dev/null || status=$?

  actual=$(check)
  if diffs=$(diff -u <(echo "$expected") <(echo "$actual")); then
    echo "pass"
    (( passes++ ))
  else
    echo "fail"
    echo "============"
    echo "$diffs"
    echo
    (( fails++ ))
  fi
}

main "$@"

# vim:sw=2
