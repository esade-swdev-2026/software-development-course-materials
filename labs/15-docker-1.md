<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 15.1 — Run, Look Inside, Clean Up

**Session 15 · Tuesday 10 November · 20 minutes · on your own**

You need Docker running: `docker run --rm hello-world` prints *Hello from Docker!*. If it does
not, pair with someone in your group and work on their machine. The fix for your install is
for office hours, not for today.

Start the downloads **now**, in a second terminal, so they are done when you need them. If you
pulled them at home, they finish at once:

```bash
docker pull nginx
docker pull python:3.13-slim
docker pull ghcr.io/astral-sh/uv:0.13.5
```

---

## 1. Where did it go?

```bash
docker run hello-world
docker ps
docker ps -a
```

`docker ps` shows nothing. `docker ps -a` shows a container with a made-up name, *Exited*.

**Write down:** the container ran, printed, and stopped. Why does it still exist? Remove it
by its name:

```bash
docker rm <its-name>
```

From now on, `--rm` does that for you: `docker run --rm hello-world` leaves nothing behind.

---

## 2. A web server you never installed

```bash
docker run -d --name web -p 8080:80 nginx
docker ps
```

Open **http://localhost:8080** in your browser. *Welcome to nginx!*

- `-d` runs it in the background and gives your terminal back.
- `-p 8080:80` connects port 8080 on **your laptop** to port 80 **inside the container**.
- `--name web` lets you say `web` instead of a random name or an ID.

Its log is one line per page load:

```bash
docker logs web
```

---

## 3. Inside the container

`exec` runs a second command inside a container that is already running:

```bash
docker exec -it web bash
```

Your prompt changes: you are now in the container. Look around, then change the page:

```bash
cat /etc/os-release
ls /usr/share/nginx/html
echo '<h1>Hello from inside a container</h1>' > /usr/share/nginx/html/index.html
exit
```

Reload the browser. Your page.

---

## 4. A container's files die with it

```bash
docker rm -f web
docker run -d --name web -p 8080:80 nginx
```

Reload the browser. **Your page is gone**: the new container started from the image, and the
image never had your change. `rm -f` stops and removes in one step.

**Write down:** where would you have to put the page so that it survives? You will answer it
on Friday.

---

## 5. Clean up

```bash
docker rm -f web
docker ps -a
docker images
```

Keep the images: Lab 2 and Friday use `python:3.13-slim`. You can delete `nginx` and
`hello-world`:

```bash
docker rmi nginx hello-world
```

`docker system df` shows how much disk Docker is using. `docker system prune` deletes stopped
containers and unused images in one go: read what it says before you answer `y`.

---

## Done?

Go to **Lab 2**: `labs/15-docker-2.md`.

---

## If something goes wrong

| You see | Means | Do |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop is not running | Start it; wait for the whale icon to say *running* |
| `port is already allocated` | Something on your laptop already uses 8080 | Use another: `-p 8081:80`, then open `localhost:8081` |
| `Conflict. The container name "/web" is already in use` | A container called `web` exists, maybe stopped | `docker rm -f web`, then run again |
| `permission denied ... docker.sock` (Linux) | Your user is not in the `docker` group | `sudo usermod -aG docker $USER`, then log out and in |
| The pull is very slow | The room's Wi-Fi, shared with sixty laptops | Carry on with the next step while it downloads |
