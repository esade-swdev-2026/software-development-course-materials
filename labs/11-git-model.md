<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 11 — The Four Locations, by Hand

**Session 11 · Tuesday 27 October · Room 108**

You have been running `git add`, `git commit` and `git push` since session 3. This lab slows
that down until you can see each step move a change from one place to another.

Every git command you will meet moves something between **four locations**:

| Location | Where it lives | What is in it |
|---|---|---|
| **Working tree** | the files you see and edit | your current, unsaved-to-git version |
| **Staging area** | `.git/index` | what the *next* commit will contain |
| **Local repository** | `.git/objects` | every commit, on your laptop |
| **Remote** | GitHub | a copy of the repository other people can reach |

As you go, fill in this table. Copy it into a file of your own; you will need it in session 13.

| Command | Moves what | From | To |
|---|---|---|---|
| `git add` | | | |
| `git commit` | | | |
| `git push` | | | |
| `git restore --staged` | | | |
| `git restore` | | | |

This is a **throwaway** repository: do not do this lab inside your group's project.

**In class:** Lab 1, Exercises 1–6, and Exercise 7 if there is time. **At home, before Tuesday
3 November:** Exercise 7 if you did not reach it, and Lab 2. Session 13 starts from the
repository you push in Lab 2.

---

## What "done" looks like

1. A local repository with **six commits**, each with a message that says what it does.
2. A `.gitignore` that keeps a secret and some junk out of git.
3. One commit you made by staging **only part** of a file.
4. The same repository on your own GitHub account, pushed, with `git status` saying you are
   up to date.
5. The table above, filled in.

---

# Lab 1 — A local repository

## Exercise 1 — Start, and look at what git sees

```bash
git config --global user.name         # your name, as set in session 3
git config --global user.email        # the email GitHub knows
git config --global init.defaultBranch main

mkdir -p ~/lab11 && cd ~/lab11
git init
ls -a
git status
```

1. `git init` created one thing. What is it, and why does `ls` without `-a` not show it?
2. `git status` says `No commits yet`. Which of the four locations is empty?

Now create two files. Copy this block exactly — it writes a small Python script:

```bash
cat > budget.py <<'EOF'
MONTHLY_INCOME = 1800.00
RENT = 750.00
DAYS_IN_MONTH = 30


def remaining_after_rent(income: float, rent: float) -> float:
    return income - rent


def daily_allowance(remaining: float, days: int) -> float:
    return remaining / days


def main() -> None:
    remaining = remaining_after_rent(MONTHLY_INCOME, RENT)
    print(f"After rent: {remaining:.2f}")
    print(f"Per day:    {daily_allowance(remaining, DAYS_IN_MONTH):.2f}")


if __name__ == "__main__":
    main()
EOF
echo "Ideas: track groceries separately." > notes.txt
python3 budget.py
git status
```

3. Both files are *untracked*. Which location are they in? Which locations are they **not** in?

---

## Exercise 2 — Stage, then commit

```bash
git add budget.py
git status
git diff
git diff --staged
```

1. `git status` now lists `budget.py` under a new heading. Which one, and what does it mean?
2. `git diff` printed nothing and `git diff --staged` printed the whole file. Complete the
   sentences: `git diff` compares the ______ with the ______. `git diff --staged` compares
   the ______ with the ______.
3. `notes.txt` was not added. Is it in the staging area?

```bash
git commit -m "Add a script that works out a daily budget"
git status
git log
```

4. Which location did the commit move `budget.py` into? Is `budget.py` still in the working
   tree? Is it still in the staging area? *(Hint: the staging area is not emptied by a commit.
   It holds a full snapshot of what the next commit will contain, and right now that equals
   the last commit.)*

Fill in the `git add` and `git commit` rows of your table.

---

## Exercise 3 — One file, two versions at once

Open `budget.py` (`code .` or `nano budget.py`) and change `MONTHLY_INCOME` to `1850.00`.
Save it.

```bash
git diff
git add budget.py
git diff
git diff --staged
```

Now edit it **again**: change `DAYS_IN_MONTH` to `31`. Save.

```bash
git status
git diff
git diff --staged
```

1. `budget.py` now appears **twice** in `git status`. Explain why, using the locations.
2. If you ran `git commit` right now, would the commit contain `31` days? Why not?
3. Run `git add budget.py` and commit both changes with a message that says what changed.
   Then `git log --oneline`.

---

## Exercise 4 — Going back, one location at a time

Make a change you will regret: delete the whole `main()` function from `budget.py` and save.

```bash
git add budget.py
git status
```

Take it out of the staging area, but keep it in your file:

```bash
git restore --staged budget.py
git status
git diff --staged
git diff
```

1. Where is your change now? Where is it **not**?

Now throw it away completely:

```bash
git restore budget.py
git status
python3 budget.py
```

2. Where did the restored version of `budget.py` come from?
3. `git restore` is one of the very few git commands that destroys work. In general, why can
   git not bring back a change that only ever existed in the working tree, when it can bring
   back almost anything that was committed?

Fill in the two `restore` rows of your table.

---

## Exercise 5 — Keep things out: `.gitignore`

A real project accumulates files that must never be committed. Create three:

```bash
mkdir -p __pycache__ data
touch __pycache__/budget.cpython-313.pyc
echo "BANK_API_KEY=sk-not-a-real-key" > .env
echo "2025-10-01,rent,780.00" > data/october.csv
git status
```

Write a `.gitignore`:

```bash
cat > .gitignore <<'EOF'
__pycache__/
.env
data/
EOF
git status
```

1. Which files disappeared from `git status`, and which new one appeared?
2. Commit `.gitignore` on its own, with a message that says *why* it exists.
3. Suppose `.env` had been committed **last week**, before `.gitignore` existed. Would adding
   it to `.gitignore` today remove it from the repository? *(Try: `git ls-files` lists what git
   is tracking.)*

---

## Exercise 6 — One messy change, two clean commits

You come back from lunch and make two unrelated changes in the same file. Change line 2 and
add a constant under `DAYS_IN_MONTH`:

```python
RENT = 780.00
DAYS_IN_MONTH = 31
SAVINGS_RATE = 0.10
```

and add one line at the end of `main()`, under the `Per day` line:

```python
    print(f"Save:       {remaining * SAVINGS_RATE:.2f}")
```

Check it runs (`python3 budget.py`). These are **two** changes: the rent went up (a fact
about the world), and the script now shows savings (a new feature). They belong in two commits,
so that either can be found, understood or undone on its own.

```bash
git add -p budget.py
```

Git shows the changes one *hunk* at a time and asks
`(1/2) Stage this hunk [y,n,q,a,d,j,J,g,/,s,e,p,?]?`. You need five of those keys:

| Key | Means |
|---|---|
| `y` | stage this hunk |
| `n` | not this one |
| `s` | split it into smaller hunks (when two changes sit close together) |
| `q` | stop |
| `?` | help |

1. The first hunk contains **both** the rent line and the new constant. Press `s` to split it,
   then `y` for the rent and `n` for everything else.
2. Check what you staged, then commit it:

   ```bash
   git diff --staged
   git commit -m "Update the rent to the new contract's 780.00"
   ```

3. Stage and commit the rest with a message of your own.
4. `git log --oneline`. You should have **five** commits.

> **In VS Code instead:** open the *Source Control* panel, click `budget.py` to see the diff,
> select the lines you want, right-click, **Stage Selected Ranges**. It does the same thing as
> `git add -p`.

---

## Exercise 7 — Messages that still make sense in November

*In class if there is time; otherwise at home.*

Your log is a list of messages that strangers (and you, in a month) will read with no other
context. The course's convention, and the demo project's: **a capitalised verb in the
imperative, saying what the commit does** — `Add`, `Fix`, `Remove`, `Update`, `Rename`.
If the *why* is not obvious, add a blank line and a body.

Rewrite each of these as a message a teammate could act on:

1. `update`
2. `fixed stuff`
3. `changes to budget.py`
4. `asdfasdf`
5. `Final version (really)`

Then read your own `git log --oneline` from this lab. Would every subject still make sense if
you read it in November?

---

# Lab 2 — The fourth location

*At home, before Tuesday 3 November. Session 13 starts from this repository.*

## Exercise 8 — Put it on GitHub

On github.com, create a **new, empty** repository on *your own* account, called `lab11-git`.
**Do not** tick *Add a README*, *.gitignore* or *licence*: you already have a history, and
GitHub would start a different one.

Copy the SSH address it shows you (`git@github.com:<you>/lab11-git.git`), then:

```bash
git remote add origin git@github.com:<you>/lab11-git.git
git remote -v
git push -u origin main
git status
```

1. `git remote add` copied nothing anywhere. What did it do?
2. After the push, `git status` says `Your branch is up to date with 'origin/main'`.
   Which two locations is it comparing?
3. Refresh the GitHub page. Is `.env` there? Is `notes.txt`? Why or why not?

## Exercise 9 — Ahead of the remote

Add `notes.txt` and commit it. Then:

```bash
git status
git log --oneline --all
```

1. `git status` now says `ahead of 'origin/main' by 1 commit`. Which location has the
   commit and which does not?
2. In the log, `main` and `origin/main` point at different commits. What is `origin/main`?
   *(Session 12 answers this properly.)*
3. `git push`, then `git status` again. Fill in the `git push` row of your table.

You can delete `lab11-git` from GitHub afterwards (*Settings → Danger Zone*), or keep it.

---

## If something goes wrong

- **`Permission denied (publickey)`** on push: your SSH key is not on GitHub, or you used
  the HTTPS address. Run `ssh -T git@github.com`; it should greet you by username. See
  `labs/00-setup.md`, step 4.
- **`error: src refspec main does not match any`**: you have no commits yet, or your branch is
  called `master`. `git branch` shows its name; `git branch -m master main` renames it.
- **`Updates were rejected because the remote contains work that you do not have`**: you
  ticked *Add a README* when you created the GitHub repository. Delete the GitHub repository
  and create it again, empty.
- **`git add -p` shows no `s` option:** the hunk cannot be split further. Use `e` (edit) or
  stage with VS Code's *Stage Selected Ranges*.
- **A text editor opened and you do not know how to leave it:** you ran `git commit`
  without `-m`. In nano: `Ctrl+O`, Enter, `Ctrl+X`. In vim: `Esc`, then `:wq`, Enter.
