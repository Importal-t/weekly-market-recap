#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  Weekly Market Recap — GitHub Push
#  Called automatically by the Saturday scheduled task after
#  generating the new HTML file. Safe to run manually too.
# ─────────────────────────────────────────────────────────────

if [ -z "$GH_TOKEN" ]; then
  echo "✗ GH_TOKEN env var not set. Run 'source .env' (or export GH_TOKEN=ghp_xxx) first."
  exit 1
fi
GH_USER="Tianyiliao"
REPO="weekly-market-recap"
DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DIR"

# Update index.html to point to the latest recap
LATEST=$(ls -t us_market_weekly_recap_*.html 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
  sed -i.bak "s|url=\./us_market_weekly_recap_[^\"]*|url=./$LATEST|g" index.html
  rm -f index.html.bak
fi

# Ensure remote is set with token
git remote remove origin 2>/dev/null || true
git remote add origin "https://$GH_TOKEN@github.com/$GH_USER/$REPO.git"

git add -A
git diff --cached --quiet && echo "Nothing new to push" && exit 0

git commit -m "📈 Market recap: $(date +'%Y-%m-%d')"
git push origin main

echo "✓ Pushed to https://$(echo "$GH_USER" | tr A-Z a-z).github.io/$REPO"
