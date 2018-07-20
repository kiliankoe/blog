+++
title = "Paperless"
date = "2018-07-20T12:00:00+02:00"
slug = "paperless"
+++

For the past few years I've been scanning all paper correspondence, be that something I receive via snail-mail, invoices, contracts or whatever else. This has been a huge improvement over not doing so. Before I had troubles finding documents when I needed them and usually had them lying around at home, not at hand when necessary.

Both of these issues are easily resolvable by having digital copies. They can be accessed remotely and are searchable. OCR software has gotten pretty fantastic as well, making it possible to search for certain keywords even in pretty bad scans.

Having used Evernote as a backing store for this database for years now, I've become rather dissatisfied with that platform. It's slow, it's primarily suited for different use cases and it's gotten expensive as well. So I decided to migrate to something else, using the very cool software [paperless](https://github.com/danielquinn/paperless). Here's a short overview of my workflow using paperless.

# Setup

I rent a VM to run most of the web-based application I use. Every application is managed via a docker-compose file. This makes it trivial to manage services with very different architectures, including paperless.

The docker-compose file looks something like the following. Please note that I did leave out a few details that are very specific to my setup, this won't work *as is*. You're at least going to have to manage exposing port 8000 of the server service.

```yaml
version: '3'

services:
  server:
    image: danielquinn/paperless
    restart: always
    volumes:
      - /path/to/your/data:/usr/src/paperless/data
      - /path/to/your/media:/usr/src/paperless/media
      - /path/to/your/consume:/consume
    environment:
      - PAPERLESS_OCR_LANGUAGES=deu
    command: ["runserver", "0.0.0.0:8000"]

  consumer:
    image: danielquinn/paperless
    restart: always
    depends_on:
      - server
    volumes:
      - /path/to/your/data:/usr/src/paperless/data
      - /path/to/your/media:/usr/src/paperless/media
      - /path/to/your/consume:/consume
    command: ["document_consumer"]
```

Here I instantiate two services based on the same image, one running the paperless webserver, one running the paperless consumer service, which watches for new files in its consume directory. Paperless has three options of adding new files.

* The consumer watches a directory and adds new files from there, removing them afterwards.
* The consumer watches your mail account and adds files from specific emails.
* New files are added via a POST request to the HTTP API.

I'm also not a huge fan of docker volumes, although they might have a few advantages. Mounting directories is easier to manage imho 🙈

# Workflow

So now we have paperless running and keeping watch over the consume directory, automatically adding new files when you add them. At this point you should take a moment and get acquainted with paperless itself. If you've ever seen a Django admin interface, this will feel very familiar, because that's exactly what it is. That does feel a bit hacky, but it seems to work good enough. You might also want to have a look at [this electron desktop app](https://github.com/thomasbrueggemann/paperless-desktop) which uses paperless' API to show all scanned documents in a prettier fashion. Unfortunately it seems to only run on macOS at the moment and it is an alpha, but it's definitely a great start! It also allows drag and drop of PDF files to upload them.

![paperless desktop](https://camo.githubusercontent.com/faee244b57e1b91b7d613952faa3cc9923347ad1/687474703a2f2f692e696d6775722e636f6d2f467267417074452e706e67)

The current setup might now already work out great for you, depending on how you scan files and are able to upload files to the consume directory. I'm very used to using a scanning app on my mobile device though, specifically [Scanbot](https://scanbot.io/en/index.html). Scanbot has the great feature of letting you upload finished scans to a service of your choice, including FTP and WebDAV shares. This seemed like a great choice to push scans directly to my server. I don't have an FTP server running (and don't want to), but WebDAV is a core feature of [Nextcloud](https://nextcloud.com). And I do have a Nextcloud instance on my server as well.

What I ended up with is the Nextcloud docker container having the consume directory mounted. Then I enabled the fantastic Nextcloud app allowing external storage, added said directory directly to Nextcloud and then configured Scanbot to upload scans via WebDAV directly to the paperless consume directory. An added bonus is that the Nextcloud desktop client also syncs the consume directory to my computer, so I also have a directory there where I can drop PDF files to be added to paperless 👌

Everything now works rather seamlessly and I have better control of my files than with Evernote. The only thing missing would be a dedicated mobile app to search for scans. Maybe I'll have a go at that 😊
