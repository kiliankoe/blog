+++
date = "2017-05-30T12:30:38+02:00"
slug = "reverse-engineering-ios"
title = "Reverse Engineering iOS Apps"
+++

<iframe width="100%" height="500" src="https://www.youtube-nocookie.com/embed/lArXWiVWImk?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>

As promised in my [last post](/itunes-mitm) I wanted to write a post about a talk I recently held at [Mobile Camp 2017](https://mobilecamp.de). I also held the talk again at our local Cocoaheads Meetup on May 24th 2017, this time being recorded on video (Thanks, [Ben](https://twitter.com/benchr)!). But since the talk is in German, I promised to publish an English summary here as well, so here we go 😊

The slides are online as well and can be found on [GitHub Pages](https://git.io/reverse-ios). I've linked to most things as well, everything in orange is clickable 😉

## What is Reverse Engineering?

According to [Wikipedia](https://en.wikipedia.org/wiki/Reverse_engineering):

> Reverse engineering, also called back engineering, is the processes of extracting knowledge or design information from anything man-made and re-producing it or re-producing anything based on the extracted information. The process often involves disassembling something (a mechanical device, electronic component, computer program, or biological, chemical, or organic matter) and analyzing its components and workings in detail.

That's exactly what we're going to do. We have an app that we didn't write ourselves and want to find out what it's *doing* under the hood. Maybe we're interested in how a certain behavior is built. Or we want to have a look at how the API the app talks to works or what kind of data is being sent to it (perhaps a little too much?). Or we might even be interested in finding out why a certain bug may be occuring.

Whatever our intent, there's a few things we can do to achieve this.

## Inside an App

There's a few things to find in an app. Obviously we have the app itself, meaning some kind of executable and possibly a list of frameworks. Additionally there's some metadata, which in the iOS world mostly comes down to the info.plist. I'd add NSUserDefaults to this as well, although they're not really included within the app, but stored elsewhere. But especially on macOS this is highly interesting, as a lot of apps offer a lot more customization than seemingly possible via their GUI. And finally we also have assets, e.g. bundled images, videos, sounds, fonts, strings and whatever else.

## What's Possible

I'm going to split this up into two cases, one being while the app is running and the other while it isn't.

If the app is running we can on one hand start monitoring the network and intercept everything the app sends and receives. This is where we can figure out how an API the app might be talking to is working. On the other hand we can try and inject code into the app and bend it to our will.

When not having a running app at our disposal we can open it up and see what kind of stuff is lying around in the bundle. We can also dump the binary to gain a lot more insight into what kind of code the app is actually running behind the scenes.

## Intercepting Network Calls

For this we're going to be using a fantastic tool called [Charles](https://www.charlesproxy.com), but there are also [alternatives](https://mitmproxy.org).

There are [plenty](http://codewithchris.com/tutorial-using-charles-proxy-with-your-ios-development-and-http-debugging/) of [tutorials](https://www.facebot.org/charles-basics/) for this online, so I'm not going to go through this step by step.

The idea is that we can use Charles to intercept anything an app sends to _the internet_ and receives from said _internet_. Charles has a pretty nifty feature called breakpoints that let us stop on both events and modify the request and response contents inline.
It becomes a bit trickier if the app is using transport encryption, which any sane app should at the very least be doing. If there are no additional measures like certificate pinning at play though we can just tell Charles to use its SSL proxying mode to use our own SSL certificate instead of the original. That way we can just as well listen in on any encrypted requests.

As mentioned though if the app pins to a specific certificate (meaning their app is expecting a specific one, not just _any_ SSL certificate), we're kinda stuck here. **And cert pinning is definitely something any app handling sensitive information should be looking in to if not already doing. Man-in-the-middle attacks are commonplace and it's always a good idea to protect your users. There's more than your reputation at stake 😉**

## The Bundle

Apps usually bundle more than just their executable. So why not have a look, even if it's just to satisfy our curiosity.

Go ahead and download whatever app you're interested in via iTunes. If you're looking for a specific (older) version, check out my [last post](/itunes-mitm) on how to do just that. Right click the app in iTunes and select "Show in Finder". Here we can just rename the .ipa file to end in .zip and unpack it. Then we can have a look inside \o/ (Right click an .app and select "Show package contents" to open it).

For most apps there's not all too much we can discover here. You'll most likely be seeing icons and maybe some other media files. Possibly fonts and sounds as well. Obviously depends on the app.

The two apps I looked into in my talk were both related to public transport in Dresden, 'cause I love myself some good public transport data. The first one, [Fahrinfo Dresden](https://itunes.apple.com/us/app/fahrinfo-dresden/id314790387?mt=8) bundles an SQLite db containing a list of all stops in Dresden (for autocompletion) including their coordinates. This was definitely a cool resource to stumble across (especially since these coordinates were somewhat hard to gather elsewhere).

The second app, [DVB mobil](https://itunes.apple.com/us/app/dvb-mobil/id1174905421?mt=8), is the official app our public transport provider publishes. As you might be able to tell by using the app and the performance that shows, this app is not a native app, but also I'd love to very much, this isn't the place to argue about that... The app is built with [Ionic](http://ionicframework.com) (previously known as Cordova - more or less), which means the core logic and pretty much everything is written in JavaScript and not compiled into a native binary. Interestingly enough this means that we're going to be running across the actual source of the app in the bundle. Unfortunately though the app doesn't do all that much that's very interesting to look at, but it's definitely cool to poke around a bit.

## Code Injection

This was the coolest part of the talk in my mind at least. Unfortunately it requires your device to be jailbroken. But once you've stepped past that hurdle, the fun begins.

We're going to be using a fantastic tool called [cycript](http://www.cycript.org) to basically give us a live REPL into an app of our choice. This is suprisingly easy to do and surprisingly powerful as well.

For the talk I ran an app called Jodel, which, if you're unfamiliar with it, is basically a German equivalent of YikYak. I ran the app on my jailbroken iPhone 4 (running a rather old iOS 7.1.2, but that shouldn't be an issue here) and to then get up and running we just have to SSH into our iPhone and run the following.

```bash
$ cycript -p Jodel
```

The `-p` flag tells cycript to look through all running processes and find the one with the given name. Cycript will now present us with a prompt where we can use its mix of JS and Objective-C to do whatever we want.

One way of getting started is having a look at the current recursive description of the view hierarchy for example.

```javascript
#> UIApp.keyWindow.recursiveDescription.toString()
```

Cycript has a pretty nice way of accessing anything you know a the memory address of.

```javascript
#> var table = new Instance(0xDEADBEEF) // use an actual memory address, duh :P
```

I used this to get a handle to the `JDLLoadingTableView` I found in the recursive description above, which is the main table view showing all "jodels". Then I wanted to find the top-most cell and see if I can change its displayed text and vote count.

```javascript
#> var idx = [NSIndexPath indexPathForRow: 0 inSection: 0]
#> var cell = [table cellForRowAtIndexPath: idx]
#> cell.hidden = YES // this worked, so we have a reference to the correct cell
#> cell.hidden = NO
#> cell.recursiveDescription.toString() // we see there's a `contentLabel`
#> cell.contentLabel.text = "foobar" // yay, it works \o/
#> cell.voteCountLabel.text = "156" // works as well :)
```

Obviously this only changes the display of things though. Once we send an upvote or trigger a refresh in any other way, our changes are obviously going to be reset. For trying to get around that it would make sense to see if we can change things directly in the models the app stores internally, but that's something for another rainy day 😊

Another way of accessing any running instance of whatever class in cycript is the `choose` function. You just provide it with a name and it hands you all instances of that class it currently finds. And since Jodel uses Fabric, we can just do the following.

```javascript
#> var crashlytics = choose(CLSAnalyticsController)
#> [crash[0] fabricAPIKey]
```

It's also worth noting at this point that cycript is a fantastic way of getting around that pesky certificate pinning mentioned previously, since we can just go ahead and disable that if it's getting in our way. It's especially easy if the app is using a framework like `AFNetworking`, where we can just set the `SSLPinningMode` to `None`.

If you're a developer you might want to think about this. Anything you do on a user's device is something the user can influence. If your app is talking directly to several third-party services and authenticating itself to them, the user of your app will probably be able to find out your API keys (or similar). It might be worth putting something like that behind your own API, so that you can play somewhat of a gatekeeper for most stuff at least. Also please make sure that you're not throwing around sensitive information everywhere. Anything your app can access is something cycript (or similar and/or more malicious tools) can access. Anything that's just lying around unencrypted and way beyond its lifetime is something that will be read by someone unauthorized. It's a _terrible_ idea to store passwords in NSUserDefaults for example. But it's maybe not quite as obvious that things like encryption keys should not be stored in memory indefinitely either, but just when you need them. It's worth talking to someone with a bit more experience regarding this stuff if you want to take it seriously.

## Dumping the Binary

To find out more of what kind of data an app stores and what it's _really_ doing we're going to have to decrypt the actual executable, arguably the most _involved_ part of this post, but it's actually rather straight-forward in acomplishing. The "hard" part lies in interpreting the results.

First off we're going to want to find the location of the app on our device so that we can tell dumpdecrypted where to look. I'm using a [fork of dumpdecrypted](https://github.com/conradev/dumpdecrypted) which also dumps all frameworks, which can come in handy.

```bash
$ find /var/mobile/Applications/ -name 'Jodel'
$ DYLD_INSERT_LIBRARIES=dumpdecrypted.dylib /var/mobile/Applications/[...]/Jodel.app/Jodel # [...] is a placeholder for the app's ID :P
```

After doing so we'll see a Jodel.encrypted file lying around. This we can now pull over to our Mac and throw into a tool like [Hopper](https://www.hopperapp.com) (there's a free trial, which is rather neat) where can look at pretty much everything and try to see what happens where and how by looking at the generated pseudo-code (awesome feature!) or we can dump the encrypted file using [class-dump](https://github.com/nygard/class-dump) into a header listing everything that exists. This is useful if you already have a faint idea of what you're looking for. In my case this was to find out some stuff about how Jodel generates the HMAC it uses to "sign" every request making it harder to tamper with their API 😉 Props to them for doing it this way by the way!

```bash
$ class-dump Jodel.decrypted > Jodel.h
```

By the way, there's the [iOS-Runtime-Headers](https://github.com/nst/iOS-Runtime-Headers) repo on GitHub which lists header info on all (including private) frameworks in iOS. It's regularly updated when new versions of iOS emerge. Apple has followed the practice of adding frameworks as private variants before publicizing them in future versions, so it's neat to see hints to some upcoming stuff before it actually gets announced at WWDC 😊

Soooo, that more or less brings us to the end of the talk. Thanks for being there, having a look at the video recording or reading this post. You're awesome! I hope that at least some of the information gathered here was of use to you, I definitely learned some stuff when putting it all together. Cheers!

## TL;DR

If your code is running on somebody else's device, they can do whatever they want with it. And there's not really anything you can do to stop that. Make sure to think about this when building your app, but don't worry about it all too much, it's normal 😜
