+++
date = "2014-07-21T01:47:19+02:00"
title = "Installing OS X applications through Homebrew"
slug = "brew-cask"
+++

I have to admit to having been slightly jealous of a friend running Arch Linux on his laptop when he went ahead and installed [xmind](http://www.xmind.net/de/) right through his package manager (or actually [yaourt](https://wiki.archlinux.org/index.php/yaourt), but I won't make the distinction here). Now don't get me wrong, there's nothing wrong with installing applications on OS X. It's dead simple.
<p align="center">
  ![drag'n drop](http://i.imgur.com/oHxuD7K.png)
</p>

You download the disk image, double-click it to mount and drag the .app onto your linked Applications directory. But it's so graphical... Any self-respecting *appleleptic* nowadays already has the fantastic [Homebrew](http://brew.sh/) package manager installed on their system anyways, which is awesome stuff, without question. And there is one package I have to admit to not having heard of before a few days ago, even though it has a rather big following which helps us out here.

It's called [Homebrew Cask](http://caskroom.io/) (you just gotta love the naming scheme of things in the Homebrew universe: Brew, Cask, Formula, Tap, etc) and its sole purpose is allowing you to run commands like `brew cask install xmind`. It worries about where to get the latest version from, where to put it, and for a few selected applications also how to specifically uninstall them when you run `brew cask uninstall app-name`. It also doesn't just do apps, but preference panes, quicklook plugins, services, widgets and a few more. It's an allround powertool for installing stuff on your mac that homebrew itself doesn't handle.

### So how do you get it?

Unfortunately cask isn't included in main homebrew repo, but don't despair, that just makes us run one more command.

```
$ brew tap caskroom/cask
$ brew install brew-cask
```

Note: You might find others online referencing to tap phinze/cask instead, which isn't wrong, it's just old. Fortunately GitHub redirects phinze/cask to caskroom/cask, but this might stop working one day, so just go with caskroom/cask and you won't have to worry.

Cask is now installed on your system. It's main working directory is `/usr/local/Library/Taps/caskroom/homebrew-cask`. This is where the git repo resides, which is one of the most awesome facts about homebrew by the way. All of it being just a bunch of ruby scripts and a git repo to manage them. You don't actually need to do anything in this directory though, unless you want to add your own casks, which we'll go over how to do in a sec.

### Using cask

```
$ brew cask update
```

This is basically an alias to `git pull origin master` in the cask repo and updates your list of available casks to the current status. Running this often is key, as new casks are created and others are updated on a daily basis. Run this if you can't find a cask or before installing one if you haven't updated in a little why to ensure you get the newest version of an application.

```
$ brew cask search app-name
```

Want to know if an app you're looking to install is available through cask? Just run this. The naming strategy is pretty straight forward with everything being lowercase and dashes for spaces. Search also finds partial results, so for example this works:

```shell
kilian@Apollo:~$ brew cask search intellij
==> Partial matches
intellij-idea     intellij-idea-ce
```

```
$ brew cask install app-name
```

Installs an app. Simple. It also automatically runs through any zip files, disk images or packages. It'll prompt you if an admin password is needed.
One thing to note is that applications are by default *not* installed to `/Applications`, but to `/opt/homebrew-cask/Caskroom/app-name/version/app-name.app` and then symlinked to `~/Applications`. This is no problem for your mac, but in case you'd like to link it to `/Applications` instead, run the command like this `brew cask install app-name --appdir=/Applications`.

```
$ brew cask uninstall app-name
```

This should be about as self-explanatory as it gets. As I mentioned already however this doesn't just remove the application from your system, but for a few special apps that require their own uninstaller to be run, this is done instead.

```
$ brew cask list
```

Lists all your installed casks. If you run it together with an application name it'll tell you which files are installed and where they reside.

```
$ brew cask cleanup
```

Cleans up downloaded files which are usually not removed after installing an application. Might free you up quite a bit of space on your harddrive.

```
$ brew cask home app-name
```

Takes you to the homepage of an application. Be it the developer's site, a GitHub repo or whatnot.

And last but not least, an essential one if you're an [Alfred](http://www.alfredapp.com/)-junkie like me:

```
$ brew cask alfred link
```

This adds the install directory to Alfred's search path so you can find your installed applications with Alfred.

That's actually all there is to using cask. It's a fantastic little application and the list of applications it can install is [pretty damn huge](https://github.com/caskroom/homebrew-cask/tree/master/Casks) (1.723 entries as of now).

There are however two other points I'd like to go over.

### Using Brewfiles

Homebrew includes the wonderful functionality of being able to run a number of commands from a file you specify. This is typically called a Brewfile, but you can name it whatever you want.

This of course finds it main purpose in installing a few packages together and *bundle* them together.

Using this is extremely simple, here's a [Brewfile](https://github.com/kiliankoe/dotfiles/blob/master/Brewfile) I set up so I can quickly install all the applications I use regularly on my system if I have to start from scratch (new machine, dead harddrive or ritual cleansing, who knows).

As you can see it just includes a command on each line without the `brew` command itself.

```
...
install node
install ffmpeg
...
# set up brew cask
tap caskroom/cask
install brew-cask
...
# cleanup
cask alfred link
cleanup
cask cleanup
...
```

Lines starting with a `#` are comments and will be ignored by homebrew.

Use the command `brew bundle filename` to let brew run through it. Already installed packages and applications will not be overwritten.

### Creating your own casks

So you found something that's not yet available through cask and want to become one of the 743 current contributors? That's awesome! And it's really quite simple as well. All you need is some basic knowledge how to use git and you're set. Let's take a look.

Let's start by setting up your fork on GitHub. Visit the [official repo](https://github.com/caskroom/homebrew-cask) of cask on GitHub and click on the fork button in the upper right-hand corner. Wait a few seconds and GitHub will create a clone of the repo under your account. We'll use this to change what we want and send a pull request back to main repo.

Now open up a terminal and navigate to the cask repo on your harddrive.

```
$ cd /usr/local/Library/Taps/caskroom/homebrew-cask
```

Let's branch off into a feature branch to add the new cask.
```
$ git branch add-app-name
$ git checkout add-app-name
```

Now we can create the cask by running

```
$ brew cask create app-name
```

Please check the [naming details](https://github.com/caskroom/homebrew-cask/blob/master/CONTRIBUTING.md#cask-naming-details) before naming your cask. The rest of the contributing guide contains all the following details as well, but I'm going to go through them anyways.

This should immediately open up your default editor where you can go ahead and fill out the details like version number, [hash](http://notepad2.blogspot.de/2012/07/mac-os-x-how-to-generate-md5-sha1.html) of the download, link to the download, homepage and name of the to be linked file. After saving this you can already go ahead and try it out by installing it yourself. Use `brew cask edit app-name` to quickly jump back to editing the file again. If you're sure everything works also run `brew cask audit app-name --download` for some additional checks.

Time to commit. Add your cask and commit it with a sensible message containing the name and version number.

```
$ git add Casks/app-name.rb
$ git commit -m 'Add app-name v0.1'
```

Now let's add our fork as a remote so we can push the changes to GitHub with one of the following two commands depending on if you interact with GitHub over SSH (second command) or not (first one).

```
$ git remote add fork https://github.com/your-username/homebrew-cask.git
$ git remote add fork git@github.com:your-username/homebrew-cask.git
```

And push it.

```
$ git push fork add-app-name -u
```

You can now visit the [main cask repo](https://github.com/caskroom/homebrew-cask) where a green button to submit your pull request should be greeting you. Click that, check the changed files just to be sure you did what you wanted and submit it. The repo is very active and presuming everything is awesome it shouldn't be long for it to be merged.

Just don't forget to switch back to the master branch in your local cask repo, otherwise you won't be getting future updates ;)

```
$ git checkout master
```

You can also delete your local feature branch if everything is done.

```
$ git branch -d add-app-name
```

You're now officially a contributer to cask, awesome stuff.

This also concludes this post. I hope it was interesting enough and you find cask to be just as useful as many others and I do.
