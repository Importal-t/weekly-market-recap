#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  Weekly Market Recap — GitHub Pages Setup
#  Run this ONCE from Terminal:
#    cd ~/Desktop/Claude_Projects/MarketRecaps && bash setup_github_pages.sh
# ─────────────────────────────────────────────────────────────

set -e

# Auto-load .env if token not already set
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -z "$GH_TOKEN" ] && [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
fi

if [ -z "$GH_TOKEN" ]; then
  echo "✗ GH_TOKEN not set."
  echo "  Create a token at https://github.com/settings/tokens (repo scope)"
  echo "  then save it:  echo 'GH_TOKEN=ghp_xxx' > ~/Desktop/Claude_Projects/MarketRecaps/.env"
  exit 1
fi
GH_USER="importal-t"
REPO="weekly-market-recap"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "📈 Weekly Market Recap — GitHub Pages Setup"
echo "─────────────────────────────────────────────"

# ── 1. Create the GitHub repo ──────────────────────────────
echo "① Creating GitHub repo '$REPO'..."
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GH_TOKEN" \
  -H "Content-Type: application/json" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO\",\"description\":\"US stock market weekly recap — auto-updated every Saturday\",\"private\":false,\"auto_init\":false}")

REPO_URL=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('html_url',''))" 2>/dev/null)

if [ -z "$REPO_URL" ]; then
  MSG=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
  if [[ "$MSG" == *"already exists"* ]]; then
    echo "   → Repo already exists, continuing..."
    REPO_URL="https://github.com/$GH_USER/$REPO"
  else
    echo "   ✗ Error creating repo: $MSG"
    echo "   Full response: $RESPONSE"
    exit 1
  fi
else
  echo "   ✓ Repo created: $REPO_URL"
fi

# ── 2. Set up git in this folder ───────────────────────────
echo "② Setting up git..."
cd "$DIR"

if [ ! -d ".git" ]; then
  git init
  git checkout -b main
fi

git config user.name "Market Recap Bot"
git config user.email "$GH_USER@users.noreply.github.com"

# Set remote (update if already exists)
git remote remove origin 2>/dev/null || true
git remote add origin "https://$GH_TOKEN@github.com/$GH_USER/$REPO.git"

# ── 3. Create index.html (redirects to latest recap) ───────
echo "③ Creating index.html..."
LATEST=$(ls -t us_market_weekly_recap_*.html 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then
  LATEST="us_market_weekly_recap_june20_2026.html"
fi

cat > index.html << HTMLEOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0; url=./$LATEST">
  <title>US Market Weekly Recap</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #f8fafc; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .msg { text-align: center; color: #64748b; }
    a { color: #2563eb; }
  </style>
</head>
<body>
  <div class="msg">
    <div style="font-size:32px;margin-bottom:12px">📈</div>
    <p>Redirecting to <a href="./$LATEST">latest recap</a>…</p>
  </div>
</body>
</html>
HTMLEOF

echo "   ✓ index.html → $LATEST"

# ── 4. Commit and push ─────────────────────────────────────
echo "④ Committing and pushing files..."
git add -A
git diff --cached --quiet && echo "   → Nothing new to commit" || git commit -m "📈 Market recap: $(date +'%Y-%m-%d')"
git push -u origin main --force
echo "   ✓ Pushed to GitHub"

# ── 5. Enable GitHub Pages ─────────────────────────────────
echo "⑤ Enabling GitHub Pages..."
sleep 2
PAGES_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$GH_USER/$REPO/pages" \
  -d '{"source":{"branch":"main","path":"/"}}')

PAGES_URL=$(echo "$PAGES_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('html_url',''))" 2>/dev/null)

if [ -z "$PAGES_URL" ]; then
  # Pages might already be enabled
  PAGES_URL="https://$(echo "$GH_USER" | tr A-Z a-z).github.io/$REPO"
  echo "   → Pages may already be enabled (or takes a moment to activate)"
fi

echo ""
echo "─────────────────────────────────────────────"
echo "✅ All done!"
echo ""
echo "  🌐 Public URL:  https://$(echo "$GH_USER" | tr A-Z a-z).github.io/$REPO"
echo "  📁 Repo:        $REPO_URL"
echo ""
echo "  ⚠️  GitHub Pages can take 1–2 minutes to go live."
echo "  ⚠️  Revoke your token at github.com/settings/tokens"
echo "      and create a new one — the old one was in chat."
echo "─────────────────────────────────────────────"
echo ""

# ── Save the public URL for the scheduled task ─────────────
echo "https://$(echo "$GH_USER" | tr A-Z a-z).github.io/$REPO" > .github_pages_url
