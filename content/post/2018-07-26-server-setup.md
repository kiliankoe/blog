+++
date = "2018-07-26"
title = "Server Setup with traefik and docker-compose"
slug = "server-setup"
+++

In the [last post](/paperless) I hinted towards how I used docker-compose to run all the services I need on my server. Since someone asked me to describe it in a little more detail I'll do just that in this post. It would probably also make sense to document it a bit for myself as I know that I'm going to forget parts of it at some point 🙈

The basic gist is that everything runs in a docker container and exposes only what's necessary to the public web (and not directly by itself). Using docker to orchestrate everything has the benefit of not having to worry about dependencies or unsupported systems (to a certain degree at least) and leads to minimal overhead when trying out new stuff or updating existing services.

On a sidenote: I host my stuff on a VM provisioned from [Hetzner](https://www.hetzner.com/cloud). I used to host all my stuff on Digital Ocean, but I recently ran into hardware limitations for the price class I was willing to pay and had a look around. Hetzner's pricing is by far the best I could find, their servers are located in Germany (EU is a must for me) and their relatively new VM offering has a pretty site as well that looks just like a DO ripoff 😅

# traefik

Holding most of it together is the fantastic [traefik](https://traefik.io), a simple reverse-proxy with everything built-in that I need here. It runs in it's own docker container and comes with a minimal config that I'll go into in a second. The reason I run it at all is because it comes with two amazing features that make it perfect for the job:

* For one it connects directly to the docker socket on the host machine and therefore discovers new services instantly and by itself.
* It automatically handles registering TLS certificates with Let's Encrypt with literally *zero* overhead on my end.

What we're going to do is configure a docker network - let's call it *web* - that every service will be placed into that's actually connected to the internet. Since this network will be service agnostic we'll create it as an external network directly with the docker cli.

```bash
$ docker network create web
```

Now we can create a new docker-compose file for traefik that looks something like this.

```yaml
version: '3'

services:
  app:
    image: traefik
    restart: always
    ports:
      - 80:80
      - 443:443
      - 8080:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik.toml:/traefik.toml
      - ~/data/traefik/acme.json:/acme.json
    networks:
      - web

networks:
  web:
    external: true
```

This describes a new service based on the official traefik image, which is restarted automatically if it stops, exposes ports 80 (HTTP), 443 (HTTPS) and 8080 (dashboard) directly, has a few mounted volumes and is part of the *web* network. For the network to be picked up by docker-compose we need to explicitly list it in a networks section below.

Ports 80 and 443 are pretty self explanatory, but 8080 is where traefik hosts its own dashboard by default. You can also choose to go about that differently, but that's the traefik default. I actually configured the dashboard to be shown on port 443 of a subdomain of my choosing behind a basic auth challenge, so that it's not entirely open to the public, but you can do whatever you like.

By mounting `/var/run/docker.sock` into the container we give traefik access to information on all running containers on the host as I mentioned previously. In `acme.json` traefik stores the Let's Encrypt certificate date. We also mount an additional config file, `traefik.toml`, the contents of which are also relatively simple.

```toml
debug = false
logLevel = "ERROR"

defaultEntryPoints = ["http", "https"]

[web]
# Port for the status/dashboard page
address = ":8080"

[entryPoints]
    [entryPoints.http]
    address = ":80"
        [entryPoints.http.redirect]
        entryPoint = "https"

    [entryPoints.https]
    address = ":443"
    [entryPoints.https.tls]

[retry]

[docker]
endpoint = "unix:///var/run/docker.sock"
domain = "kilian.io"
watch = true
exposedByDefault = false

[acme]
email = "me@kilian.io"
storage = "acme.json"
entryPoint = "https"
onHostRule = true
    [acme.httpChallenge]
    entryPoint = "http"
```

There's not a lot to say about this. We configure the log level, the default entry points and a redirect to always use TLS. Additionally we tell traefik about the base domain and also about how to handle TLS and and which challenge to use.

The only thing left to do now is to setup your domains DNS records to point to your server's IP address and ideally set up a wildcard subdomain, e.g. `*.kilian.io` in my case to point to the server as well. This allows you to specify any necessary subdomains directly (blog.kilian.io runs on GitHub pages for example, not my server) and let everything else fall back to the server and therefore into traefik's hands.

Don't forget to boot up traefik via docker-compose from within it's directory and we're good to go ✨

```bash
$ docker-compose up -d
```

# Running Other Services

As examples we're going to configure two web-facing services. Instances of [gitea](https://gitea.io) and [huginn](https://github.com/huginn/huginn).

## Gitea

Gitea is rather easy to set up, since it requires no other services besides itself. Let's go straight for the docker-compose file.

```yaml
version: '3'

services:
  app:
    image: gitea/gitea:latest
    restart: always
    environment:
      - USER_UID=1000
      - USER_GID=1000
    networks:
      - web
    volumes:
      - ~/data/gitea:/data
    ports:
      - 2221:22
    labels:
      - "traefik.enable=true"
      - "traefik.backend=gitea"
      - "traefik.docker.network=web"
      - "traefik.frontend.rule=Host:git.kilian.io"
      - "traefik.port=3000"

networks:
  web:
    external: true
```

All we need to do is declare two env vars, the network this container will be added to, a volume for persisting data beyond container restarts and rebuilds, specifically for gitea a custom SSH port and most importantly a few labels.

These labels are what traefik uses to understand how to channel traffic to this container. The last two are the most important ones. First we tell traefik which host header to look for in requests to the server (here: git.kilian.io) and then which port this service wants to map to port 80 / 443 on that domain.

That's it. A request to git.kilian.io (or directly to the server with a fitting host header field) will be forwarded to port 3000 of this service. All you have to do is start it up.

```bash
$ docker-compose up -d
```

TLS is configured automatically by traefik on the first request (which might therefore take a second longer). You should be seeing a valid certificate if everything is set up correctly.

## Huginn

Huginn is slightly more complex since we're going to need two services. The application itself and a database.

```yaml
version: '3'

services:
  app:
    image: huginn/huginn
    restart: always
    networks:
      - web
      - internal
    environment:
      - POSTGRES_PORT_5432_TCP_ADDR=db
      - POSTGRES_PORT_5432_TCP_PORT=5432
      - HUGINN_DATABASE_ADAPTER=postgresql
      - HUGINN_DATABASE_USERNAME=huginn
      - HUGINN_DATABASE_PASSWORD=...
      - TIMEZONE=Berlin
    volumes:
      - ~/data:/server/data
    labels:
      - "traefik.enable=true"
      - "traefik.backend=huginn"
      - "traefik.frontend.rule=Host:huginn.kilian.io"
      - "traefik.port=3000"
      - "traefik.docker.network=web"

  db:
    image: postgres
    restart: always
    networks:
      - internal
    environment:
      - POSTGRES_USER=huginn
      - POSTGRES_PASSWORD=...
    volumes:
      - ~/data/huginn/db:/var/lib/postgresql/data

networks:
  internal:
  web:
    external: true
```

The key difference is that we obviously need to create both services, the main application and a postgres database. Since docker-compose doesn't place both of these containers in a new network of their own by default **if** there's already a network present (the *web* network), we also have to explicitly create a new network (I'm calling it *internal*) so that these services can connect to each other. Notice however how the database is *not* a part of the web network, there's no reason for it to be accessible from the outside.

And that's also already it for this case as well 👌

# Conclusion

Running applications including any other services they might depend on behind a reverse-proxy taking care of TLS and only exposing necessary stuff to the web should no longer be an issue. The main complexity for setting up new services lies in... well... setting them up correctly. Most [well designed](https://www.12factor.net/config) applications allow this to be done by setting a few environment variables, making our setup via docker-compose extremely straight-forward and easy to replicate.

Persistence is easily solved via [docker volumes](https://docs.docker.com/storage/volumes/) or volume mounts. I prefer the latter, even though they lead to a few permission issues here and there and are not host-os-agnostic. I suggest having a look at volumes, there are quite a few advantages. It's just a tiny bit more effort to backup and transfer your persisted data.

I also suggest storing your service's docker-compose files and other configs (like the traefik.toml) in a git repo (obviously not public), which makes setup on a new machine even easier.

🖖
