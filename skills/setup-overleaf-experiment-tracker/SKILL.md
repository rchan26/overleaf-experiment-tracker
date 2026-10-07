---
name: setup-overleaf-experiment-tracker
description: Set up a clone of the overleaf-experiment-tracker repo on this machine. Puts the `overleaf` command on PATH, hides a nested clone from the outer git repository, installs TinyTeX if no TeX is found, installs the tracker's other Claude Code skills, and checks the Overleaf Git token, guiding the user to create one if it is missing. Use when the user wants to set up, install or update the overleaf-experiment-tracker tool or its Overleaf connection; to only check the setup, use check-overleaf-experiment-tracker.
argument-hint: [path to the overleaf-experiment-tracker clone]
allowed-tools: Read, Glob, Grep, AskUserQuestion, Bash(command -v *), Bash(readlink *), Bash(uname)
---

Set up a clone of the overleaf-experiment-tracker repo on this machine.
Assume the user has already cloned it where they want it, and copied or linked this skill into a `.claude/skills/` directory.
Every step checks before it changes anything, so the skill is safe to run again, e.g. after pulling an update.

Arguments: $ARGUMENTS

If given, the argument is the path to the clone.

## Steps

1. **Check the platform.**
   The tool uses the macOS keychain and `open`, so stop if `uname` does not print `Darwin`.
2. **Find the clone.**
   Call it `TOOL`: the absolute path of the directory containing `bin/overleaf` and `templates/`.
   Use the first of these that works:
   - the path in the arguments;
   - this skill's own directory (`${CLAUDE_SKILL_DIR}`, the base directory shown when the skill loads), if `readlink -f` resolves it to `TOOL/skills/setup-overleaf-experiment-tracker`;
   - `command -v overleaf`, if `readlink -f` resolves it to `TOOL/bin/overleaf`;
   - a search of the current project, up to three levels deep, for a `bin/overleaf` next to `templates/experiment-tracker/`.

   If nothing matches, or more than one clone does, ask the user for the path.
3. **Hide a nested clone.**
   If `git -C "$(dirname "$TOOL")" rev-parse --show-toplevel` succeeds, the clone sits inside another repository; call that `OUTER`.
   If `git -C "$OUTER" check-ignore -q "$TOOL"` fails, the outer repository would list the clone as untracked.
   To stop that, add `/<path of TOOL relative to OUTER>/` as a line in the file printed by `git -C "$OUTER" rev-parse --path-format=absolute --git-path info/exclude`.
   Never edit the outer repository's committed `.gitignore`; tell the user they can move the line there if their whole team uses this layout.
4. **Put the command on PATH.**
   - If `command -v overleaf` resolves to `TOOL/bin/overleaf`, it is already done.
   - If it resolves anywhere else, another copy of the tool is installed: ask before replacing it.
   - Otherwise create `~/.local/bin` if needed, and run `ln -s "$TOOL/bin/overleaf" ~/.local/bin/overleaf`.

   If `~/.local/bin` is not on `PATH`, ask whether to add `export PATH="$HOME/.local/bin:$PATH"` to the shell's startup file (`~/.zshrc` for zsh), and tell the user it takes effect in new terminals.
   Until then, run the command as `"$TOOL/bin/overleaf"`.
5. **Install TeX.**
   Run `overleaf doctor`, which prints one line per check: a status (`ok`, `warn`, `fail` or `skip`), the check's name and a detail.
   It exits non-zero when any check fails, so read its output either way.
   If the `tex` line is `ok`, TeX is ready.
   If it is `fail`, tell the user you are installing TinyTeX into `~/Library/TinyTeX`: a download of about 65 MB, about 250 MB installed, no admin rights needed. Then run:

   ```sh
   dl=$(mktemp -d) && mkdir "$dl/archive"
   curl -fsSL -o "$dl/install-tinytex.sh" https://yihui.org/tinytex/install-bin-unix.sh
   (cd "$dl" && TMPDIR="$dl" sh install-tinytex.sh "$dl/archive" --no-path)
   rm -rf "$dl"
   ```

   The installer treats its first argument as a directory to keep the downloaded archive in, so it must come before `--no-path`.
   `--no-path` skips the admin-password step that adds TinyTeX to the shell `PATH`; `overleaf` finds TinyTeX without it.
   The download can take several minutes, so run it in the background if you can, and wait for it to finish.

   After installing TinyTeX, build each template once, so the LaTeX packages they need are installed now rather than on the first report: run `overleaf build "$TOOL/templates/<template>"` for each directory in `TOOL/templates/`, then delete the `build/` directory it creates there.
6. **Install the other skills.**
   This skill sits in a skills directory: the parent of `${CLAUDE_SKILL_DIR}`.
   Install every other skill in `TOOL/skills/` into that directory, the same way this one was installed:
   - If this skill's directory is a symlink, symlink the others to `TOOL/skills/<name>`.
   - Otherwise copy them with `cp -R`.

   Skip any that are already there and identical.
   If an installed copy differs from the clone's version, ask before replacing it.
7. **Check the Overleaf Git token.**
   Run `overleaf doctor` and read its `token` line.
   If it is `fail`, give the user these steps:
   1. Sign in to Overleaf, open Account settings, and generate a token under Git integration.
      Git integration needs a premium plan, which many institutional licences include.
   2. Run `overleaf login` in their own terminal, and paste the token when prompted.
      It reads the token with hidden input, which needs a real terminal, so it cannot run inside Claude Code, not even with the `!` prefix.

   Never ask the user to paste the token into the chat.
   Wait for the user to say they have done it, then run `overleaf doctor` again.
   If `overleaf login` reported that no credential helper saved the token, suggest `git config --global credential.helper osxkeychain`, and ask before running it.
8. **Check Git access.**
   `overleaf doctor` tests Git access with the first project under `projects/` that is linked to Overleaf.
   If its `git` line is `skip`, there is none: ask the user for the URL of any Overleaf project they own, and run `overleaf doctor <URL>`.
   If the `git` line is `ok`, Overleaf Git access works.
   If it is `fail` with an authentication error, the token is wrong or has expired (tokens last a year): ask the user to generate a new one and run `overleaf login` again.
   If the user has no Overleaf project yet, skip this step: the first `overleaf create` makes one.
9. **Report back.**
   List what you changed, what was already in place, and anything the user still has to do.
   Point them at `/init-overleaf-experiment-report <project-name> [details]` for starting an experiment report, `/init-overleaf-document <project-name> [details]` for any other document, `/check-overleaf-experiment-tracker` for checking the setup later, and `"$TOOL/README.md"` for the full workflow.

## Rules

- Ask before replacing anything that already exists, and before editing shell startup files or global git config.
- Never read, print or store the Overleaf token yourself.
- Do not commit anything, in the clone or in the outer repository.
