+++
date = "2017-05-10T15:04:18+02:00"
slug = "itunes-mitm"
title = "Downloading older iOS app versions with iTunes"
+++

I recently held a talk about reverse engineering iOS apps at [Mobile Camp 2017](https://mobilecamp.de). There will be another post about said talk soon, since I'll be holding it again at our local Cocoaheads meetup in a few days, this time with a video recording 😊.

One of my topics was taking a look into an app's bundle, for which I had an app in mind that bundled an interesting SQLite database[^1]. I remembered stumbling across this a little while ago and thought it'd be something nice and small to show. On redownloading the current version of the app I noticed that the SQLite db was still there, but now encrypted 😿. Not wanting to look around for something else to demo I chose to force iTunes to just download an older version of the app instead. Doing so turned out to be rather easy if you're at least somewhat familiar with *man-in-the-middle* attacking yourself, something I also went over in my talk.

I'm using a tool called [Charles](https://www.charlesproxy.com) for this. I can also recommend the very popular [mitmproxy](https://mitmproxy.org). The idea is the same for both of them, but I'll reference Charles here.

Run your tool of choice and start iTunes. Search for the app you want and click download. Since you don't want the current version you can cancel the download right after that. Now check Charles for a request to `*-buy.itunes.apple.com`. Since this request is TLS encrypted we're going to enable Charles' SSL Proxying (right-click the request and do so). Let iTunes re-send the request by starting the download again (we still just need it to start, not actually finish downloading). Charles should now show the request in it's unencrypted form.

If you view the server's response you'll see a plist file (Apple's XML based "property list" file format). You're looking for a section that looks like the following.

```xml
<key>softwareVersionExternalIdentifiers</key>
<array>
<integer>813164182</integer>
<integer>813305098</integer>
<integer>814184616</integer>
<integer>814214406</integer>
<integer>814369260</integer>
<integer>814850256</integer>
<integer>817722935</integer>
</array>
```

This is a list of all versions of the app (or more precisely their IDs), starting with the oldest. Obviously your IDs will most likely differ.
<!--Unfortunately these version IDs aren't directly convertible to the version string used by the app. You're going to have to guess. For my case this was fine, since I just needed *any* old version. Otherwise you can of course just try a few times and see if you can find a specific one you're looking for.-->
Unfortunately there's no direct way to correlate all of these version identifiers with the app's actual version strings. Apple's servers only tell you the version string when requesting one of these specifically, but more on that in a pinch.

Go ahead and copy an ID. Now check the request tab of that same request. You should be able to find a section that specifies which version iTunes wants to download.

```xml
<key>appExtVrsId</key>
<string>822037669</string>
```

The easiest way in Charles is to now set a breakpoint on this request (right-click → Breakpoints). Restart the download in iTunes and Charles will pop up allowing you to edit the request iTunes sends to Apple before it goes through. This is where you can now insert your copied ID as the value for the just mentioned `appExtVrsId` field. After clicking "Execute" Charles will also stop the incoming response before allowing iTunes to read it. This includes a field named `bundleShortVersionString` which contains the human-readable ID. You can abort the response and try again if this wasn't the app version you're looking for.

<img style="display: block; margin: 0 auto;" src="https://cloud.githubusercontent.com/assets/2625584/25902476/e85fca08-3599-11e7-9643-78d41095f4c1.png" />

If it is a version that works for you, great! That's it 🎉. iTunes is downloading the app as we speak and you can then do whatever you want with it. Be aware that any current versions of the app need to be removed from your device if you want to sync it to one.

[^1]: I'm referring to the app [FahrInfo](https://itunes.apple.com/us/app/fahrinfo-dresden/id314790387?mt=8) for Dresden. The bundled SQLite db contains a list of all public transport stops including their coordinates, which was used by the app for autocompletion. And if you know me, I'm a [sucker](https://github.com/kiliankoe/vvo) for local public transport data.
