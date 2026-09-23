# macos-debloat
A small macOS cleanup script I made because I wanted something similar to the Windows debloat tools out there.

It gives you a simple menu where you can remove some Apple apps you don't use, clean up caches, clean Homebrew, check background items, and do a few other basic cleanup tasks.

Nothing fancy. Just some useful stuff in one script.

What it does
Remove optional Apple apps like:
GarageBand
iMovie
Chess
Pages
Numbers
Keynote
Clean user caches
Clean Homebrew
Disable some Siri settings
Check Spotlight
Check Login & Background Items
Clean Xcode DerivedData
Show basic system info
Back up some preferences before making changes
What it doesn't do

I'm not trying to completely tear macOS apart with this.

The script won't:

Disable SIP
Disable Gatekeeper
Mess with /System
Modify the sealed system volume
Delete protected system apps
Remove system frameworks
Randomly disable system services

Basically, if macOS is protecting something for a good reason, I'm leaving it alone.

How to use it

Clone the repo:

git clone https://github.com/YOUR-USERNAME/okyx-macos-debloat.git
cd okyx-macos-debloat

Make the script executable:

chmod +x okyx-macos-debloat.zsh

Run it:

./okyx-macos-debloat.zsh

You'll get a menu and can choose what you want to clean up.

It doesn't just start deleting things as soon as you run it. You choose the option and confirm it first.

Why?

I wanted a quick way to clean up my Mac without installing some random "Mac Cleaner Pro Ultra Premium 2026" that wants $39.99 a year to delete three cache files.

So I made this instead.

It's also something I can keep adding to as I find other useful cleanup tasks.

A few notes

This is mainly made for modern macOS and Apple Silicon Macs, but some things should also work on Intel Macs.

Apple changes things between macOS versions, so there's a chance some options won't do anything on newer versions. That's normal.

If you're not sure what an option does, don't run it. The Mac will survive without being aggressively "optimized."

Disclaimer

Use it at your own risk.

Have a backup of anything important before messing around with system cleanup.

This isn't affiliated with Apple.
