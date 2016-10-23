+++
title = "Writing Custom Alfred Worklows"
slug = "alfred workflows"
date = "2016-10-23T12:42:16+02:00"
+++

A [friend of mine](https://twitter.com/BenchR) has recently started automating some of his tasks using Alfred workflows, a feature of Alfred I've been using for years, but have never really thought about using for my own stuff before.

Although they can sometimes come across rather gimicky, Alfred workflows are actually quite powerful. There's a huge amount of possibilities built right in, but in this post I really only want to focus on a short introduction to so called *script filters*.

*Please be aware that workflows are a paid [powerpack](https://www.alfredapp.com/powerpack/) feature of Alfred. I can definitely recommend the upgrade though!*

## What's a *Script Filter*?

On creating a new blank workflow you're presented with an empty page. Here you can add a bunch of stuff, but the most straight-forward thing (in my opinion at least) is a script filter.
<p align="center">
  ![](/img/alfredworkflows_1.png)
</p>

Script filters are input actions, meaning they can be run on certain keywords and with certain arguments. The argument can then be passed on to a given script (hence the name), which does some 🎩🐰✨ and returns some items for Alfred to display.

Alfred has a list of supported default "languages", including bash or zsh, php, ruby, python, perl and applescript. Or you can just choose "External script" and go with whatever you want.

**Caveat**: If you're looking to distribute your workflow to others, it might make sense to go with something that they can run natively without having to install additional dependencies. My first workflow was written in Node.js, which unfortunately doesn't come preinstalled on macOS. And then one of the users had an older version running into all kinds of additional errors. On the other hand, if you're writing a wrapper for npm tooling, node will probably be on your user's machines and the language is their tool of choice anyways. It's always a question of your target audience.

What's also noteworthy here is the "Run Behaviour". Alfred defaults to running one instance of your script after each other. That means that if an instance is already running (maybe being rather slow due to a network call or something else), any further user input will only be processed after the first script has finished and a new instance can be started.
My experience has been that this can easily be changed to terminate the previous instance if the users adds additional input for most cases, making things a lot snappier.

## Getting Started with a Script Filter

A user's input is handed over to your script as argv by default, making it trivial to access this with your language of choosing.

To show a list of items in Alfred once you're done you have to do nothing more than output some JSON (or XML) to STDOUT.
Alfred has [pretty good documentation](https://www.alfredapp.com/help/workflows/inputs/script-filter/json/) on how your outputted data has to be formatted for Alfred to pick it up.

The basic idea is having a list of items with their respective fields. Most of them are pretty self-explanatory or well explained in the docs linked above.

```javascript
{"items": [
    {
        "title": "An item",
        "subtitle": "Some description ",
        "arg": "an argument",
        "icon": {
            "path": "link to an image"
        }
    },
    //...
]}
```

Setting an argument is especially helpful for other actions, as this is what is passed on to them. You can also specify different arguments for modifier keys, so a different actions will be passed on if the user holds ⌘ for example.

Alfred also does a lot for you out-of-the-box if you want to list files from your harddrive.

## Using a Helper Library

You'll make your life a lot easier using one of the plentiful alfred-workflow helper libraries out there, surely also for your language of choice.

Two I'd like to highlight are [Alfy](https://github.com/sindresorhus/alfy) by Sindre Sorhus (Javascript) and [goalfred](https://github.com/BenchR267/goalfred) by Benjamin Herzog (golang).
Both have a fantastic API making your life a lot easier by just passing along the items and setting appropriate attributes.

Something specific to goalfred are the so called complex arguments. It turns out to be rather tricky if you want to pass along specific variables to further actions. Ben and I figured that out together as I was trying to build a workflow showing departures in our local public transport network (DVB in Dresden, Germany).

<p align="center">
<iframe src='https://gfycat.com/ifr/CluelessSaneAtlasmoth' frameborder='0' scrolling='no' width='640' height='377' allowfullscreen></iframe>
</p>

When hitting enter on an item I wanted to schedule a notification to be displayed several minutes before the departure. My first implementation included a small Swift app using system APIs to schedule that as it turns out you can't schedule future notifications via applescript 😕
We later figured out how to implement the same functionality directly within the workflow getting rid of the rather cumbersome and awkward first implementation. Ben went ahead and built that directly into goalfred 🙂 A big recommendation goes out to that library.

Using that we can easily throw together a small (albeit useless) workflow script in go greeting the name the user enters or no one if no input is given.

```go
package main

import (
    "fmt"

    "github.com/BenchR267/goalfred"
)

func main() {
    // Deals with the normalizing issue below.
    query, _ := goalfred.NormalizedArguments()

    defer goalfred.Print()

    if query[0] == "" {
        goalfred.Add(goalfred.Item{
            Title: "Hello world!",
        })
    } else {
        goalfred.Add(goalfred.Item{
            Title: fmt.Sprintf("Hello, %s 👋", query[0]),
        })
    }
}
```

I would usually compile this running `go build <file>.go` and setting Alfred to run the binary as an external script, but you can also use a bash script filter to have Alfred run `go run <file>.go` or the binary, whatever you prefer.

## Problems

A pain point specific to non-ascii-compatible languages is Alfred's handling of special characters. It uses NSTask internally, which results in umlauts for example being split up into their parts before being passed on, meaning `ü` becomes `¨u`. [Here](http://www.alfredforum.com/topic/2015-encoding-issue/)'s some more info on that if you're interested and some help on how to re-normalize the user's input.

Something essential I haven't found a good solution for are workflow updates. Some people publish their workflows using [Packal](http://www.packal.org), which provides some help with that. There's also a python lib with some magic.
The best solution I've seen this far is how Alfy recommends publishing workflows on npm and linking them to the correct directory on a post-install step. Still not perfect, but definitely interesting.

---

If you want to check out the source to some workflows, I've published three of mine on GitHub: [alfred dvb](https://github.com/kiliankoe/alfred_dvb), [alfred mensa](https://github.com/kiliankoe/alfred_mensa) and [alfred n26](https://github.com/kiliankoe/alfred_n26).

Got any additional input or cool workflow ideas? Hit me up on Twitter 🙃
