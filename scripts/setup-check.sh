#!/usr/bin/env bash
#
# setup-check.sh — verify the developer environment for
# Software Development for Business (ESADE).
#
# TARGET REPO: software-development-course-materials (PUBLIC).
#
# It checks that each tool *works*, never that it was installed a particular
# way — the syllabus lets you choose your own tools, and this script has to
# stay honest about that. Every line reports pass or fail plus a one-line fix.
#
# It writes setup-report.md in the current directory AND prints the same
# report to the screen. Push setup-report.md to your group repository even if
# lines are red: a red line is a ticket, not a failure. The push is what
# triggers the CI workflow that grades your project all term — that is the
# point of the exercise.
#
# Exit code: 0 if everything needed to START the course passes (uv, Python
# 3.13, PyPI reachable, git identity, GitHub SSH). Non-zero otherwise. Docker
# is checked too but is not needed until session 16, so a Docker-only failure
# still exits 0.
#
# PORTABILITY: this must run on macOS's stock /bin/bash, which is 3.2.57 and
# always will be. So: no mapfile, no associative arrays, no ${var^^}, no
# `timeout` (BSD has none), no GNU-only flags to sed/date/grep. Every row is
# recorded unconditionally, because bash 3.2 under `set -u` errors on
# "${arr[@]}" when the array is empty.

set -u

REPORT="setup-report.md"
now="$(date -u '+%Y-%m-%d %H:%M UTC')"
os="$(uname -s) $(uname -m)"
shell_version="bash ${BASH_VERSION:-unknown}"

# Each check appends one "| item | status | fix |" row to these arrays.
now_rows=()
later_rows=()
now_failures=0
later_failures=0
gh_user=""

pass_row() {
  printf '| %s | pass | %s |\n' "$1" "${3:-—}"
}
# A literal | in a fix hint splits the markdown table cell on GitHub, and
# backticks do not protect it. Escape every pipe in a hint as \\|.
fail_row() {
  printf '| %s | **FAIL** | %s |\n' "$1" "$2"
}

record_now() {
  # $1 label, $2 fix hint, $3 exit status of the test
  if [ "$3" -eq 0 ]; then
    now_rows+=("$(pass_row "$1" "" "")")
  else
    now_rows+=("$(fail_row "$1" "$2")")
    now_failures=$((now_failures + 1))
  fi
}
record_later() {
  if [ "$3" -eq 0 ]; then
    later_rows+=("$(pass_row "$1" "" "")")
  else
    later_rows+=("$(fail_row "$1" "$2")")
    later_failures=$((later_failures + 1))
  fi
}

# --- needed to start the course -------------------------------------------

# uv
if command -v uv >/dev/null 2>&1; then
  uv_version="$(uv --version 2>/dev/null)"
  record_now "uv installed ($uv_version)" "" 0
else
  record_now "uv installed" "install uv: \`curl -LsSf https://astral.sh/uv/install.sh \\| sh\` then restart the shell" 1
fi

# Python 3.13 discoverable by uv
if command -v uv >/dev/null 2>&1 && uv python find 3.13 >/dev/null 2>&1; then
  record_now "Python 3.13 available to uv" "" 0
else
  record_now "Python 3.13 available to uv" "\`uv python install 3.13\`" 1
fi

# PyPI reachable. Nothing else here proves the network will let uv install a
# package — a TLS-intercepting proxy or an always-on VPN passes every check
# above and then breaks `uv sync` in session 4. So actually fetch something.
# UV_HTTP_TIMEOUT rather than timeout(1), which macOS does not ship.
if command -v uv >/dev/null 2>&1 \
  && UV_HTTP_TIMEOUT=30 uv run --no-project --quiet --with packaging \
       python -c "import packaging" >/dev/null 2>&1; then
  record_now "PyPI reachable (uv can install a package)" "" 0
else
  record_now "PyPI reachable (uv can install a package)" "network is blocking PyPI — disconnect the VPN, or see troubleshooting §5 (corporate proxy / TLS interception)" 1
fi

# git present
if command -v git >/dev/null 2>&1; then
  record_now "git installed ($(git --version | awk '{print $3}'))" "" 0
else
  record_now "git installed" "install git (WSL2 Ubuntu: \`sudo apt install git\`; macOS: \`xcode-select --install\`)" 1
fi

# git identity
git_name="$(git config --get user.name 2>/dev/null || true)"
git_email="$(git config --get user.email 2>/dev/null || true)"
if [ -n "$git_name" ] && [ -n "$git_email" ]; then
  record_now "git identity set ($git_name <$git_email>)" "" 0
else
  record_now "git identity set" "\`git config --global user.name \"Your Name\"\` and \`git config --global user.email \"you@example.com\"\`" 1
fi

# GitHub SSH auth. `ssh -T git@github.com` exits 1 on success with a greeting,
# 255 on real failure — so match the greeting, not the exit code.
ssh_out="$(ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 || true)"
if printf '%s' "$ssh_out" | grep -q "successfully authenticated"; then
  gh_user="$(printf '%s' "$ssh_out" | sed -n 's/^Hi \([^!]*\)!.*/\1/p')"
  record_now "GitHub SSH authenticates (as $gh_user)" "" 0
else
  record_now "GitHub SSH authenticates" "add an SSH key to GitHub: \`ssh-keygen -t ed25519 -C you@example.com\`, then paste ~/.ssh/id_ed25519.pub at github.com/settings/keys" 1
fi

# --- needed later (session 16, Containerize Your Project) -----------------

# `docker info` and not `docker run hello-world`: a room of sixty laptops behind
# one campus NAT hits Docker Hub's anonymous pull limit, which would paint red
# lines that say nothing about the student's machine. This proves the daemon is
# installed and answering, which is what we need to know today.
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  record_later "Docker daemon reachable" "" 0
else
  record_later "Docker daemon reachable" "install Docker Desktop with the WSL2 backend and start it (not needed until session 16)" 1
fi

# --- assemble the report --------------------------------------------------

{
  echo "# Setup report"
  echo
  echo "- Generated: $now"
  echo "- Machine: $os"
  echo "- Shell: $shell_version"
  echo
  echo "## Needed to start the course"
  echo
  echo "| Check | Status | Fix |"
  echo "|---|---|---|"
  for row in "${now_rows[@]}"; do echo "$row"; done
  echo
  echo "## Needed by session 16 (containers)"
  echo
  echo "| Check | Status | Fix |"
  echo "|---|---|---|"
  for row in "${later_rows[@]}"; do echo "$row"; done
  echo
  if [ "$now_failures" -eq 0 ] && [ "$later_failures" -eq 0 ]; then
    echo "**All checks pass.**"
  elif [ "$now_failures" -eq 0 ]; then
    echo "**Ready to start.** The container checks are red, but those are not needed until session 16."
  else
    echo "**$now_failures check(s) still needed to start the course are red.** Push this file anyway — it is a ticket. Bring it to the lab or to office hours."
  fi
} | tee "$REPORT"

# The exact next commands, with the student's own GitHub login already filled
# in. Placeholder substitution (<your-username>, <your-group>) is the single
# largest source of typos in the room, so do it for them.
echo
echo "Wrote $REPORT in $(pwd)"
echo
if [ -n "$gh_user" ]; then
  echo "Next — push it to your group repository, on your own branch:"
  echo
  echo "  cd ~"
  echo "  git clone git@github.com:esade-swdev-2026/<your-group>.git"
  echo "  cd <your-group>"
  echo "  git switch -c setup/$gh_user"
  echo "  mkdir -p setup-reports"
  echo "  cp $(pwd)/$REPORT setup-reports/$gh_user.md"
  echo "  git add setup-reports/"
  echo "  git commit -m \"add setup report\""
  echo "  git push -u origin setup/$gh_user"
  echo
  echo "Replace <your-group> with your group's repository name. Everything else"
  echo "above is already filled in for you."
else
  echo "Next: fix the GitHub SSH line above, then re-run this script — it will"
  echo "print the exact commands to push this report, with your username in them."
fi

[ "$now_failures" -eq 0 ]
