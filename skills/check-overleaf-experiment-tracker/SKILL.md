---
name: check-overleaf-experiment-tracker
description: Check that the overleaf-experiment-tracker tool is set up correctly, without changing anything. Verifies that the `overleaf` command links to the clone, that a clone nested in another repository is ignored by it, TeX, the Overleaf Git token and Git access, that the tracker's Claude Code skills are sound links or up-to-date copies, and that the template builds. Use when the user wants to check, verify, diagnose or troubleshoot the overleaf-experiment-tracker setup.
argument-hint: [Overleaf project URL]
allowed-tools: Read, Glob, Grep, Bash(command -v *), Bash(readlink *), Bash(uname)
---

Check the overleaf-experiment-tracker setup on this machine, and report what is wrong and how to fix it.
Fix nothing yourself: the user decides what to change, usually by running `/setup-overleaf-experiment-tracker`.

Arguments: $ARGUMENTS

If given, the argument is an Overleaf project URL to test Git access with.

## Steps

1. **Find the clone.**
   Call it `TOOL`: the absolute path of the directory containing `bin/overleaf` and `templates/`.
   Use the first of these that works:
   - this skill's own directory (`${CLAUDE_SKILL_DIR}`, the base directory shown when the skill loads), if `readlink -f` resolves it to `TOOL/skills/check-overleaf-experiment-tracker`;
   - `command -v overleaf`, if `readlink -f` resolves it to `TOOL/bin/overleaf`;
   - a search of the current project, up to three levels deep, for a `bin/overleaf` next to `templates/experiment-tracker/`.

   If nothing matches, or more than one clone does, ask the user which one to check.
   If the platform is not macOS (`uname` is not `Darwin`), report that the tool does not support it and stop.
2. **Run the tool's checks.**
   Run `"$TOOL/bin/overleaf" doctor`, adding the project URL if one was given.
   Call it by path rather than through `PATH`, so it checks this clone even if the `PATH` link is wrong.
   It exits non-zero when anything fails; read its output either way.
   Each line gives a status (`ok`, `warn`, `fail` or `skip`), the check and a detail:
   - `command`: `overleaf` on `PATH` is a link to this clone, not a broken link, a copy or another clone.
   - `nesting`: if the clone is inside another repository, that repository ignores it and tracks none of its files.
   - `tex`: pdfLaTeX and latexmk are found, and so is tlmgr, which `build` uses to install missing packages.
   - `token`: git's credential helper holds an Overleaf token.
   - `git`: the token can read a project: the URL given, or else the first project under `projects/` linked to Overleaf.
   - `projects`: how many projects are linked to Overleaf.
3. **Check the skills.**
   Run `sh "${CLAUDE_SKILL_DIR}/check-skills.sh" "$TOOL"`.
   It compares each skill in `TOOL/skills/` with the skills directory this skill is installed in, and prints one line per finding:
   - `ok`: a link to this clone, or a copy identical to the clone's version.
   - `fail`: a broken link, e.g. after the clone or the outer repository moved.
   - `warn`: missing; a copy that differs from the clone (out of date, or edited); a link to a different clone; a link tracked by a repository, which gives everyone else a link into your clone; or a second copy in `~/.claude/skills/` or the clone's own `.claude/skills/`, which Claude Code would also list.
4. **Check a build.**
   Copy `TOOL/templates/experiment-tracker` into a new temporary directory, run `"$TOOL/bin/overleaf" build` on the copy, then delete the temporary directory.
   This shows that TeX can build the template.
   If LaTeX packages are missing, `build` installs them; tell the user if it did, since it is the only change this skill makes.
5. **Report back.**
   Give a short checklist: each check, its result, and for each `warn` or `fail`, the fix.
   Say which fixes `/setup-overleaf-experiment-tracker` makes, and give the exact command for any that are one line.
   Only the user can fix a token problem: they generate a token under Git integration in Overleaf's Account settings, then run `overleaf login` in their own terminal.
   If a `git` failure mentions authentication, the token is wrong or has expired (tokens last a year).
   If everything passes, say so in one line.

## Rules

- Change nothing: do not create, link, copy, edit or delete anything except the temporary build directory.
- Never read, print or store the Overleaf token.
