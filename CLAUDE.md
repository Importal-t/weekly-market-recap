# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A static site that publishes a weekly US stock market recap (and occasional sector deep-dives) as standalone, self-contained HTML files via GitHub Pages. There is no build step, no package manager, and no test suite — each page is a single hand-authored `.html` file with inline `<style>` (no external CSS/JS dependencies).

- `index.html` — redirect stub pointing to the latest recap via `<meta http-equiv="refresh">`.
- `us_market_weekly_recap_<month><day>_<year>.html` — the weekly recap page. One new file per week; old ones are kept in the repo for history.
- `Industry deepdive/` (or similarly named loose files like `ai_ecosystem_deepdive.html`) — one-off deep-dive visualizations on a specific sector/theme.
- `push_to_github.sh` — run after generating a new recap. Updates `index.html` to point at the newest `us_market_weekly_recap_*.html`, commits, and pushes to `main`. Intended to be called by a Saturday scheduled task, but safe to run manually.
- `setup_github_pages.sh` — one-time setup script: creates the GitHub repo, initializes git, sets the remote, pushes, and enables GitHub Pages. Not needed for routine work.

## Auth / secrets

`GH_TOKEN` (a GitHub PAT with `repo` scope) is read from `.env` (gitignored) — never hardcode it in scripts or commit it. Both shell scripts auto-source `.env` if `GH_TOKEN` isn't already in the environment. Target repo is `Tianyiliao/weekly-market-recap`, published at `tianyiliao.github.io/weekly-market-recap`.

## Working conventions for new pages

When creating a new recap or deep-dive, match the style already established in existing pages:
- Self-contained single HTML file, system font stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", ...`), light background (`#f8fafc`), slate text colors (`#1e293b` / `#64748b` / `#0f172a`).
- `max-width` centered container, uppercase 11px letter-spaced `.section-title` headers, rounded badge/chip elements for metadata (dates, legend keys).
- Sector deep-dives define a CSS custom-property color palette (`--c0`...`--cN`) in `:root` for consistent category coloring across charts/legends.
- After adding a new weekly recap file, run `push_to_github.sh` to update the redirect and publish.

## Commands

- Publish latest recap: `bash push_to_github.sh`
- One-time GitHub Pages setup (already done; only needed if repo/Pages is reset): `bash setup_github_pages.sh`

There is no build, lint, or test tooling in this repo — pages are plain HTML/CSS viewed directly in a browser.
