# idleSound

Automatically mutes your Mac when it goes idle or the screen locks, so notification sounds and stray audio don't keep playing while you're away.

A lightweight menu bar app — no dock icon, no window to manage.

## Features

- Mutes after a configurable idle timeout (off, 5, 15, 30, or 60 minutes)
- Mutes when the screen locks or the screensaver starts
- Both triggers can be toggled independently, right from the menu bar

## Download

Grab a build from [Releases](https://github.com/hashier/idleSound/releases), or clone and build it yourself in Xcode.

## Screenshot

![Screenshot](https://raw.github.com/hashier/idleSound/master/images/Screenshot.png)

## Known limitation

Doesn't play well with [Caffeine](https://intelliscapesolutions.com/apps/caffeine) — Caffeine fakes user activity instead of registering with the system's idle hooks, so idleSound never sees the Mac as idle while it's running. [Amphetamine](https://geo.itunes.apple.com/app/amphetamine/id937984704?mt=12&at=11l4L8) and [iCanSleep](http://www.koboldtouch.com/display/ICS/iCanSleep+-+Prevent+your+Mac+from+Sleeping) use real system hooks instead and don't have this problem.

## License

GNU General Public License v3.
