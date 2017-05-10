+++
date = "2016-03-07T02:19:48+02:00"
title = "Cheap DynDNS Alternative"
slug = "cheap dyndns alternative"
+++

Until recently I had the pleasure of living with a static IP. This made accessing my Raspberry PI from outside my home rather easy. I could just open the port on my router and hardcode the IP anywhere.

After moving though easy access like that unfortunately fell away. I looked into some services like DynDNS but found them cumbersome and hard to work with. A simple solution to this “problem” presented itself via CloudFlare. Why not just get my current IP every $TIME_INTERVAL or so and send that to CloudFlare via their API updating an existing DNS record.

Here’s a simple ruby script for just that.

```ruby
#! /usr/bin/env ruby

require 'net/http'
require 'cloudflare'

# Email used for login
CLOUDFLARE_EMAIL = ENV["CLOUDFLARE_EMAIL"]

# API Key, can be found here => https://www.cloudflare.com/a/account/my-account
CLOUDFLARE_API_KEY = ENV["CLOUDFLARE_API_KEY"]

# The zone (aka domain) this is for, e.g. 'example.com'
CLOUDFLARE_ZONE = ENV["CLOUDFLARE_ZONE"]

# The specific record name to edit, e.g. 'record.example.com'
CLOUDFLARE_RECORD_NAME = ENV["CLOUDFLARE_RECORD_NAME"]

def get_ip
  Net::HTTP.get(URI.parse('http://canihazip.com/s'))
end

def update_cloudflare(ip)
  cf = CloudFlare::connection(CLOUDFLARE_API_KEY, CLOUDFLARE_EMAIL)
  begin
    rec_id = ''
    records = cf.rec_load_all(CLOUDFLARE_ZONE)
    records['response']['recs']['objs'].each do |record|
      if record['name'] == CLOUDFLARE_RECORD_NAME
        rec_id = record['rec_id']
        break
      end
    end
    # Sending '1' for the TTL = 'automatic' meaning approx. 300 (5 minutes)
    cf.rec_edit(CLOUDFLARE_ZONE, 'A', rec_id, CLOUDFLARE_RECORD_NAME, ip, 1)
  rescue => e
    puts e.message
  else
    puts "Successfully updated A record for #{CLOUDFLARE_RECORD_NAME} to #{ip}"
  end
end

update_cloudflare(get_ip)
```

The script relies on two things to work correctly:

 - Make sure to set the record to be updated beforehand, this script will look at all records and update the IP of the correct one.
 - You need to pass a few environment variables as specified at the top of the script, namely `CLOUDFLARE_EMAIL`, `CLOUDFLARE_API_KEY`, `CLOUDFLARE_ZONE` and `CLOUDFLARE_RECORD_NAME`.

Now just periodically run it via cron or however you like 🙂

Setting up the record beforehand also gives you the freedom of specifying if you want CloudFlare tunneling for the record or not. Whatever you set will not be changed by this script.

**UPDATE**: Thanks to [@stefanmajewsky](https://twitter.com/stefanmajewsky) [here](https://github.com/jasontbradshaw/gandi-dyndns)’s a Python script for doing the same directly via Gandi.net. Awesome!
