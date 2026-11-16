<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 17a — Docker Compose

**Session 17 · Tuesday 17 November · 09:45–10:10 · in pairs, on one laptop · not graded**

You get an old Compose file that no longer runs, make it run, give the database a volume, and
make the web server wait until the database is *ready*, not just started. Everything happens
in a scratch folder, not in your project.

```bash
mkdir compose-lab && cd compose-lab
docker pull -q nginx:1.29-alpine && docker pull -q postgres:18-alpine
```

---

## 1. A file from 2016 (5 min)

Create `compose.yaml` with exactly this. It is the old "version 1" format, which you will still
find in blog posts and old repos:

```yaml
web:
  image: nginx:1.29-alpine
  ports:
    - "8080:80"
  links:
    - db
db:
  image: postgres:18-alpine
  environment:
    - POSTGRES_PASSWORD=lab-only
```

```bash
docker compose up -d
```

You get:

```text
validating …/compose.yaml: additional properties 'db', 'web' not allowed
```

**Read it before you fix it.** A Compose file allows only a few top-level keys: `services`,
`volumes`, `networks`, and a few more. `web` and `db` are not among them, so they must
go *inside* `services`.

Fix it:

- Put both services under a top-level `services:` key, and indent them.
- Delete `links:`. Services in one Compose file already find each other by name (section 4).
- Turn `environment:` into a map: `POSTGRES_PASSWORD: lab-only`.
- **Do not** add a `version:` line. Compose ignores it now and warns: *the attribute `version`
  is obsolete*.

```bash
docker compose up -d
docker compose ps
curl -s localhost:8080 | grep title        # or open http://localhost:8080
```

`<title>Welcome to nginx!</title>` means it works.

## 2. Give the database somewhere to live (8 min)

Write something into the database:

```bash
docker compose exec db psql -U postgres -c "CREATE TABLE notes (body text);"
docker compose exec db psql -U postgres -c "INSERT INTO notes VALUES ('still here');"
docker compose down
docker compose up -d
docker compose exec db psql -U postgres -c "SELECT * FROM notes;"
```

`relation "notes" does not exist`. `down` removed the container, and the data went with it,
just as in session 16.

Add a named volume. Last year's lab mounted it like this; **try it as written**:

```yaml
  db:
    image: postgres:18-alpine
    environment:
      POSTGRES_PASSWORD: lab-only
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

```bash
docker compose up -d
docker compose ps -a              # db: Exited (1)
docker compose logs db | head -15
```

Read the log. Postgres 18 changed where its image keeps data, and it refuses to start with a
volume mounted at the old path. The log says why and names the new layout. **Copying a fix from
an old tutorial is how you meet this error at work.** Fix the path:

```yaml
      - db-data:/var/lib/postgresql
```

```bash
docker compose down -v            # -v: remove the volume from the failed attempt too
docker compose up -d
```

Now repeat the three commands at the top of this section: create, insert, `down`, `up`,
select. `still here` survives. Then:

```bash
docker compose down -v
docker compose up -d
docker compose exec db psql -U postgres -c "SELECT * FROM notes;"
```

**Write down:** what does `-v` change?

## 3. Started is not ready (7 min)

`depends_on` decides the **order** in which containers start. It does not wait for Postgres
to accept connections, which takes a few seconds after the container starts. Add a health check,
and make `web` wait for it:

```yaml
services:
  web:
    image: nginx:1.29-alpine
    ports:
      - "8080:80"
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:18-alpine
    environment:
      POSTGRES_PASSWORD: lab-only
    volumes:
      - db-data:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 2s
      retries: 15

volumes:
  db-data:
```

```bash
docker compose down -v
docker compose up -d
docker compose ps
```

Watch the output of `up`: `db` goes `Waiting`, then `Healthy`, and only then does `web` start.
`ps` shows `(healthy)` next to `db`.

## 4. How did `web` find `db`? (5 min)

You deleted `links:`, and nothing broke. Ask `web`:

```bash
docker compose exec web ping -c 1 db
docker network ls | grep compose-lab
```

Compose created one network for this project (`compose-lab_default`) and put both services
on it. On that network, **a service's name is its host name**. That is what lab 17b is about.

Clean up:

```bash
docker compose down -v
```

## Done?

- [ ] You read the `additional properties` error and fixed it with `services:`, not `version:`
- [ ] Your data survived `down` and was gone after `down -v`
- [ ] You read the Postgres 18 log and fixed the mount path
- [ ] `up` showed `db` becoming `Healthy` before `web` started

## If something goes wrong

| You see | It means |
|---|---|
| `port is already allocated` | Something else is on 8080. Change `"8080:80"` to `"8081:80"` and use that port |
| `curl: (7) Failed to connect` right after `up` | nginx is still starting. Try again in a second |
| `db` stays `Exited (1)` after you fixed the path | The volume still holds the failed attempt: `docker compose down -v`, then `up -d` |
| `password authentication failed` | You changed `POSTGRES_PASSWORD` after the volume was created. The password is only set on an empty volume: `down -v` |
