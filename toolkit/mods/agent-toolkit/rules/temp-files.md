# Temp files go in the project's .temp/ directory

Every scratch file an AI agent creates goes in `<project>/.temp/`. System temp
directories are off limits for agent-written files.

## Rules

1. **Write scratch files to `<project>/.temp/`.** The project dir is the root of
   the repo or workspace you are working in — not a package subdirectory, not the
   parent of the repo. Create it on demand: `mkdir -p .temp`.
2. **Never use a system temp directory:** `/tmp`, `/private/tmp`, `/var/tmp`,
   `/var/folders/…`, `/dev/shm`, `$TMPDIR`, `mktemp`, `tempfile.*`,
   `os.tmpdir()`. When a tool insists on a temp path, point it at the project:
   `TMPDIR="$PWD/.temp" <cmd>`.
3. **In a git project, `.temp/` must be git-ignored.** Check first, add the rule
   if it is missing, then write:
   ```bash
   git check-ignore -q .temp/.probe \
     || printf '\n# Agent scratch files\n.temp/\n' >> .gitignore
   ```
   Never commit a `.temp/` directory.
4. **Name it so it reads as disposable:** `.temp/verify/`, `.temp/build.log`,
   `.temp/pr-body.md`.
5. **Clean up** what you created once the task is done. `.temp/` is scratch
   space, not a place to park something you will need later.

## Examples

```bash
mkdir -p .temp
npm run build > .temp/build.log 2>&1
curl -s https://example.com > .temp/page.html
```

If a project already defines its own temp-file rule (for example a repo-level
`.claude/rules/temp-files.md`), follow that one — it wins over this file.
