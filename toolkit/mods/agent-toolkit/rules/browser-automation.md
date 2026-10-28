# Shared browser for automation

Every agent on this machine drives the same real Google Chrome, in a visible
window you can click and type in. Do not download or launch your own.

## Use the shared instance

Node, with the helper:

```js
const { withPage, watchErrors } = require('/Users/jc/.agents/browser/browser.js');

await withPage(async ({ page }) => {
  const errors = watchErrors(page);
  await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
  console.log(errors);
});
```

Add `{ profile: true }` to keep cookies and logins between runs. Without it each
run gets a throwaway profile in a temp dir.

Python, via Playwright's own sync API:

```python
from playwright.sync_api import sync_playwright

# Real path, not the symlink. See "Why the path matters" below.
EXECUTABLE = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(
        "/Users/jc/.agents/browser/profile",
        executable_path=EXECUTABLE,
        headless=False,
        args=["--no-first-run", "--no-default-browser-check"],
    )
    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    page.goto("http://localhost:3000")
    ctx.close()
```

## Why the path matters

`~/.agents/browser/chrome` is a symlink to `/Applications/Google Chrome.app`,
but you must pass the **real** path to Playwright, which `browser.js` does with
`fs.realpathSync`.

Chrome finds its own framework relative to its executable. Launched through the
symlink, the process starts and then stalls during setup; the launch promise
never settles and throws nothing. It looks like a hang with no error. Use the
resolved path.

## Rules

- Never run `npx playwright install`. The npx cache already holds three stray
  `playwright-core` copies, and they are what pulled down a second Chromium:
  two full browsers sit under `~/Library/Caches/ms-playwright` at ~356M each.
- Always pass `--no-first-run --no-default-browser-check`. Without them real
  Chrome opens its welcome flow on a fresh profile and the launch stalls.
- Chrome is single-instance. Always launch with its own profile directory, or
  the launch is handed to the already-running instance and never resolves. That
  also keeps automation off your everyday profile, so a runaway script cannot
  reach your real sessions, cookies, or saved passwords.
- Playwright only accepts a custom profile directory through
  `launchPersistentContext`, so use that for throwaway profiles too.
- Session cookies do not survive a restart; that is correct browser behaviour.
  Cookies with an expiry do persist, so a WordPress login survives between runs.
- `playwright-core` is installed at `~/.agents/browser/node_modules`. Require it
  by absolute path instead of installing a copy per project. Nine copies exist
  on this machine, at versions from 1.57 to 1.64; the shared one is 1.64.1.
  The copy under `~/.cursor/extensions/` is vendored inside a Cursor extension
  and must not be removed. The rest predate this rule and are safe to prune on
  request.
- Report which checks passed and which could not run. Never describe UI work as
  verified on the strength of a screenshot alone, and do not present automation
  of someone's site as though it were manual.