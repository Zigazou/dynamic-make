#!/bin/bash
escape_make() { printf '%q' "${1:2}" | sed "s/\\\\'/'/g"; }
escape_shell() { printf '%q' "${1:2}"; }

make_filter() {
    local filters

    printf -- '-type f ( '
    filters="$(for ext in $*; do printf -- '-name *.%s -o ' "$ext"; done)"
    printf '%s )' "${filters% -o }"
}

set -o noglob
compressible="$(make_filter html css js svg xml json)"

printf 'all:'
find . -type f $compressible | while read filepath
do
    fem="$(escape_make "$filepath")"
    printf ' %s.gz %s.br' "$fem" "$fem"
done
printf '\n\n'

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
