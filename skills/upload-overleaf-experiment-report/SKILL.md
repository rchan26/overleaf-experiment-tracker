---
name: upload-overleaf-experiment-report
description: Upload a local experiment report to Overleaf as a new Overleaf project, and link the local directory to it so `overleaf pull` and `overleaf push` keep the two in sync. Does nothing if the report is already on Overleaf. Use when the user wants to upload a report to Overleaf, put it on Overleaf, or create its Overleaf project.
argument-hint: <project-name>
allowed-tools: Read, Edit, AskUserQuestion, Bash(overleaf status *), Bash(overleaf build *), Bash(overleaf doctor), Bash(overleaf create *), Bash(overleaf link *), Bash(du *), Bash(mktemp *), Bash(rsync *)
---

Upload a local report, as made by `overleaf new` or `/init-overleaf-experiment-report`, to Overleaf as a new project, and link the local directory to it.

Arguments: $ARGUMENTS

The argument is the project's name under `projects/` in the overleaf-experiment-tracker clone, or a path to its directory.
If it is missing, ask the user which project to upload.

## Steps

1. **Check whether it is already on Overleaf.**
   Run `overleaf status <name>`.
   - `linked to <URL>`: the report is already on Overleaf, so there is nothing to upload.
     Give the user the URL and stop.
     If `main.tex` has an empty `\overleafproject{}`, offer to fill it in with that URL.
     If the output also lists local changes, say that `overleaf push <name>` would upload them, but do not run it.
   - `not linked to Overleaf: ... is a git repository with origin ...`: the directory is its own git repository but not an Overleaf project, and linking it would replace that repository's history.
     Stop and ask the user what they want.
   - `not linked to Overleaf: <dir>`: carry on.
   - An error that the directory does not exist: ask the user to check the name.
2. **Build it.**
   Run `overleaf build <name>`, so that what goes to Overleaf compiles.
   If the build fails, show the errors, and ask whether to fix them first or upload anyway.
3. **Check the token.**
   Linking needs Overleaf Git access, so check it before creating anything.
   Run `overleaf doctor` and read its `token` line; it exits non-zero when any check fails, so read its output either way.
   If `token` is `fail`, tell the user to generate a token under Git integration in Overleaf's Account settings, then run `overleaf login` in their own terminal.
   `overleaf login` reads the token with hidden input, which needs a real terminal, so it cannot run inside Claude Code, not even with the `!` prefix.
   Wait until they say it is done, and run `overleaf doctor` again.
4. **Check the size.**
   `overleaf create` sends the whole project, zipped, inside one browser request, and Overleaf rejects one that is too large.
   Run `du -sh <dir>/figures` (and on any other directory of images or data).
   If the figures come to more than a few megabytes, use the text-only route in step 5.
   Overleaf does not document the limit: a report whose zip was 12.5 MB, almost all PNG figures, was rejected, and its text files alone were accepted.
5. **Create the Overleaf project.**
   Run `overleaf create <name>`.
   For the text-only route, first copy the report's text sources to a temporary directory, and create the project from that copy instead:

   ```sh
   seed=$(mktemp -d)/<name>
   rsync -am --exclude build/ --exclude .git/ --include '*/' \
     --include '*.tex' --include '*.cls' --include '*.sty' --include '*.bib' --include '*.bst' \
     --exclude '*' <dir>/ "$seed"/
   overleaf create "$seed"
   ```

   `overleaf create` opens a browser tab that creates the project in whichever Overleaf account is signed in to that browser.
   Then tell the user:
   - If Overleaf asked them to sign in first, the project may not have been created; say so, and you will run the command again.
   - Overleaf picks the project's name; they can rename it under Menu > Rename.
   - On the text-only route, the project will not compile until the figures are pushed.
   - Paste the project's URL (`https://www.overleaf.com/project/<id>`) here once it has loaded.

   Wait for the URL.
   If the user reports "Something went wrong, sorry. There was a problem with your request.", Overleaf rejected the request and created no project: run the text-only route, even if the figures looked small.
   Otherwise run `overleaf create` again only if the user says no project was created, so that you do not make duplicates.
6. **Link it.**
   Run `overleaf link <name> <URL>` on the report itself, never on the temporary copy, whatever link command `overleaf create` printed.
   It adopts the Overleaf project's git history in the local directory, then lists any local files that differ from the Overleaf project.
   The list is normally empty, because the project was just created from these files.
   On the text-only route it lists the files the copy left out, normally just `figures/`; tell the user that pushing them completes the upload.
   Otherwise, if it is not empty, show it to the user.
   Many differences suggest the URL belongs to a different project: check with the user before anything else.
7. **Record the URL in the report.**
   If `main.tex` has `\overleafproject{}`, fill in the project URL, and run `overleaf build <name>` to check it renders.
   A report whose class file predates `\overleafproject` has neither the command nor the row, so leave it alone.
   This edit is a local change, so upload it with any files from step 6: run `overleaf push <name> "<message>"` only if the user agrees.
8. **Report back.**
   Give the Overleaf URL and the local directory.
   Explain how to keep them in sync: `overleaf pull <name>` brings in edits made on Overleaf, and `overleaf push <name> "<message>"` uploads local changes.

## Rules

- Create at most one Overleaf project per upload, and never one for a report that is already linked.
  A request Overleaf rejected created nothing, so the text-only route after it is not a second project.
- Only push when the user asks: it publishes to a project others may share.
- Never read, print or store the Overleaf token.
