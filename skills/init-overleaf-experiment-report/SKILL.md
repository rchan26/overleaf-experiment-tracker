---
name: init-overleaf-experiment-report
description: Start a new LaTeX experiment report from the overleaf-experiment-tracker template. Creates the local project with `overleaf new`, fills in whatever details the user gives (title, problem statement, hypotheses, approach, evaluation, links), leaves the rest as placeholders, and builds the PDF. Use when the user wants to start, set up or initialise an experiment report or experiment tracker for Overleaf.
argument-hint: <project-name> [initial details]
allowed-tools: Read, Edit, Write, Glob, Grep, AskUserQuestion, Bash(command -v overleaf), Bash(overleaf new *), Bash(overleaf build *), Bash(git config user.name), Bash(gh issue view *), Bash(gh pr view *)
---

Start a new experiment report with the `overleaf` command from the overleaf-experiment-tracker repo, and fill in what the user has already said.

Arguments: $ARGUMENTS

The first word is the project name.
Everything after it is optional initial details in any form: a problem statement, hypotheses, the approach, how it will be evaluated, links, a GitHub issue, loose notes.
Details given earlier in the conversation count too.

## Steps

1. **Check the name.**
   It becomes a directory name and is typed in commands, so it must be short kebab-case, e.g. `window-loss-rft`.
   If it is missing or unsuitable, suggest one based on the details and ask the user to confirm it.
2. **Check the tool.**
   Run `command -v overleaf`.
   If nothing is found, tell the user to follow the Setup section of the overleaf-experiment-tracker README, and stop.
3. **Create the project.**
   Run `overleaf new <name>`.
   It prints the new project directory; the report is `main.tex` in it.
   If the project already exists, stop and ask the user for another name.
   Never delete or overwrite an existing project.
4. **Gather context.**
   If the details name or link a GitHub issue or PR, read it with `gh issue view` or `gh pr view`, and use it as a source.
   If they point at files, such as a planning doc or a config, read those.
5. **Fill in `main.tex`.**
   Read it first: it is the template, with a `\guidance{}` note and `\placeholder{}` text in every section.
   Then edit it:
   - `\title`: from the details, or a working title from the project name.
   - `\author`: `git config user.name`, plus anyone else the user names, joined with `\and`.
   - `\relatedlink`: one per link in the details, including any issue or PR you read.
     Delete the template's example links that you did not replace.
   - Sections: put each detail in the section it belongs to, and replace the `\placeholder{}` it fills.
     Leave the placeholder wherever the user has said nothing.
   - Hypotheses: one `\item` per hypothesis, each with a `\label{hyp:<slug>}`.
     Point the other sections' `\ref{hyp:main}` at the real labels, and delete template items that stay unused.
6. **Build.**
   Run `overleaf build <name>`.
   If it fails, fix the errors it prints and build again until it succeeds.
   Also fix any warnings it prints about undefined references or citations, which show as "??" in the PDF.
7. **Report back.**
   Give the paths to `main.tex` and the PDF, and say which sections you filled and which still have placeholders.
   Then say what the user can do next: edit `main.tex` themselves, ask you to add figures or write up results, or put the report on Overleaf with `overleaf create <name>` then `overleaf link <name> <project URL>`.

## Rules

- Write only what the user said or what the sources you read say.
  Never invent hypotheses, numbers, results, verdicts, citations or reviewer questions: leave a placeholder instead.
  Keep the user's wording, tidying only grammar and LaTeX.
- Keep every `\guidance{}` note.
  The `final` class option hides them once the report is ready.
- In prose, escape `_ % & # $` as `\_ \% \& \# \$`, and put code identifiers, variable names and paths in `\texttt{}`.
  URLs in `\relatedlink` need no escaping.
- The template's Supporting evidence placeholder cites `placeholder2026`.
  Add a real reference to `references.bib` only when the user gives it, or it is in a source you read; never guess bibliographic details.
  If nothing is cited any more, delete the `\bibliographystyle` and `\bibliography` lines.
- Do not run `overleaf create`, `overleaf link` or `overleaf push` unless the user asks, because they publish to Overleaf.

## Template reference

Each section is a numbered list whose items get IDs, which `\ref` prints as links:
`hypotheses` (H1…), `assumptions` (A1…), `approaches` (P1…), `evidence` (E1…), `criteria` (C1…, the Evaluation section), `risks` (R1…), `impacts` (I1…), `questions` (Q1…) and `findings` (F1…, the Results section).

Other macros:

- `\status{}`: Draft, Proposed, In progress, Complete or Abandoned.
- `\version{}`, and `\relatedlink{label}{url}` once per link.
- `\lead{Label}` starts a labelled line inside an item, e.g. `\lead{Rationale}`, `\lead{Alternatives considered}`, `\lead{If \ref{hyp:x} is supported}`, `\lead{Follow-up}`.
- `\verdict{}`: Supported, Partly supported, Inconclusive, Rejected or Pending.
- `\raisedby{Name}` ends a question with who asked it.

The layout and macros are defined in `exptracker.cls` in the project directory.

## Later requests on the same report

The user may go on to ask for more, such as plots or results.
Keep to the rules above, and rebuild with `overleaf build <name>` after every change.

- **Figures**: put image files in `figures/` in the project, as PDF for plots and PNG otherwise.
  Include each in a `figure` environment next to the text that discusses it, with a `\caption` and a `\label{fig:<slug>}`, and refer to it with `\ref`.
  The whole project directory is uploaded to Overleaf, so keep plotting scripts and raw data outside it unless the user wants them in the report.
- **Tables**: `booktabs` is loaded, so use `\toprule`, `\midrule` and `\bottomrule`.
- **Results**: one `findings` item per result.
  Start it with a `\verdict{}` and the `\ref` of the hypothesis it tests, then the result with its numbers and a pointer to the figure or table.
  Put next steps after `\lead{Follow-up}`.
  Choose a verdict only from what the results show, and ask the user if it is unclear.
- **Status**: update `\status{}` and `\version{}` when the user says the experiment has moved on.
- **Ready to share**: add the `final` class option, build, and list any "Unfilled placeholder" warnings from the build output.
