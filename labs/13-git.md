<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 13 — Conflicts, Remotes and Undo

**Session 13 · Tuesday 3 November · Room 108**

This lab runs on **your own `lab11-git` repository** from session 11, not on your group's
project. Here you will cause a conflict on purpose, make GitHub refuse a push, and throw
commits away, so do it somewhere nothing matters.

You will play two people: **you**, on your laptop, and **a teammate**, who is also you, editing
files directly on github.com.

---

## Two rules for today

1. **Never `git push --force`**, not even here. Nothing in this lab needs it, and the habit is
   the point.
2. When git prints a `hint:`, **read it before doing anything else**. Most of today's answers
   are in those hints.

---

## What "done" looks like

1. A conflict you resolved yourself, and a second one you aborted.
2. A push GitHub rejected, then accepted after you fetched and merged.
3. A commit you threw away with `reset --hard` and got back with `reflog`.
4. A pushed commit undone with `revert`.

---

## Exercise 0 — Ready? (5 minutes)

```bash
cd ~/lab11
git status
git remote -v
git log --oneline -3
```

**If `git remote -v` prints nothing**, you have not done session 11's Lab 2. Do it now: on
github.com, create a **new, empty** repository called `lab11-git` (no README, no licence),
then:

```bash
git remote add origin git@github.com:<you>/lab11-git.git
git push -u origin main
```

**If `~/lab11` does not exist at all**, make a fresh one in two minutes:

```bash
mkdir -p ~/lab11 && cd ~/lab11 && git init -b main
printf 'MONTHLY_INCOME = 1800.00\nRENT = 750.00\nDAYS_IN_MONTH = 30\n' > budget.py
echo "Ideas: track groceries separately." > notes.txt
git add . && git commit -m "Add a budget script and some notes"
```

and then create the GitHub repository and push it as above.

**Is your work credited to you?** On GitHub, open your repository's commit list. Next to each
commit there should be **your avatar and username**. If there is a grey silhouette instead,
the email git is using is not one GitHub knows:

```bash
git config --global user.email
```

Add that address on github.com → *Settings → Emails*, or change it to one already there with
`git config --global user.email <address>`. This matters for your project: commits under an
unknown email do not count as yours.

---

## Exercise 1 — A conflict of your own (12 minutes)

Two branches change **the same line** of `budget.py`, differently.

```bash
git switch main
git switch -c rent-rise
```

Change the `RENT` line to `RENT = 800.00` (whatever it says now), save, then:

```bash
git commit -am "Raise rent to 800 from January"
git switch main
git switch -c shared-flat
```

Change the same `RENT` line to `RENT = 600.00`, save, then:

```bash
git commit -am "Lower rent to 600 after moving to a shared flat"
git switch main
git merge rent-rise
git merge shared-flat
```

1. The first merge did not conflict. What kind of merge was it, and why could it be that kind?
2. The second merge conflicts. Using the three-commit model from the slides, which commit is
   the **base**, which is **ours**, and which is **theirs**?
3. Run `git status`. Which heading lists `budget.py`?
4. Open `budget.py`. Copy the conflict, markers included, into your notes. Which value is
   between `<<<<<<< HEAD` and `=======`? Why that one?

Now **resolve it** with the seven steps. Decide that the shared flat wins, so rent is 600:

- delete the three marker lines and the line you do not want
- `python3 budget.py` (does it still run?)
- `git add budget.py`
- `git commit`: an editor opens with `Merge branch 'shared-flat'`. Add a line saying what you
  decided and why, save, and close it (nano: `Ctrl+O`, Enter, `Ctrl+X`)

```bash
git log --oneline --graph --all
```

5. How many parents does the merge commit have? Which two commits are they?

**Now the panic button.** Make one more conflict and back out of it:

```bash
git switch -c rent-up-again shared-flat~1
```

Change the `RENT` line to `RENT = 900.00`, save, then:

```bash
git commit -am "Raise rent to 900"
git switch main
git merge rent-up-again
git merge --abort
git status
git log --oneline -1
```

6. After `--abort`, is there any trace of the merge you started? What is still there?

---

## Exercise 2 — Fetch is not pull (13 minutes)

**Your teammate pushes.** On github.com, open `lab11-git` → `notes.txt` → the pencil icon.
Add a line `Ideas: compare phone contracts.` and press *Commit changes…* (commit directly to
`main`).

Back on your laptop, **do not pull yet**:

```bash
git push                          # send Exercise 1's work first, if you have not
git status
git fetch
git status
git log --oneline --all -5
```

1. Before `git fetch`, `git status` said you were up to date. Was that true? What was it
   comparing?
2. After `git fetch`, what does `git status` say? Has `notes.txt` on your laptop changed?
3. In the log, where is `main` and where is `origin/main`?

```bash
git log --oneline main..origin/main
git diff main origin/main
git merge origin/main
git status
```

4. Was that merge a fast-forward or a merge commit? Why?
5. You just did, in three steps, what `git pull` does in one. Which step does `pull` skip?

**Now both of you work at once.** On github.com, edit `budget.py`: change the
`DAYS_IN_MONTH` line to `DAYS_IN_MONTH = 28`, and commit. On your laptop, **without fetching**,
edit `notes.txt` (add any line), then:

```bash
git commit -am "Add a note about the gym"
git push
```

6. The push was rejected. Copy the first `hint:` line. What is git telling you?
7. `git fetch`, then `git status`. What does *diverged* mean here: how many commits does each
   side have that the other does not?

```bash
git merge origin/main             # an editor may open for the merge message: save and close
git push
git log --oneline --graph -6
```

8. Did this merge conflict? Why not, when Exercise 1's did?

**The same thing, with a conflict.** On github.com, change `MONTHLY_INCOME` to `1900.00`. On
your laptop, without fetching, change it to `2000.00`, commit, and `git push`. Rejected again:
fetch, merge, resolve with the seven steps (keep `2000.00`), push.

---

## Exercise 3 — Undo, at the right level (15 minutes)

Work on a throwaway branch, so `main` stays tidy:

```bash
git switch -c undo-practice
```

### Amend: fix the commit you just made

```bash
echo "Ideas: cancel the magazine." >> notes.txt
git commit -am "Add a note abuot the magazine"
git log --oneline -1
git commit --amend -m "Add a note about the magazine"
git log --oneline -1
```

1. Compare the two SHAs. Why did amending a message change the SHA?

### Reset: move the label back

Make three commits quickly:

```bash
for n in 1 2 3; do echo "line $n" >> notes.txt; git commit -qam "Add line $n"; done
git log --oneline -4
```

Now undo them three different ways, checking after each:

```bash
git reset --soft HEAD~1
git status
git log --oneline -3
```

2. Where did the change from "Add line 3" go?

```bash
git commit -m "Add line 3 again"
git reset --mixed HEAD~1          # --mixed is the default
git status
```

3. Where is the change now? What is the difference from `--soft`?

```bash
git commit -am "Add line 3 once more"
git reset --hard HEAD~1
git status
cat notes.txt
```

4. Is `line 3` anywhere: in the file, the staging area, or the log?

### Reflog: get it back

```bash
git reflog -6
```

5. Find the line `commit: Add line 3 once more`. Its SHA is the commit you just "deleted". Get
   it back:

```bash
git reset --hard <that-sha>
cat notes.txt
```

6. The commit came back. Why could `reflog` find it when `git log` could not?

### Revert: undo something already pushed

```bash
git push -u origin undo-practice
git revert --no-edit HEAD
git log --oneline -3
cat notes.txt
git push
```

7. `git log` now has **more** commits, not fewer. Why is that the safe way to undo a commit
   other people may have pulled?
8. Why would `git reset --hard HEAD~1` followed by `git push` have failed here? What would
   it have taken to force it, and who would that hurt on a real team?

---

## Exercise 4 (bonus) — Your group's conflicting pull request

If your group's repository has a pull request from session 12 that GitHub still marks *This
branch has conflicts*, its author resolves it now, on their own laptop:

```bash
cd ~/code/<your-project>
git switch main && git pull
git switch <the-pr-branch>
git merge main
# seven steps; run the checks
git push
```

Refresh the pull request. The conflict warning is gone and CI runs again. **Do not merge it
yet**: on Friday another group reviews your open PRs first.

---

## For Friday

Friday is **Practice 3**, and **Checkpoint 4** is about code review. Before **Friday 10:45**,
your group has **two pull requests open** on its repository:

- one backlog item each, **under ~200 changed lines**
- the description filled in from the PR template
- CI green
- **not merged**: another group reviews them in class

The checklist is `grading/checkpoint-4.md` on Moodle.

---

## If something goes wrong

- **An editor opened and you do not know how to leave it.** In nano: `Ctrl+O`, Enter,
  `Ctrl+X`. In vim: `Esc`, then `:wq`, Enter.
- **`git pull` says `You have divergent branches and need to specify how to reconcile them`.**
  Run `git config --global pull.rebase false` once, then pull again.
- **`error: Your local changes to the following files would be overwritten by merge`.** You
  have uncommitted edits. Commit them, or `git restore <file>` to drop them, then merge.
- **`git switch` refuses, mentioning local changes.** Same cause and the same fix.
- **`fatal: You have not concluded your merge (MERGE_HEAD exists)`.** You are still in the
  middle of a merge. Finish it (`git add`, `git commit`) or `git merge --abort`.
- **The commit list on GitHub shows a grey silhouette.** See Exercise 0, *Is your work
  credited to you?*
- **You ran `git reset --hard` and lost work.** If it was committed: `git reflog`. If it was
  never committed, it is gone. That is the one undo there is no undo for.
