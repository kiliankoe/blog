+++
slug = "github-images"
title = "Keeping Static Images out of your GitHub Repo"
date = "2017-04-10T14:12:35+02:00"
draft = true
+++

People love images *[citation needed]*. Or at least I know I do. And I've previously stated elsewhere that I hate downloading or installing software that doesn't show me any obvious references to its visuals beforehand. I mean come on, it's just a  screenshot, how hard can it be? GIFs or videos get bonus ✨ points. This obviously also goes for CLIs, which doesn't mean you should skimp on man pages and/or good `--help` documentation, but a link to a "*video*" powered by [asciinema](https://asciinema.org) speaks volumes compared to a textual description of usage patterns!

A lot of the tools we use and download nowadays are primarily hosted publicly on GitHub, which is why a good README has become the defacto standard homepage for your project. **This** is exactly where your screenshots, GIFs or videos should go. And it's what most people do, which is awesome.

The problem with inline images and GIFs however is that they have to come from *somewhere* and that *somewhere* is usually from within the repo (a `./screenshots` dir for example). Especially for GIFs though this can quickly bloat your repo by several megabytes 😕

The solution is rather simple, just let GitHub host the static assets instead 🤷‍♀️ There's no obvious direct upload form anywhere, but we can just abuse GitHub's hosting of images for issues for this. The process is fairly simple:

1. Open a new issue in a repo of your choice (doesn't matter since it won't be part of the URL and we're not going to actually open the issue).
2. Drag and drop the image into the issue body.
3. Your browser will upload the image to GitHub's static hosting server and you'll be provided with a public link similar to this one: [`https://cloud.githubusercontent.com/assets/2625584/24861665/d962d642-1df9-11e7-9bd5-cb4f02c5d0c1.png`](https://cloud.githubusercontent.com/assets/2625584/24861665/d962d642-1df9-11e7-9bd5-cb4f02c5d0c1.png)
4. Copypasta that link into your project's README and discard the issue 🙌

This is no different than hosting the image somewhere else like imgur, but it just seems logical to let GitHub handle the public remote hosting for the repo including the static assets without forcing them on everybody wanting to clone the repo 👌

Also, I sincerely apologize for a post that's several times longer than it needs to be for a topic so simple 😜
