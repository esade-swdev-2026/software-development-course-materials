<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 16 — Containerize Your Project

**Session 16 · Friday 13 November · 11:30–13:15 · Practice 4 · one PR per group**

You start from Tuesday's **Add a Dockerfile** pull request: a naive Dockerfile that works.
No checkpoint today. What you build is marked once, in the final submission, against this
criterion, word for word:

**Docker criterion** (final submission, read on `main` at `v1.0`; all five):

1. CI builds the image and runs it with `--help`: the steps **Build the image** and **Run the image** in the `check` job, green.
2. A `.dockerignore` keeps at least `.venv/`, `.git/` and the tool caches out of the build.
3. The dependencies are installed **before the code is copied in**, so a code change does not reinstall them.
4. The app runs as a **non-root user**.
5. The README has a **Run with Docker** section whose commands run as written on the lecturer's machine, and show the app's data or configuration living **outside the image**: data that survives `docker rm`, or configuration that changes the output without a rebuild.

**Today, in class: items 1–4**, in Tuesday's pull request, reviewed by your partner group and
squash-merged together at 13:05. **Item 5** (sections 4 and 6) you start today; if it needs
more than the time left, it may follow in a pull request of its own, merged by `v1.0`.

---

## 0. Back on Tuesday's branch (11:30)

```bash
git switch add-dockerfile
git pull
```

If the PR was merged on Tuesday by mistake: `git switch main && git pull && git switch -c
containerize`, and open a new PR at the end.

**Time the problem first.** Build, change one line anywhere in `src/`, build again:

```bash
docker build --progress=plain -t your-command . 2>&1 | grep -E "CACHED|Prepared|Installed"
```

Write down how many packages the second build installed. You are about to make it one.

---

## 1. `.dockerignore`

Create `.dockerignore` next to the Dockerfile:

```text
.venv/
.git/
__pycache__/
*.py[cod]
.ruff_cache/
.mypy_cache/
.pytest_cache/
data/
```

> **Keep `data/` out of this list if it holds files you committed to git and the app needs
> to start**: a product list, a catalogue, seed data. `git ls-files data` tells you. Section 4
> shows what to do with them. If your app writes to a folder with another name
> (`storage/`, `my-app-data/`), list that folder instead.

Build again. The `.venv` warning from Tuesday is gone, and `docker image ls your-command` is
smaller.

---

## 2. Dependencies first, code last

Replace the middle of your Dockerfile, so the whole file reads:

```dockerfile
FROM python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:0.13.5 /uv /bin/uv

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

COPY README.md LICENSE ./
COPY src ./src
RUN uv sync --locked --no-dev

ENV PATH="/app/.venv/bin:$PATH"
ENTRYPOINT ["your-command"]
CMD ["--help"]
```

- The first `uv sync` installs only the dependencies (`--no-install-project`). It depends on
  `pyproject.toml` and `uv.lock` alone, so it is rebuilt only when they change.
- The second installs your own package, after the code is in. About a second.
- `README.md` and `LICENSE` are there because `pyproject.toml` names them.

**Prove it.** Build, change a line in `src/`, build again with the command from step 0. The
dependency step says `CACHED`, and the last step installs **one** package: yours.

---

## 3. A non-root user

Add these two lines **before** `ENV PATH`:

```dockerfile
RUN useradd --create-home app && mkdir /app/data && chown app:app /app/data
USER app
```

```bash
docker build -t your-command .
docker run --rm --entrypoint id your-command
```

`uid=1000(app)`. Not root.

The `mkdir` and `chown` make a folder **the app may write to**. Everything else in `/app`
belongs to root, so the app can read its code but not change it. Change `/app/data` to the
folder your app actually writes to (section 4).

Now try a command of your app that **saves** something. If it fails with
`PermissionError: [Errno 13] Permission denied`, good: section 4 is about exactly that.

---

## 4. Where does your app keep its files?

Find where your app reads and writes, in your code: look for `Path(`, `open(`, `.json`,
`.csv`. Then find your case:

| Your app writes to… | Example in the code | Do this |
|---|---|---|
| **A folder** in the current directory | `Path("data") / "tasks.csv"` | A **named volume** on that folder. `mkdir` and `chown` it in step 3, with its real name |
| **Loose files** in the current directory | `Path("cards.json")` | Move them into a folder: `Path("data") / "cards.json"`, every place the name appears, with the tests updated. In the same PR, or item 5's follow-up. Then as above |
| A path from an **environment variable** | `os.environ.get("APP_FILE", ...)` | `-e APP_FILE=/app/data/file.json`, plus a named volume on `/app/data`. No code change |
| Your **home directory** | `Path.home() / ".app.json"` | A named volume on the home folder: `-v name:/home/app`. No code change |
| **Inside your own package** | `Path(__file__).parent / "books.csv"` | It cannot work: the code is read-only, and it is editing a file you committed. Ship the file as **seed data** and copy it to `data/` on first run. Read your group's issue |
| It **only reads** a file you might want to edit | `world.json`, a fares table | A **bind mount**, read-only: `-v ./world.json:/data/world.json:ro`, and point the app at it |
| Nothing | | Read your group's issue |

**Committed seed data in `data/`** (the app needs it to start): do not ignore `data/`, and copy
it in owned by the app user, in place of the `mkdir`:

```dockerfile
RUN useradd --create-home app
COPY --chown=app:app data ./data
USER app
```

The first time a new named volume is mounted on `/app/data`, Docker copies those files into it.

### Prove it survives

Run your app twice, **in two containers**, with the same volume. The second sees what the
first saved:

```bash
docker run --rm -v your-command-data:/app/data your-command <a command that saves>
docker run --rm -v your-command-data:/app/data your-command <a command that shows it>
```

Without `-v`, the second shows nothing: Lab 15.1, step 4. `docker volume ls` lists your volume;
`docker volume rm your-command-data` starts over.

Interactive app (a game, a menu)? Add `-it` to every `docker run`.

---

## 5. CI builds and runs the image

In `.github/workflows/check.yml`, add two steps **at the end of the `check` job**, after
`Tests`, indented like the others:

```yaml
      - name: Build the image
        run: docker build -t your-command .

      - name: Run the image
        run: docker run --rm your-command --help
```

Commit, push, and open the PR's *Checks* tab. Both new steps must be green.

> **From the moment this is on `main`, a broken Dockerfile blocks every pull request**,
> because `check` is required to merge. That is the point: nothing reaches `main` that does not
> build and start.

---

## 6. "Run with Docker" in the README

**Someone who did not write the Dockerfile** writes this section, and runs every line in it,
as written, in a fresh terminal:

````markdown
## Run with Docker

```bash
docker build -t your-command .
docker run --rm your-command --help
docker run --rm -v your-command-data:/app/data your-command <a command that saves>
docker run --rm -v your-command-data:/app/data your-command <a command that shows it>
```

Your data lives in the named volume `your-command-data`; `docker volume rm your-command-data`
deletes it.
````

Adapt it to your case from section 4: `-e`, a bind mount, `-it`.

---

## 7. Review and merge (12:50–13:15)

1. Push; wait for the green check
2. Your **partner group** (the same pairs as session 14) reviews the PR, with
   `grading/review-checklist.md`, for items 1–4. If item 5 is in it too, they **run the
   README's commands** on their own laptop: if they do not work as written, that is a review
   comment
3. Fix, push, reply "Done in `<sha>`"
4. **13:05, everyone together: Squash and merge.** Title: *Containerize the app* (or what the
   PR now does)

Item 5 not finished? Merge items 1–4 now anyway. Item 5 goes in a pull request of its own,
reviewed by the same partner group, merged by `v1.0`.

Then everyone: `git switch main && git pull && docker build -t your-command .`

---

## Done?

Today:

- [ ] The PR is squash-merged, and `main` is green, with **Build the image** and **Run the
      image** among its steps (item 1)
- [ ] `.dockerignore` exists (item 2)
- [ ] A one-line code change rebuilds without reinstalling the dependencies (item 3)
- [ ] `docker run --rm --entrypoint id your-command` is not root (item 4)

By `v1.0`:

- [ ] The README's "Run with Docker" commands run as written, and the data survives (or the
      configuration is read from outside the image) (item 5). Your partner group ran them on a
      laptop that is not yours: the lecturer will too

Finished early? Try a **multi-stage build** (slide 10): the final image without uv and without
`src/`. Compare `docker image ls`. Optional, not marked.

---

## If something goes wrong

| You see | Means | Do |
|---|---|---|
| `PermissionError: [Errno 13] Permission denied: 'data'` | The app, as `app`, cannot create a folder in root's `/app` | `mkdir` and `chown` that folder before `USER app` (step 3) |
| `PermissionError: … 'data/…'` with a volume | The folder did not exist in the image, so the volume belongs to root | Fix the Dockerfile (step 3) and rebuild. Still failing? The volume already holds files from before: `docker volume rm` it |
| `PermissionError` on a path under `/app/src/` or `.venv/` | The app writes inside its own package | Section 4, "inside your own package" |
| `not found` for a file the app needs to start | `.dockerignore` or `COPY src` left it out | Section 4, "committed seed data" |
| `uv sync` reinstalls everything after a code change | A `COPY` of your code comes **before** the first `uv sync` | Only `pyproject.toml` and `uv.lock` before it |
| `Readme file does not exist` during the second `uv sync` | `COPY README.md LICENSE ./` missing, or your files have other names | Copy what `pyproject.toml` names |
| `"/LICENSE": not found` (or `"/README.md"`) | The file is not in your repository, or `.dockerignore` lists it | Drop it from the `COPY` line if `pyproject.toml` does not need it |
| CI: `Build the image` fails, works on your laptop | A file the build needs is in `.gitignore`, so it is not on GitHub | `git ls-files` shows what CI has |
| The game or menu exits at once | No terminal | `-it` |
| Bind mount: the app finds a **folder** where it expected your file, and an empty folder appears on your laptop | The host path did not exist, so Docker created a folder there | Run from the repository root, check the name, delete the empty folder, run again |
