+++
date = "2013-11-05T20:50:33+02:00"
title = "Launching Alfred with Caps Lock on OS X"
slug = "alfred-caps-lock"
+++

In great contrast to [Alfred](http://www.alfredapp.com/) being one of those apps I love more than anything on OS X, the caps lock key is something utterly useless nowadays (or ever for that matter). And if you do happen to find yourself in an argument on the internet, even [Homer Simpson agrees](http://www.youtube.com/watch?v=xznylVUyND0) that you put a lot more weight into your statement if you take your time to press the shift key. The already mentioned Alfred however is so immensely useful, that even two keys for its hotkey (the default `alt` + `space`) is too much. So why not combine the two and have a dedicated *launch everything and search for stuff anywhere* key on your keyboard?

So let's go ahead and set that up.

### Step 1 - Install Seil

The very cool Takayama Fumihiko ([@tekezo](https://twitter.com/tekezo)) wrote a great little tool dedicated to changing the behavior of the caps lock key (and some others for that matter) on Macs. Check out his site and [download it](https://pqrs.org/osx/karabiner/seil.html.en). And yes, this app works just fine with OS X 10.9 Mavericks and should also already support 10.10 Yosemite. Note: Before a few versions ago Seil was known as PCKeyboardHack.

### Step 2 - Getting the relevant key code

You could waste some time looking up the key code for the caps lock key, or you could download this nifty [little app](http://manytricks.com/keycodes/) to check it quickly.

For me it was **103**, but I don't want to guarantee that it'll be the same for you.

### Step 3 - Mapping the functionality

Unfortunately the caps lock key is a bit special. It isn't really registered by the system as a normal key like pretty much anything else, so we're going to have to map it to something. The F-keys on your keyboard are pretty useful for that, so just choose one of those, as long as you're not using it for anything else. It doesn't matter if it's a media key, if no function on your machine is set to happen when you press `fn` + `FX` (I'm using `F11`), this would work.

If you're not sure about this, check your System Preferences > Keyboard > Keyboard Shortcuts. Any functionality would be listed there.

Open Key Codes, hold `fn` if necessary and press your key. Aside from all the other information that should now be displayed, remember the key code.

Now open up PCKeyboardHack, check the *Change Caps Lock* option and set it to the key code we just looked up.

### Step 4 - Alfred

All that's left is changing Alfred's preferences. In the General tab, you'll see the Alfred Hotkey option. Set this to the F-key you chose earlier, remember to hold `fn` if you're on an Apple keyboard.

### Step 5 - Disable caps lock

This step really isn't necessary for this to already be working, try it out!

Something that seemed to be bothering me, is that Macs have a built-in feature to protect you from accidentally activating caps lock in every day use. This is a short delay when activating it (not deactivating, just activating), so when you press the key fast enough, nothing will happen. The only way to get around this is disabling caps lock itself, but that's not really a problem since we're not using it for its actual function anyways.

The option for this is in the System Preferences > Keyboard > Modifier Keys. Set caps lock to *No Action* here. That should do the trick. And now have fun!

By the way:
the famous [CR-48 Chromebooks](http://en.wikipedia.org/wiki/Chromebook) also had a dedicated search key instead of caps lock. I was jealous from the start, but this fixed it :)
