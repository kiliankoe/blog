+++
date = "2016-03-07T02:19:48+02:00"
title = "Cheap DynDNS Alternative"
slug = "cheap dyndns alternative"
+++

Until recently I had the pleasure of living with a static IP. This made accessing my Raspberry PI from outside my home rather easy. I could just open the port on my router and hardcode the IP anywhere.

After moving though easy access like that unfortunately fell away. I looked into some services like DynDNS but found them cumbersome and hard to work with. A simple solution to this “problem” presented itself via CloudFlare. Why not just get my current IP every $TIME_INTERVAL or so and send that to CloudFlare via their API updating an existing DNS record.

Here’s a simple ruby script for just that.

<script src="https://gist.github.com/kiliankoe/268c13efa87c510bf8ad.js"></script>

The script relies on two things to work correctly:

 - Make sure to set the record to be updated beforehand, this script will look at all records and update the IP of the correct one.
 - You need to pass a few environment variables as specified at the top of the script, namely `CLOUDFLARE_EMAIL`, `CLOUDFLARE_API_KEY`, `CLOUDFLARE_ZONE` and `CLOUDFLARE_RECORD_NAME`.

Now just periodically run it via cron or however you like 🙂

Setting up the record beforehand also gives you the freedom of specifying if you want CloudFlare tunneling for the record or not. Whatever you set will not be changed by this script.

**UPDATE**: Thanks to [@stefanmajewsky](https://twitter.com/stefanmajewsky) [here](https://github.com/jasontbradshaw/gandi-dyndns)’s a Python script for doing the same directly via Gandi.net. Awesome!
