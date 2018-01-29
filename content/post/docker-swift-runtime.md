+++
date = "2018-01-29T12:25:00+01:00"
title = "Docker Swift Runtime"
slug = "docker-swift-runtime"
+++

I recently wrote a small [Vapor](https://vapor.codes) web app in Swift which I then wanted to deploy on my server inside a docker container. Not having all too much experience with docker my simple Dockerfile looked something like this.

```shell
FROM swift:4

COPY . .

EXPOSE 8080

RUN swift build --configuration release

ENTRYPOINT [".build/release/Run"]
CMD ["serve", "--env=production"]
```

Whilst this worked perfectly fine, the image size turned out to be a whopping 1.5GB. That didn't quite feel right if for an app as small as mine.

The problem is of course that the `swift` image contains the entire development environment that we don't actually need anymore after having built the app.

After trying to go the route of automating the build process by using a container dedicated to building the app then extracting everything I needed from that container and building a new one from that I saw that docker actually had this functionality built in. It's called a multistage build and lets you use separate images to perform whatever it is you want to do. In this case use an image for compiling the app and a separate one to actually package up and run the app binary and configs.

The Dockerfile for that case doesn't get a lot more complicated, we just set a second base image after we're done with the first one and copy over the necessary files.

```shell
FROM swift:4 as build

COPY . .

RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

FROM ubuntu:16.04

RUN apt-get -q update && \
    apt-get -q install -y \
    libatomic1 \
    libbsd0 \
    libcurl3 \
    libicu55 \
    libxml2 \
    && rm -r /var/lib/apt/lists/*

COPY --from=build /build/bin .
COPY --from=build /build/lib/* /usr/lib
COPY --from=build /Config ./Config

EXPOSE 8080

ENTRYPOINT["./release/Run"]
CMD["serve", "--env=production"]
```

To properly set up the second image to run our app we just have to install a few dependencies and copy over the contents of `/usr/lib/swift/...`. The rest is the same as before.

Since we now no longer store all dev dependencies in our image, we've just made our image ~1.3GB smaller (around 200MB), that's quite the improvement!

To wrap things up even nicer I published the runtime image as [`kiliankoe/swift-runtime`](https://hub.docker.com/r/kiliankoe/swift-runtime/) so that we can reduce our Dockerfile to the following.

```shell
FROM swift:4 as build

COPY . .

RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

FROM kiliankoe/swift-runtime:latest

COPY --from=build /build/bin .
COPY --from=build /Config ./Config

EXPOSE 8080

ENTRYPOINT["./release/Run"]
CMD["serve", "--env=production"]
```

My image above is still based on `ubuntu:16.04`, which definitely shouldn't be a necessity and accounts for most of the remaining 200MB. It would be nice to have far slimmer images in the future, based on alpine for example, but for time being the [efforts needed seem to be insurmountable](https://lists.swift.org/pipermail/swift-users/Week-of-Mon-20151228/000653.html).
