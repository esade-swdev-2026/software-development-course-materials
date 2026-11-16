<!-- TARGET REPO: software-development-course-materials (PUBLIC). Student-facing. -->

# Lab 17b — Docker Networking

**Session 17 · Tuesday 17 November · 10:10–10:30 · in pairs · not graded**

Two containers on the same machine: can they talk to each other, and by what name? You see
the failure first, then the fix. Every container here is a tiny Alpine Linux with `ping` in it.

```bash
docker pull -q alpine:3.22
```

---

## 1. The default network: no names (6 min)

Start two containers without saying which network to use:

```bash
docker run -dit --name c1 alpine:3.22
docker run -dit --name c2 alpine:3.22
docker exec c1 ping -c 1 c2
```

```text
ping: bad address 'c2'
```

They are on the same network. Docker calls it `bridge`, and every container you started in
sessions 15 and 16 joined it. But that default network **has no DNS**, so `c2` is not a name
that `c1` can look up. Ask Docker for `c2`'s address and try that instead:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' c2
docker exec c1 ping -c 1 <that address>
```

That works. **Write down** why hard-coding that address in your app's configuration would be a
bad idea. (Hint: `docker rm -f c2`, start it again, and look at the address.)

## 2. A network of your own: names work (6 min)

```bash
docker network create lab-net
docker run -dit --name c3 --network lab-net alpine:3.22
docker run -dit --name c4 --network lab-net alpine:3.22
docker exec c3 ping -c 1 c4
docker network inspect lab-net
```

`PING c4 (172.x.x.x)`. On a network you create, Docker runs a small DNS server, and **a
container's name is its host name**. Find both containers and their addresses in the output
of `inspect`.

Is `c1` (on the default network) able to reach `c4`?

```bash
docker exec c1 ping -c 1 c4
```

Networks also **separate** containers. A database on one network cannot be reached by a
container on another one.

## 3. No network at all (3 min)

```bash
docker run --rm --network none alpine:3.22 ip addr
docker run --rm --network none alpine:3.22 ping -c 1 -W 2 8.8.8.8
```

Only `lo` (the container talking to itself), and `Network unreachable`. When would you want
this? Think of a job that converts files and must never send them anywhere.

## 4. Compose does section 2 for you (5 min)

```bash
mkdir net-lab && cd net-lab
```

`compose.yaml`:

```yaml
services:
  server:
    image: nginx:1.29-alpine
  client:
    image: alpine:3.22
    command: ["sh", "-c", "while true; do wget -qO- http://server | grep title; sleep 3; done"]
```

```bash
docker compose up -d
docker compose logs -f client          # Ctrl-C to stop following
docker network ls | grep net-lab
docker compose down
```

No `networks:` key anywhere, yet `client` finds `server` by name. Compose created
`net-lab_default`, a network of the section 2 kind, and attached both services to it. This is
why `DATABASE_URL` in the tracker says `@db:5432`: `db` is the database's service name.

Clean up section 1–3:

```bash
docker rm -f c1 c2 c3 c4
docker network rm lab-net
```

## Done?

- [ ] You saw `bad address` on the default network, and a working ping by address
- [ ] On your own network, a name worked, and `c1` could not reach `c4`
- [ ] With `--network none`, the container had only `lo`
- [ ] In Compose, `client` reached `server` by its service name

## Host networking: one paragraph, no exercise

`--network host` removes the isolation: the container uses the host's own network, so nginx
listens on the host's port 80 with no `-p`. It is the third mode you will read about, and it
behaves differently on Docker Desktop (Mac, Windows) than on Linux, which is why there is no
exercise for it today.
