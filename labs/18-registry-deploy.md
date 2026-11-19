<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 18 — Publish Your Image

**Session 18 · Friday 20 November · 11:30–13:15 · one laptop per group · ends with `v1.0`**

The goal is to publish your project's image in a registry, put there by a pipeline on every merge, and publish tag
**`v1.0`**. The demo on 27 November pulls that image and runs it. Nobody builds
anything on demo day.

**Before you start:** your Docker pull request must be merged. `git switch main && git pull`,
then `ls Dockerfile .dockerignore`. If either is missing, merge first: that is today's first
ten minutes.

---

## Lab 1 — By hand, once (11:30–11:50)

Do it manually once, and **count the steps**. Below, `<you>` is your GitHub username in
**lowercase**, and `<project>` is your repo's name.

### 1. A token that may push images

GitHub → your avatar → **Settings → Developer settings → Personal access tokens → Tokens
(classic) → Generate new token (classic)**.

- Note: `swdev lab 18`
- Expiration: **7 days**
- Scopes: tick **`write:packages`** only (it ticks `read:packages` too)

Copy the token now: GitHub shows it once. Treat it like a password: not in a file in your repo,
not in a chat, never in a Dockerfile. Keep it in your password manager until Sunday: Lab 2 §4
and the `v1.0` check need it again.

### 2. Log in, tag, push

```bash
docker login ghcr.io -u <you>              # paste the token as the password
docker build -t ghcr.io/<you>/<project>:hand .
docker push ghcr.io/<you>/<project>:hand
```

The image name **is** the address: registry (`ghcr.io`) / owner / name : tag. Find it on your
GitHub profile → **Packages**.

### 3. Make it public, then prove it runs from the registry alone

On the package page: **Package settings → Change visibility → Public**. Then:

```bash
docker image rm ghcr.io/<you>/<project>:hand
cd "$(mktemp -d)"                           # an empty folder: no code, no Dockerfile
docker pull ghcr.io/<you>/<project>:hand
docker run --rm ghcr.io/<you>/<project>:hand --help
```

### 4. Swap

Give your partner group (the session 14 pairs) your image name. Pull theirs and run it. What
did you need from them? Only the name.

### 5. Count

How many commands, clicks and secrets did that take? Write the number down. Now imagine doing
it after every merge, by whoever merged, without one typo. Then log out:

```bash
docker logout ghcr.io
```

---

## Lab 2 — Automate it (11:50–12:45)

From now on the registry fills itself, and nobody types `docker push` again.

### 1. A branch and the job

```bash
git switch main && git pull
git switch -c publish-image
```

Add this job to `.github/workflows/check.yml`, **after** the `check` job, at the same
indentation as `check:`. Copy it exactly: it needs no edits for your project.

```yaml
  release:
    needs: check
    if: >-
      github.event_name == 'push' &&
      (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v'))
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Check out the code
        uses: actions/checkout@v7

      - name: Name the image
        run: |
          echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}" >> "$GITHUB_ENV"
          echo "SHA=${GITHUB_SHA::7}" >> "$GITHUB_ENV"

      - name: Log in to GHCR
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u "${{ github.actor }}" --password-stdin

      - name: Build the image
        run: docker build --label "org.opencontainers.image.source=https://github.com/${{ github.repository }}" -t "$IMAGE:$SHA" .

      - name: Push it, tagged with the commit
        run: docker push "$IMAGE:$SHA"

      - name: Push it, tagged with the version
        if: github.ref_type == 'tag'
        run: |
          docker tag "$IMAGE:$SHA" "$IMAGE:$GITHUB_REF_NAME"
          docker push "$IMAGE:$GITHUB_REF_NAME"

      - name: Pull it back and run it
        run: |
          docker image rm "$IMAGE:$SHA"
          published="$IMAGE:$SHA"
          if [ "$GITHUB_REF_TYPE" = tag ]; then
            docker image rm "$IMAGE:$GITHUB_REF_NAME"
            published="$IMAGE:$GITHUB_REF_NAME"
          fi
          docker pull "$published"
          docker run --rm "$published" --help
```

### 2. Read it before you push it

With your group, find the line that does each of these. You will be asked at the demo.

| What | Which line |
|---|---|
| Nothing ships if the checks are red | |
| It never runs for a pull request, only after a merge or a tag | |
| No secret of yours is involved | |
| Every image is named after the commit it came from | |
| A version tag like `v1.0` also becomes an image tag | |
| The pipeline checks its own result, and for a tag, the very image demo day pulls | |

`secrets.GITHUB_TOKEN` is not something you created. GitHub hands every run a fresh token that
expires when the run ends, and `packages: write` is the only permission you gave it. Compare
that with the token you made in Lab 1.

### 3. Pull request, review, merge

```bash
git add .github/workflows/check.yml
git commit -m "Publish the image from CI"
git push -u origin publish-image
```

Open the PR. On the PR, `release` shows as **skipped**: pull requests never publish. Your
partner group reviews it; squash-merge.

### 4. Watch it ship

**Actions** tab → the run on `main`: `check`, then `release`. When it is green, open your repo's
main page → **Packages** (right-hand column) → your image, tagged with the first seven
characters of the merge commit.

The package page says **Private**, and it stays that way: only your group and I can pull it.
To pull it, log in first. Your Lab 1 token works, since `write:packages` includes reading.

Then, on any laptop:

```bash
docker login ghcr.io -u <you>              # paste the token as the password
docker pull ghcr.io/esade-swdev-2026/<project>:<those seven characters>
docker run --rm ghcr.io/esade-swdev-2026/<project>:<those seven characters> --help
```

---

## `v1.0` — the pipeline publishes it (12:45–13:15)

The final submission is the `v1.0` tag on `main` (see the final rubric). Check first, tag
second:

```bash
git switch main && git pull
uv run ruff check . && uv run ruff format --check . && uv run mypy src tests && uv run pytest
git tag -a v1.0 -m "Final submission"
git push origin v1.0
```

The tag push runs `check` and `release` again, and this time `release` also pushes
`:v1.0`. When it is green:

```bash
docker pull ghcr.io/esade-swdev-2026/<project>:v1.0
docker run --rm ghcr.io/esade-swdev-2026/<project>:v1.0 --help
```

That is the exact command I type on demo day.

Not finished? You have until **Sunday 22 November, 23:59**. The rubric's last section explains how to move
the tag: fix in a PR, merge, `git tag -fa v1.0`, `git push --force origin v1.0`. Every move
publishes the image again.

---

## Done?

- [ ] Lab 1: you pushed by hand, pulled it back in an empty folder, ran your partner group's image, and logged out
- [ ] Lab 2: `release` is in `check.yml`, merged through a reviewed PR, and green on `main`
- [ ] Your group can point at the line for each row of the table in Lab 2 §2
- [ ] `v1.0` is tagged, and `docker pull …:v1.0` then `docker run … --help` works on a laptop that did not build it (logged in)

## If something goes wrong

| You see | It means |
|---|---|
| `denied: permission_denied: write_package` (Lab 1) | The token lacks `write:packages`, or you typed your username with capitals. Make a new token; use lowercase |
| `unauthorized` on `docker pull` (Lab 1 §3) | The package is still private: change its visibility, or `docker login` first |
| `unauthorized` or `denied` pulling `ghcr.io/esade-swdev-2026/…` | You are not logged in, or your token expired (7 days). `docker login ghcr.io` with a fresh one |
| `invalid reference format: repository name must be lowercase` | Your username or repo has capitals. In Lab 2 the job lowercases it for you (`,,`) |
| `release` is skipped on `main` | `check` failed first, or the job's `if:` was retyped. Copy it again |
| `denied: installation not allowed to Create organization package` | The org does not let the pipeline create packages yet. Tell me: it is an org setting |
| `release` red at **Pull it back and run it** | The image was published but does not start. Same failure as `docker run … --help` on your laptop: fix that |
