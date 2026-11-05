<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 14 — Code Review, for Real

**Session 14 · Friday 6 November · Room 108 · Practice 3 · Checkpoint 4**

Two parts. First you review four prepared pull requests, each with one planted problem, to
calibrate what a useful review comment looks like. Then you review your **partner group's**
real pull requests, they review yours, and the reviewed PRs are squash-merged.

**Checkpoint 4 is due Sunday 8 November, 23:59.** The checklist is `grading/checkpoint-4.md`;
what counts as a substantive comment is in `grading/review-checklist.md`. Both are on Moodle.

---

## Three rules for today

1. **Never force-push** a branch someone is reviewing. Fix things with new commits.
2. **Comments are about the code**, never the person.
3. **Nobody presses *Squash and merge* before 13:05.** We do it together.

---

## Part 1 — Calibration (11:30–12:15)

Open **github.com/esade-swdev-2026/review-practice** → *Pull requests*. Your group's PR
number is on the slide:

| PR | Groups |
|---|---|
| #1 | flashcard-trainer · habit-tracker · parking-lot · text-adventure |
| #2 | fortune-cookie · library-manager · public-transport-fares · vending-machine |
| #3 | gradebook · meal-planner · ship-port-management |
| #4 | gym-workout-logger · movie-watchlist · task-manager |

**Each of you, on your own (15 minutes):**

1. Read the PR's description. What is it supposed to do?
2. Open **Files changed**. Read every line, tests included. Go through
   `grading/review-checklist.md`, items 4–9.
3. Hover over a line, click the blue **+**, write your comment, and press **Start a review**
   (not *Add single comment*). Your comments stay **pending**: nobody sees them yet.
4. Add as many as you like. **At least one** each.
5. **Do not submit** until the signal.

Every PR is green on CI. Every PR has **at least one thing a reviewer must stop**.

**On the signal:** *Review changes* (top right) → **Request changes** → *Submit review*.

Then we go through the four PRs together. For each one, write down:

1. What was the planted problem?
2. Would any of `ruff`, `mypy` or `pytest` have caught it?
3. One comment you read that you would want to receive, and why.

---

## Part 2 — Peer review (12:15–13:05)

Sit with your partner group:

| | | |
|---|---|---|
| flashcard-trainer | ⇄ | parking-lot |
| fortune-cookie | ⇄ | ship-port-management |
| gradebook | ⇄ | vending-machine |
| gym-workout-logger | ⇄ | library-manager |
| habit-tracker | ⇄ | public-transport-fares |
| meal-planner | ⇄ | text-adventure |
| movie-watchlist | ⇄ | task-manager |

Your group should have **two open pull requests** from the homework. If it has none, open one
now: one backlog item, small, with the template filled in. You have 10 minutes.

### As reviewers, on the partner group's repository (until 12:35)

The partner's repository is public: you can comment without being a collaborator.

1. Split up: each member takes one of the partner's PRs, or one part of it.
2. Go through `grading/review-checklist.md` from the top.
3. Comment with **Start a review**, then submit as **Request changes** (something must change)
   or **Comment** (questions and suggestions only).
4. Between you, **at least four substantive comments** across the partner's PRs. That is
   Checkpoint 4, item 2. Specific (on a line), actionable (what to change), kind.

### As authors, on your own repository (until 12:55)

1. Read every comment on your PRs. **Answer every one**: "Done in `<sha>`", "Changed", or why
   not.
2. **Act on at least one**: make the change on the same branch, then:

   ```bash
   git switch <your-pr-branch>
   git pull                                   # teammates may have pushed to it
   # ... the change; run the checks ...
   git commit -am "Rename process to overdue_tasks"    # what it does, as always
   git push
   ```

   Reply to the comment with the commit's short SHA. That is Checkpoint 4, item 3.
3. Wait for CI to go green on the new commit.

### As reviewers again (until 13:05)

Look at the replies on the partner's PRs. If your comment was dealt with, mark the
conversation **resolved**. If the PR is ready, submit a review with **Approve**.

---

## Part 3 — Squash and merge (13:05–13:15)

On each of your reviewed PRs:

1. **Squash and merge**.
2. Read the commit message GitHub proposes. The title is the PR title plus `(#n)`: if it does
   not say what the change does, fix it now. It is what `main` will say forever.
3. **Confirm squash and merge**. GitHub deletes the branch.

Then, every member:

```bash
git switch main
git pull
git log --oneline -5
git branch -D <the-merged-branch>            # -D: squash left its commits behind (session 12)
git fetch --prune
```

Each reviewed PR is **one commit** on `main`.

A PR not ready by 13:15 is not lost: keep going until **Sunday 23:59**, same rules, same
partner.

---

## Checkpoint 4 — check it yourself before Sunday

1. *Pull requests → Closed* on your repository: at least **two** merged, each with a review or
   comments from a partner-group member.
2. On the partner's repository: count your group's substantive comments. At least **four**.
3. One comment with a reply pointing at the commit that answered it.

---

## If something goes wrong

- **`git push` to `main` is rejected: `protected branch` / `Changes must be made through a pull
  request`.** That is the new rule since Thursday night. Push a branch and open a PR.
- **The merge button is grey: `Required status check "check" is expected` or failing.** CI has
  not finished, or it is red. Click *Details*, fix on the branch, push.
- **There is no *Squash and merge*, only a grey button saying the branch is out of date or has
  conflicts.** Merge `main` into your branch on your laptop (session 13, Exercise 4), resolve,
  push.
- **You cannot see the + on a line.** You are on the *Conversation* tab. Open *Files changed*.
- **Your comment is visible to nobody.** It is still pending: *Review changes → Submit review*.
- **The partner group has no open PR.** Review the one they open in the first 10 minutes; if
  there is still none at 12:30, tell the lecturer.
