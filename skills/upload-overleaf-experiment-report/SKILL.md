---
name: upload-overleaf-experiment-report
description: Upload a local experiment report to Overleaf as a new Overleaf project, and link the local directory to it so `overleaf pull` and `overleaf push` keep the two in sync. Does nothing if the report is already on Overleaf. Use when the user wants to upload a report to Overleaf, put it on Overleaf, or create its Overleaf project.
argument-hint: <project-name>
allowed-tools: Read, AskUserQuestion, Bash(overleaf status *), Bash(overleaf build *), Bash(overleaf doctor), Bash(overleaf create *), Bash(overleaf link *)
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
4. **Create the Overleaf project.**
   Run `overleaf create <name>`.
   It opens a browser tab that creates the project in whichever Overleaf account is signed in to that browser.
   Then tell the user:
   - If Overleaf asked them to sign in first, the project may not have been created; say so, and you will run the command again.
   - Overleaf picks the project's name; they can rename it under Menu > Rename.
   - Paste the project's URL (`https://www.overleaf.com/project/<id>`) here once it has loaded.

   Wait for the URL.
   Run `overleaf create` again only if the user says no project was created, so that you do not make duplicates.
5. **Link it.**
   Run `overleaf link <name> <URL>`.
   It adopts the Overleaf project's git history in the local directory, then lists any local files that differ from the Overleaf project.
   The list is normally empty, because the project was just created from these files.
   If it is not empty, show it to the user.
   Many differences suggest the URL belongs to a different project: check with the user before anything else.
   Upload the local versions with `overleaf push <name> "<message>"` only if the user agrees.
6. **Report back.**
   Give the Overleaf URL and the local directory.
   Explain how to keep them in sync: `overleaf pull <name>` brings in edits made on Overleaf, and `overleaf push <name> "<message>"` uploads local changes.

## Rules

- Create at most one Overleaf project per upload, and never one for a report that is already linked.
- Only push when the user asks: it publishes to a project others may share.
- Never read, print or store the Overleaf token.
