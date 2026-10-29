<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 12 — Branches and Merging, on Your Project

**Session 12 · Friday 30 October · Room 108 · Checkpoint 3**

This lab runs on your **group's repository**, and the work counts: it is most of what
Checkpoint 3 asks for. Each of you takes one backlog item onto a branch, and each of you lands
it on `main` a **different way**. At the end, your group's graph shows all four ways a branch
can land, side by side, and you can read each one off it.

**CP3 is due Sunday 1 November, 23:59, at the tag `v0.6`.** The checklist is in
`grading/checkpoint-3.md` on Moodle.

---

## Three rules for today

1. **Never `git push --force`**, on any branch. Nothing in this lab needs it.
2. **If GitHub says a pull request has conflicts, stop.** Do not press *Resolve conflicts*.
   Leave the PR open: it becomes your live example in session 13, and CP3 is not due until
   Sunday.
3. **Member 1 goes first** (Exercise 4). Nobody presses a merge button on GitHub until member 1
   says "pushed".

---

## Exercise 1 — Bring your copy up to date, and read it

```bash
cd ~/code/<your-project>
git switch main
git pull
git log --oneline --graph --all
```

`git pull` brings down what your teammates pushed; session 13 takes it apart.

Find, in your own graph:

1. The commit `main` points at. What does `HEAD -> main` mean?
2. `origin/main`. Is it on the same commit as `main`? What would it mean if it were not?
3. Every `setup/<name>` branch from session 3. Are any of them merged into `main`?
4. Any merge commit (a line that splits into two). How many parents does it have?
   (`git cat-file -p <sha>` prints them.)

---

## Exercise 2 — Delete your setup branch

Your setup report from session 3 has been checked; its branch is no longer needed and
clutters every graph your group draws from now on.

```bash
git branch --list 'setup/*'                    # do you have it locally?
git branch -d setup/<your-github-username>     # delete the local label, if you have one
git push origin --delete setup/<your-github-username>
git fetch --prune                              # forget remote labels that are gone
git log --oneline --graph --all
```

1. If you had the branch locally, `git branch -d` refused with `not fully merged`. What is
   git protecting you from? Since you know the report was checked, delete it anyway with `-D`.
   (If you never had it locally, git says `not found`; skip to the `push` line.)
2. Two commands deleted two different things. Which deleted the label on your laptop, and
   which deleted the one on GitHub?
3. Your setup commit no longer appears in the graph. Has it been destroyed?
   *(Hint: what is a branch, according to today's slides?)*

---

## Exercise 3 — One backlog item, one branch

As a group, take **one item per person** from your backlog, chosen so that **no two of you
edit the same file**. A new module, a new test file, a README section and a new CLI command
in its own file are all good choices. Write down who has which item.

On your own laptop:

```bash
git switch main
git pull
git switch -c <short-descriptive-name>        # e.g. add-search-command, not branch1
```

Do the work in **at least two commits**, each with a message that says what it does (the rules
from session 11). Then run the checks and push the branch:

```bash
uv run ruff check . && uv run ruff format --check . && uv run mypy src tests && uv run pytest
git push -u origin <your-branch>
git log --oneline --graph --all
```

1. Where do `main`, your branch, and `HEAD` point now?
2. Has `main` moved? Why not?

---

## Exercise 4 — Land it, a different way each

Each member has a role. Agree on roles before anyone merges.

| Member | Lands their branch by | Where |
|---|---|---|
| **1** | **Fast-forward**, locally, then push | terminal |
| **2** | Pull request → **Create a merge commit** | GitHub |
| **3** | Pull request → **Squash and merge** | GitHub |
| **4** | Pull request → **Rebase and merge** | GitHub |
| 5 (groups of five) | **`--no-ff` merge**, locally, then push. **Goes last** | terminal |

Groups of three: skip member 4's role.

### Member 1 — fast-forward (do this first)

A fast-forward is only possible while `main` has not moved since you branched. That is why
you go first.

```bash
git switch main
git pull
git merge --ff-only <your-branch>
git push
```

Tell your group "pushed". If `git merge --ff-only` says `Not possible to fast-forward`,
someone landed something first. Do not force it: open a pull request and use *Create a merge
commit* instead, and tell me. A fast-forward that cannot happen is also a lesson.

### Members 2, 3 and 4 — through a pull request

1. On GitHub, open your repository. A yellow bar offers **Compare & pull request** for your
   branch; click it. (Or: *Pull requests → New pull request*, base `main`, compare your branch.)
2. Give it a title that says what it does. Click **Create pull request**.
3. Wait for the check to go green.
4. Click the **arrow next to the green merge button** and choose your method: *Create a merge
   commit*, *Squash and merge*, or *Rebase and merge*. Confirm.
5. Click **Delete branch** when GitHub offers it.

If the merge button is grey and says *This branch has conflicts that must be resolved*: stop
(rule 2).

### Member 5 — `--no-ff`, locally (last)

```bash
git switch main
git pull
git merge --no-ff --no-edit <your-branch>
git push
```

If the push is rejected with `fetch first`, someone landed something between your `pull` and
your `push`. Run `git pull` again, then `git push`.

---

## Exercise 5 — Read the four shapes

When everyone has landed, **every member** runs:

```bash
git switch main
git pull
git fetch --prune
git log --oneline --graph --all
```

Find each member's work in the graph and answer.

1. **Fast-forward.** Can you tell from `main`'s history that member 1 ever used a branch?
2. **Merge commit.** Find member 2's merge commit. What are its two parents? Run
   `git cat-file -p <sha>` to check.
3. **Squash.** How many commits did member 3 make on their branch? How many did `main` get?
   Where are the original commits now?
4. **Rebase.** Member 4's commits are on `main` with the same messages as on their branch.
   Compare the SHAs:

   ```bash
   git log --oneline -n 2 main
   git log --oneline -n 2 origin/<member-4-branch>   # if member 4 has not deleted it yet
   ```

   Why are the SHAs different, when the changes are the same?
5. Squash and rebase-and-merge both **added** commits to `main`. Did either of them change a
   commit that was already on `main` before you started? How would you check?
6. Member 3 tries `git branch -d <their-branch>` and git refuses: `not fully merged`. The work
   *is* on `main`. Why does git think otherwise?

---

## Exercise 6 — Tag the checkpoint (when CP3 is ready)

CP3 needs at least three branches landed, by at least three of you. When that is true and
`main` is green, **one** member tags it:

```bash
git switch main
git pull
git tag -a v0.6 -m "Checkpoint 3: branches and merging"
git push origin v0.6
git ls-remote --tags origin v0.6        # proves the tag reached GitHub
```

`git push` on its own **does not send tags**. A tag that only exists on your laptop does not
exist for the marker.

---

## If something goes wrong

- **`fatal: Not possible to fast-forward, aborting.`**: `main` moved since your branch
  started. See member 1's instructions.
- **`! [rejected] main -> main (fetch first)`**: someone pushed first. `git pull`, then
  `git push`. (If `git pull` asks how to reconcile divergent branches, run
  `git config --global pull.rebase false` once, then `git pull` again. Session 13 explains.)
- **An editor opens during `git merge`**: you left out `--no-edit`. Save and close it
  (nano: `Ctrl+O`, Enter, `Ctrl+X`; vim: `Esc`, `:wq`, Enter); the default message is fine.
- **`error: The branch '...' is not fully merged`**: see Exercise 5, question 6. If the pull
  request shows *Merged*, `git branch -D` is safe.
- **There is no *Squash and merge* or *Rebase and merge* in the menu**: tell me; a repository
  setting controls it.
- **`git push origin --delete` says `remote ref does not exist`**: the branch is already gone
  from GitHub. Run `git fetch --prune` and carry on.
