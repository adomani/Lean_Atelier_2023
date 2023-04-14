#!/bin/bash

##  `getLinkRef <file>` extracts the content of each
##  "second consecutive square bracket", one per line.
##  For instance
##  ```
##  printf 'text [1][2], more text, [3][4]\n[5][6]' | getLinkRef -
##  > 2\n4\n6\n
##  ```
getLinkRef () {
  sed -n 's=[^[]*\[[^]]*\]\[\([^]]*\)\][^[]*=\1\n=gp' "${1}" |
    tr --squeeze-repeats "/" "\n"
}

if [ "$(whoami)" == "damiano" ]; then
  .  ~/Setup/Tests/testtest.sh
  outerret 'printf "text [1][2], more text, [3][4]\n[5][6]" | getLinkRef -' $'2\n4\n6\n' '' 0
fi

##  `mkLink <file>` search for `<file>.lean` starting from the git root directory
##  returns the url for opening `<file>.lean` with the lean-web-editor.
##  it also assigns as "hover name" to the link the name of the file with
##  underscores (`_`) replaced by spaces (` `).
mkLink () {
  local pth url
  pth="$(git rev-parse --show-toplevel)"
  url='https://leanprover-community.github.io/lean-web-editor/#url=https://raw.githubusercontent.com/'"$(git config --get remote.origin.url | sed 's=.*github\.com/==; s=\.git$==')"'/master'
  find "${pth}" -name "${1}.lean" | sed "s|${pth}|[${1}]: ${url}|; s|$| \"${1//_/ }\"|"
}

##  `allLinks <file>` extracts the md-encoded url-refs from `<file>` and
##  produces the actual url links.
allLinks () {
  (
    cd "$(git rev-parse --show-toplevel)"
    echo '<!--  Autogenerated links  -->'
    for fil in $(getLinkRef "${1}"); do
      mkLink ${fil}
    done
  )
}

##  `autolinksSafe <file>` acts like `autolinks <file>`, but prints to stdout
##  instead of modifying `<file>`.
autolinksSafe () {
  sed '/^<!--  Autogenerated links  -->$/Q' "${1}" |
    tee >(allLinks -) | cat
}

##  `autolinks <file>` extracts the link references from `<file>`,
##  for each `<ref>` searches for `<ref>.lean`,
##  removes from `<file>` everything after `<!--  Autogenerated links  -->` and
##  recreates the end of `<file>` with all the generated links.
autolinks () {
  if [ -z "${1}" ]; then
    >&2 printf 'Usage: autolinks FILE\n'
    return 1
  fi
  autolinksSafe "${1}" > nonexistentfilehere.tmp &&
    mv nonexistentfilehere.tmp "${1}"
}

##  `checkUnlinkedFiles <file>` prints the `.lean` files that are not
##  referenced in `<file>`.
checkUnlinkedFiles () {
  local fil outp
  outp="$({
    for fil in $(getLinkRef "${1}"); do
      echo "./src/$fil.lean"
    done
    find . -type f -name "*.lean" -a -not -path "./_target*"
  } | sort | uniq -u)"
  [ -n "${outp}" ] && >&2 printf '`.lean` files that are not referenced in %s:\n\n%s\n\n' "${1}" "${outp}"
}
