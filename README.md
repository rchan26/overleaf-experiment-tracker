# overleaf-experiment-tracker

Write LaTeX experiment reports locally, compile them with the same engine Overleaf uses (pdfLaTeX via latexmk), and create and sync the matching Overleaf projects from the command line.
macOS only: it uses the keychain and `open`.

```
bin/overleaf                    the command (run it with no arguments for help)
templates/experiment-tracker/   experiment tracking report
  main.tex                      the content: fill this in
  exptracker.cls                layout and macros
  references.bib
skills/                         Claude Code skills (see "Claude Code skills")
projects/<name>/                one report per directory, each its own git
                                clone of an Overleaf project (not tracked here)
```

## Setup

With Claude Code, the `setup-overleaf-experiment-tracker` skill can do these steps for you: see [Claude Code skills](#claude-code-skills).

1. **Put the command on your PATH**, from the repo root:

   ```sh
   ln -s "$PWD/bin/overleaf" ~/.local/bin/overleaf
   ```

2. **Install TeX.**
   TinyTeX is a small TeX Live distribution that goes in `~/Library/TinyTeX` and needs no admin rights:

   ```sh
   curl -sL https://yihui.org/tinytex/install-bin-unix.sh | sh
   ```

   At the end it asks for your password to add TinyTeX to the shell `PATH`.
   `overleaf` finds TinyTeX without that.
   Any other TeX distribution on `PATH` (e.g. MacTeX) also works.

3. **Store an Overleaf Git token.**
   Git integration needs a premium Overleaf plan, which many institutional licences include.
   In Account settings, under Git integration, generate a token, then run:

   ```sh
   overleaf login
   ```

   It prompts for the token without echoing it, and stores it for `git@git.overleaf.com` with git's credential helper (the macOS keychain by default).
   Tokens expire after a year, and you can hold at most 10.

4. **Check** with `overleaf doctor`.
   It prints `ok`, `warn`, `fail` or `skip` for each check: the command link, nesting inside another repository, TeX, the token, and Git access.
   Git access is tested on the first project linked to Overleaf, or on a project you name: `overleaf doctor <project URL>`.

### Inside another repository

To keep reports next to the code they describe, clone this repo into another repository's working tree, such as a monorepo, and hide it from that repository:

```sh
cd path/to/monorepo
git clone git@github.com:rchan26/overleaf-experiment-tracker.git overleaf
echo "/overleaf/" >> .git/info/exclude
ln -s "$PWD/overleaf/bin/overleaf" ~/.local/bin/overleaf
```

- This is a plain nested clone, not a submodule, so the outer repository records nothing about it.
- Excluding the folder stops the outer repository listing it as untracked, and stops `git add -A` there from adding it as an embedded repository.
- `.git/info/exclude` only applies to your own clone, so the outer repository's committed `.gitignore` stays unchanged.
  If everyone on the team uses this layout, add `/overleaf/` to that `.gitignore` instead.
- There are three levels of git repository: the outer repository, this one, and one Overleaf clone per project under `overleaf/projects/`.
  Git acts on the innermost repository containing the current directory, so from the outer repository's root, use `git -C overleaf ...` for this one.
- `overleaf` commands take project names, so they work from anywhere, e.g. `overleaf build my-experiment` from the outer repository's root.
- Update the tool with `git -C overleaf pull`.
- `git clean -fdx` in the outer repository leaves the nested clone alone, but a doubled force (`git clean -ffdx`) deletes it, along with any reports not yet pushed to Overleaf.

### Claude Code skills

`skills/` holds three [Claude Code](https://code.claude.com/docs/en/skills) skills:

- `setup-overleaf-experiment-tracker` does the setup above for you.
  It links the command onto your PATH, hides a nested clone from the outer repository, installs TinyTeX if it finds no TeX, installs the other skills, and checks your Overleaf Git token.
  It cannot store the token itself, so if there is none, it tells you how to create one and run `overleaf login`.
  It is safe to run again, e.g. after pulling an update.
- `check-overleaf-experiment-tracker` checks the setup without changing anything, and says how to fix what it finds.
  It runs `overleaf doctor` and a test build of the template.
  It also checks that each skill is a working link to this clone or an up-to-date copy.
  In the nested layout it warns about a link that the outer repository tracks, or a skill that Claude Code would list twice.
- `init-overleaf-experiment-report` starts a report:

  ```
  /init-overleaf-experiment-report my-experiment <problem statement, hypotheses, links, ...>
  ```

  It creates the project with `overleaf new`, fills in whatever details you give it, leaves placeholders for the rest, and builds the PDF.
  Then you can edit `main.tex` yourself, or keep asking Claude in the same session, e.g. to add plots or write up results.
  It never uploads to Overleaf unless you ask.

Claude Code looks for project skills in `.claude/skills/` at the root of the repository you run it in.
Install the setup skill there by hand, and it installs the other skills next to itself.
Run the following from that root, with `TOOL` set to the path of this repo (e.g. `overleaf` when nested, `.` when working in this repo itself):

```sh
TOOL=overleaf
mkdir -p .claude/skills
cp -R "$TOOL/skills/setup-overleaf-experiment-tracker" .claude/skills/
```

Then run `/setup-overleaf-experiment-tracker` in Claude Code.

- Copies do not change when you pull this repo.
  After pulling, re-run the `cp`, then the setup skill, which offers to update the other copies.
- To stay in sync instead, symlink the setup skill with `ln -s "$(cd "$TOOL" && pwd)/skills/setup-overleaf-experiment-tracker" .claude/skills/`, and it symlinks the other skills too.
  A symlink points into your own clone, so only use one if `.claude/` is not committed.
- To have the skills in every repository, install them into `~/.claude/skills/` instead.

## Workflow

```sh
overleaf new my-experiment                  # copy the template to projects/my-experiment
# ... edit projects/my-experiment/main.tex ...
overleaf build my-experiment                # -> projects/my-experiment/build/main.pdf
overleaf watch my-experiment                # or rebuild on every save

overleaf create my-experiment               # new Overleaf project, opens in the browser
overleaf link my-experiment <project URL>   # connect the local copy to it

overleaf pull my-experiment                 # Overleaf -> local
overleaf push my-experiment "add results"   # local -> Overleaf
```

Commands take the name of a project under `projects/` or a path to any directory.
To work on an existing Overleaf project, run `overleaf clone <project URL> <name>` instead of `new`, `create` and `link`.

Notes:

- `build` puts everything in `<dir>/build/`, which is excluded from the Overleaf git repo.
  If a package is missing, `build` installs it with `tlmgr` and retries.
  `watch` does not, so run `build` once after adding a package.
- `push` commits all local changes, rebases them on any edits made in the browser, and pushes.
  Resolve any rebase conflict with plain git in the project directory.
- Overleaf's git has one branch, and no tags, submodules or LFS.
  Renaming a file over git drops its Overleaf comments and tracked changes.
- To match `build`, keep the Overleaf compiler at pdfLaTeX (Menu > Compiler).
  `create` sets that already.

## How it talks to Overleaf

Overleaf has no general REST API.
`overleaf` uses its two official routes:

- **Creating a project**: the "Open in Overleaf" endpoint (<https://www.overleaf.com/devs>).
  `create` zips a directory, and opens a browser tab that posts the zip to `https://www.overleaf.com/docs`.
  The project is created in whichever account is logged in to that browser.
- **Syncing a project**: Overleaf Git integration (`https://git.overleaf.com/<project-id>`).
  Git logs in as user `git` with the token stored by `overleaf login`.

## Experiment tracker template

Every section has a numbered list, and each list gives its items IDs:

| Environment   | IDs | Section                             |
| ------------- | --- | ----------------------------------- |
| `hypotheses`  | H1… | Hypotheses                          |
| `assumptions` | A1… | Assumptions                         |
| `approaches`  | P1… | Proposed approach and model choices |
| `evidence`    | E1… | Supporting evidence                 |
| `criteria`    | C1… | Evaluation                          |
| `risks`       | R1… | Risks and limitations               |
| `impacts`     | I1… | Expected impact                     |
| `questions`   | Q1… | Questions and feedback              |
| `findings`    | F1… | Results                             |

Put `\label{hyp:foo}` on an item, and `\ref{hyp:foo}` elsewhere prints its ID (`H1`) as a link.
Other macros:

- Preamble: `\version{}`, `\status{Draft | Proposed | In progress | Complete | Abandoned}`, and `\relatedlink{label}{url}` once per link.
  URLs need no escaping.
- In items: `\lead{Rationale}`, which starts a labelled line such as "Rationale:" or "If H1 is supported:".
  Also `\verdict{Supported | Partly supported | Inconclusive | Rejected | Pending}`, and `\raisedby{Name}` for the person who asked a question.
- `\guidance{}` for the grey notes under each heading, and `\placeholder{}` for text still to fill in.
  `\documentclass[final]{exptracker}` hides the guidance and lists each leftover placeholder as a warning in the log.

To add another template, create a directory under `templates/` with a `main.tex`, and start reports from it with `overleaf new <name> <template>`.
