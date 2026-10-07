---
name: init-overleaf-document
description: Start a new general LaTeX document, such as notes, a write-up or a paper draft, from the overleaf-experiment-tracker repo's `document` template. Creates the local project with `overleaf new <name> document`, fills in the title, authors and any outline or content the user gives, and builds the PDF. Use when the user wants to start a LaTeX or Overleaf document that is not an experiment report; for an experiment report, use init-overleaf-experiment-report.
argument-hint: <project-name> [title, authors, outline or notes]
allowed-tools: Read, Edit, Write, Glob, Grep, AskUserQuestion, Bash(command -v overleaf), Bash(overleaf new *), Bash(overleaf build *), Bash(git config user.name), Bash(gh issue view *), Bash(gh pr view *)
---

Start a new LaTeX document from the plain `document` template of the overleaf-experiment-tracker repo, using its `overleaf` command, and fill in what the user has already said.

Arguments: $ARGUMENTS

The first word is the project name.
Everything after it is optional, in any form: a title, authors, what the document is for, an outline of its sections, or notes on what goes in them.
Details given earlier in the conversation count too.

## Steps

1. **Check the name.**
   It becomes a directory name and is typed in commands, so it must be short kebab-case, e.g. `forecast-notes`.
   If it is missing or unsuitable, suggest one based on the details and ask the user to confirm it.
2. **Check the tool.**
   Run `command -v overleaf`.
   If nothing is found, tell the user to follow the Setup section of the overleaf-experiment-tracker README, and stop.
3. **Create the project.**
   Run `overleaf new <name> document`.
   It prints the new project directory; the document is `main.tex` in it.
   If the project already exists, stop and ask the user for another name.
   Never delete or overwrite an existing project.
4. **Gather context.**
   If the details name or link a GitHub issue or PR, read it with `gh issue view` or `gh pr view`, and use it as a source.
   If they point at files, such as notes or a planning doc, read those.
5. **Fill in `main.tex`.**
   Read it first: it is a plain `article` with an empty `\title{}`, `\author{}` and `\date{}`, an Introduction section, and a bibliography drawn from `biblio.bib`.
   Then edit it:
   - `\title`: from the details, or a working title from the project name.
   - `\author`: `git config user.name`, plus anyone else the user names, joined with `\and`.
   - `\date`: leave it empty unless the user gives a date or asks for one; `\date{\today}` prints the build date.
   - Sections: if the details give an outline, write one `\section` per heading, in order, and `\subsection`s for points nested under a heading.
     Replace the template's Introduction with them, unless the outline starts with an introduction.
     Put any content the user gave under its heading, and leave the other sections empty.
   - Without an outline, keep the Introduction, and put in it any text the user gave for the document.
6. **Build.**
   Run `overleaf build <name>`.
   If it fails, fix the errors it prints and build again until it succeeds.
   Also fix any warnings it prints about undefined references or citations, which show as "??" in the PDF.
   A warning about an empty `thebibliography` environment is expected while nothing is cited.
7. **Report back.**
   Give the paths to `main.tex` and the PDF, and say what you filled in.
   Then say what the user can do next: edit `main.tex` themselves, ask you to write sections or add figures, or put the document on Overleaf with `/upload-overleaf-experiment-report <name>`, which handles documents as well as reports.

## Rules

- Write only what the user said or what the sources you read say.
  Never invent content, numbers, results or citations: leave a section empty instead.
  Keep the user's wording, tidying only grammar and LaTeX.
- Write one sentence or statement per line, and never wrap a paragraph to a line width.
  Inside an item or a caption, put each following sentence on its own indented line.
  Comments follow the same rule.
  Keep to it in every later edit too, so a changed sentence is one changed line on Overleaf.
- In prose, escape `_ % & # $` as `\_ \% \& \# \$`, and put code identifiers, variable names and paths in `\texttt{}`.
  `hyperref` is loaded, so write links as `\url{...}` or `\href{url}{text}`.
- Add a reference to `biblio.bib` only when the user gives it, or it is in a source you read; never guess bibliographic details.
  Cite it with `\cite{key}`, which the `apalike` style prints as (Author, year).
  Keep the `\bibliographystyle` and `\bibliography` lines even before anything is cited, so that citing works as soon as an entry is added, unless the user wants no references section.
- This skill works locally only.
  Do not run `overleaf create`, `overleaf link` or `overleaf push` unless the user asks, because they publish to Overleaf.
  If the user asks to upload the document, use the upload-overleaf-experiment-report skill.

## Template reference

The template loads `hyperref` (black internal links, blue citations and URLs), `xcolor`, `multicol`, `geometry` (A4 with a 7 by 10 inch text area) and `blindtext`.
`\blindtext` prints filler text for trying out a layout; remove it before the document is shared.
Text between the `%%%%` comment rules is the body; the bibliography starts on a new page.

## Later requests on the same document

The user may go on to ask for more, such as sections, figures or tables.
Keep to the rules above, and rebuild with `overleaf build <name>` after every change.

- **Figures**: the template does not load `graphicx`, so add `\usepackage{graphicx}` to the preamble before the first figure.
  Put image files in `figures/` in the project, as PDF for plots and PNG otherwise.
  Include each in a `figure` environment next to the text that discusses it, with a `\caption` and a `\label{fig:<slug>}`, and refer to it with `\ref`.
  The whole project directory is uploaded to Overleaf, so keep scripts and raw data outside it unless the user wants them in the document.
- **Tables**: add `\usepackage{booktabs}` to the preamble, and use `\toprule`, `\midrule` and `\bottomrule`.
- **Columns**: `multicol` is loaded, so put two-column text in `\begin{multicols}{2}` and `\end{multicols}`.
