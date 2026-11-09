<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 15.2 — A First Dockerfile for Your Project

**Session 15 · Tuesday 10 November · 25 minutes · one per group, everyone watching one screen**

Today's Dockerfile is **naive on purpose**: it works, and it has three problems you will fix on
Friday. Do not improve it yet. On Friday you will time it first, and the fix only makes sense
after that.

---

## 1. A branch

On the laptop of whoever types today, from your group repository:

```bash
git switch main
git pull
git switch -c add-dockerfile
```

---

## 2. Find your command

Your app's command is the name on the left of `[project.scripts]` in `pyproject.toml`:

```toml
[project.scripts]
gradebook = "gradebook.cli:app"
```

Here it is `gradebook`. It is the word you type after `uv run`.

---

## 3. The starter Dockerfile

Create a file called exactly `Dockerfile` (capital D, no extension) in the **root** of your
repository, next to `pyproject.toml`. Paste this, and change `your-command` to yours:

```dockerfile
FROM python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:0.13.5 /uv /bin/uv

WORKDIR /app
COPY . .
RUN uv sync --locked --no-dev

ENV PATH="/app/.venv/bin:$PATH"
ENTRYPOINT ["your-command"]
CMD ["--help"]
```

Line by line, out loud in your group (each one is on the slides):

| Line | Does |
|---|---|
| `FROM python:3.13-slim` | Start from a small Debian Linux with Python 3.13 installed |
| `COPY --from=… /uv /bin/uv` | Copy the `uv` program out of uv's own image |
| `WORKDIR /app` | Work in `/app`, creating it |
| `COPY . .` | Copy your whole repository into `/app` |
| `RUN uv sync --locked --no-dev` | Install exactly what `uv.lock` says, without the dev tools |
| `ENV PATH=…` | Let the container find your command without `uv run` |
| `ENTRYPOINT […]` | The program the container runs, always |
| `CMD ["--help"]` | Its arguments, if `docker run` gives none |

---

## 4. Build it

```bash
docker build -t your-command .
```

The `.` at the end matters: it is the folder Docker builds from, your repository.

Read the output. Find the line that runs `uv sync`, and how many packages it installs. Did you
also get this warning?

```text
warning: Ignoring existing virtual environment linked to non-existent Python interpreter
```

**Write down:** where did that `.venv` come from? (Hint: line 4.)

---

## 5. Run it

```bash
docker run --rm your-command
```

Your app's `--help`, printed by a Python you did not install, on a Linux you are not running.

Now run **one real command** of your app, the way your README says, but with
`docker run --rm your-command` in place of `uv run your-command`. For example:

```bash
docker run --rm gradebook average grades.csv
```

| Your app | Add |
|---|---|
| Interactive: it waits for you to type (a game, a menu) | `-it` before the image name: `docker run --rm -it your-command play` |
| Reads a file from your repository | It works: `COPY . .` copied the file in. On Friday, it will not, and you will see why |
| Writes a file | It works, and the file vanishes with the container. Friday's problem |

---

## 6. A pull request, not a merge

```bash
git add Dockerfile
git commit -m "Add a Dockerfile"
git push -u origin add-dockerfile
```

Open the pull request on GitHub, titled **Add a Dockerfile**. CI should be green: it does not
build the image yet.

**Do not merge it.** On Friday you will add to this branch: the fixes, and the CI steps that
build the image on every push.

---

## If something goes wrong

| You see | Means | Do |
|---|---|---|
| `failed to read dockerfile: open Dockerfile: no such file` | Wrong name or wrong folder | Exactly `Dockerfile`, in the root. On Windows check it is not `Dockerfile.txt` |
| `executable file not found in $PATH: "your-command"` | `ENTRYPOINT` does not match `[project.scripts]` | Copy the name from `pyproject.toml`, exactly, `-` and `_` included |
| `The lockfile at uv.lock needs to be updated` | `pyproject.toml` changed and `uv.lock` was not committed | `uv lock` on your laptop, commit `uv.lock`, build again |
| `OSError: Readme file does not exist: README.md` | `pyproject.toml` names a README that is not in the repository | Add the file, or fix the name in `pyproject.toml` |
| Build fails pulling `python:3.13-slim` | Wi-Fi | Wait for the `docker pull` from Lab 1 to finish, then build again |
