# overleaf

Write LaTeX experiment reports locally, compile them with the same engine Overleaf uses (pdfLaTeX via latexmk), and create and sync the matching Overleaf projects from the command line.
macOS only: it uses the keychain and `open`.

```
bin/overleaf                    the command (run it with no arguments for help)
templates/experiment-tracker/   experiment tracking report
  main.tex                      the content: fill this in
  exptracker.cls                layout and macros
  references.bib
projects/<name>/                one report per directory, each its own git
                                clone of an Overleaf project (not tracked here)
```

## Setup

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

   It prompts for the token without echoing it, and stores it in the macOS keychain for `git@git.overleaf.com`.
   Tokens expire after a year, and you can hold at most 10.

4. **Check**: `overleaf doctor <any project URL>`.

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
