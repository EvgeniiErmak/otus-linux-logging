#!/usr/bin/env bash
# Создание репозитория на GitHub (если его нет) и push.
# Использование: ./scripts/create_repo.sh "сообщение коммита"
set -euo pipefail

GH_USER="EvgeniiErmak"
GH_EMAIL="djermak3000@mail.ru"
REPO="otus-linux-logging"
MSG="${1:-Update}"

cd "$(dirname "$0")/.."

read -rsp "GitHub Personal access token (classic): " GH_TOKEN; echo
export GIT_TERMINAL_PROMPT=0
API="https://api.github.com"
AUTH="Authorization: token ${GH_TOKEN}"
PUSH_URL="https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${REPO}.git"

code=$(curl -s -o /dev/null -w '%{http_code}' -H "$AUTH" "$API/repos/$GH_USER/$REPO")
if [ "$code" = "404" ]; then
  curl -sf -H "$AUTH" -H "Accept: application/vnd.github+json" \
    -d "{\"name\":\"$REPO\",\"description\":\"OTUS Linux Professional: centralized logging (rsyslog, auditd, ELK)\",\"private\":false}" \
    "$API/user/repos" > /dev/null
  echo "Репозиторий $REPO создан"
elif [ "$code" = "200" ]; then
  echo "Репозиторий $REPO уже существует"
else
  echo "Ошибка GitHub API (HTTP $code). Проверьте токен (scope: repo)"; exit 1
fi

[ -d .git ] || git init -q -b main
git config user.name  "$GH_USER"
git config user.email "$GH_EMAIL"
git remote get-url origin >/dev/null 2>&1 \
  || git remote add origin "https://github.com/${GH_USER}/${REPO}.git"

git add -A
git commit -q -m "$MSG" || echo "Нет изменений для коммита"

# Забираем изменения, сделанные через браузер (скриншоты)
git pull -q --rebase "$PUSH_URL" main 2>/dev/null || true
git push -q "$PUSH_URL" main
git fetch -q origin && git branch -q --set-upstream-to=origin/main main 2>/dev/null || true

echo "Готово: https://github.com/${GH_USER}/${REPO}"
