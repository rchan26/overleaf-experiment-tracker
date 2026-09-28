#!/bin/sh
# Checks each skill in an overleaf-experiment-tracker clone against the skills
# directory this script is installed in. Prints one line per finding: a status
# (ok, warn or fail), the skill's name and a detail. Changes nothing.
set -u

tool=$(cd "${1:?usage: check-skills.sh <clone>}" && pwd -P)
# Found without resolving symlinks, since this skill may itself be a link into
# the clone.
skills=$(cd "$(dirname "$0")/.." && pwd -L)
user_skills="$HOME/.claude/skills"

report() {
  printf '%-4s  %-34s  %s\n' "$1" "$2" "$3"
}

for src in "$tool"/skills/*/; do
  name=$(basename "$src")
  src=$(cd "$src" && pwd -P)
  dest="$skills/$name"
  if [ -L "$dest" ] && [ ! -e "$dest" ]; then
    report fail "$name" "broken link to $(readlink "$dest")"
  elif [ -L "$dest" ]; then
    target=$(cd "$dest" && pwd -P)
    if [ "$target" != "$src" ]; then
      report warn "$name" "links to $target, not this clone"
    elif git -C "$skills" ls-files --error-unmatch "$name" >/dev/null 2>&1; then
      report warn "$name" "link is tracked by $(git -C "$skills" rev-parse --show-toplevel), so others get a link into your clone"
    else
      report ok "$name" "links to this clone"
    fi
  elif [ -d "$dest" ]; then
    if diff -rq "$src" "$dest" >/dev/null 2>&1; then
      report ok "$name" "copy, same as this clone"
    else
      report warn "$name" "copy, differs from this clone"
    fi
  else
    report warn "$name" "not installed in $skills"
  fi

  # The same skill in another discovered location is listed twice.
  if [ "$skills" != "$user_skills" ] && [ -e "$user_skills/$name" ]; then
    report warn "$name" "also in $user_skills, so Claude Code lists it twice"
  fi
  if [ "$skills" != "$tool/.claude/skills" ] && [ -e "$tool/.claude/skills/$name" ]; then
    report warn "$name" "also in $tool/.claude/skills, which Claude Code may list again when you work in the clone"
  fi
done
