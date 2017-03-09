+++
date = "2016-11-09T13:43:52+01:00"
title = "Automatically Increment Your Xcode Project's Build Number"
slug = "xcode-buildnumber"
+++

Those of us who use Xcode to build, run and deploy projects of ours have probably run into an issue where we've forgotten to increment the build number before trying to deploy a project.
In my case the problem is usually iTunes Connect, which doesn't take your app's version (or `CFBundleShortVersionString`) into account, but only the build number (or `CFBundleVersion`). The former is the version we usually set (according to [semver](http://semver.org) if you're a good person, although it really doesn't make much of a difference for user-facing versions) to identify the version internally.
If you fail to increment the latter before uploading, iTunes Connect doesn't see this as a new version, which stinks.

A first idea might be having a build phase which just increments that number every time you hit build. The obvious downside being that you're either going to be committing increments of this number and fixing conflicts on merges or running into outdated build numbers if you have multiple people deploying your app. That's no fun.

The best solution I've come across is coupling your build number to the commit count of your project's git repo. This leads to reproducible build numbers also allowing you to track the state of the app (presuming no uncommited changes were present during archival) based on the build. It doesn't however solve the issue we had with automatically incremented build numbers before, so what if we also reset the build number back to a default value right after we finish compiling? That way our build gets its nice identifying build number and we have no build number changes to commit. Sweet.

All we need for that are two run script build phases. One before near the top setting our *generated* build number and one near the bottom resetting it (before and after `Copy Bundle Resources` should probably suffice).

For the first one, add the following.

```bash
buildNumber=$(git rev-list HEAD | wc -l | tr -d ' ')
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"
```

Here we're utilizing `git rev-list` to list out all parent commits of the current state, piping that through `wc` to count the number of lines and removing leading whitespace with `tr`. This results in our build number that we set using `plistbuddy`.

The second script is rather similar.

```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion DEV" "${PROJECT_DIR}/${INFOPLIST_FILE}"
```

Same idea, just a hardcoded string `DEV` instead of a number of commits.

Hopefully this method will save you just that teeny amount of time updating your build number in the future 🙂
