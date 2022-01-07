# [ztratify/dotfiles](https://github.com/ztratify/dotfiles) < forked from [holman/dotfiles](https://github.com/holman/dotfiles) 📎

> ## _holman does dotfiles_
> 
> _Your dotfiles are how you personalize your system. These are mine._
> 
> _I was a little tired of having long alias files and everything strewn about_
> _(which is extremely common on other dotfiles projects, too). That led to this_
> _project being much more topic-centric. I realized I could split a lot of things_
> _up into the main areas I used (Ruby, git, system libraries, and so on), so I_
> _structured the project accordingly._
> 
> _If you're interested in the philosophy behind why projects like these are_
> _awesome, you might want to [read my post on the subject](http://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/)._

## Topical 🎩

Everything's built around topic areas. If you're adding a new area to your
forked dotfiles — say, "Java" — you can simply add a `java` directory and put
files in there. Anything with an extension of `.zsh` will get automatically
included into your shell. Anything with an extension of `.symlink` will get
symlinked without extension into `$HOME` when you run `script/bootstrap`.

## What's inside? 👀

A lot of stuff. Seriously, a lot of stuff. Check them out in the file browser
above and see what components may mesh up with you.
[Fork it](https://github.com/holman/dotfiles/fork), remove what you don't
use, and build on what you do use.

## Components 🏗️

There's a few special files in the hierarchy.

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **\*/\*.zsh**: Any files ending in `.zsh` get loaded into your
  environment.
- **\*/path.zsh**: Any file named `path.zsh` is loaded first and is
  expected to setup `$PATH` or similar.
- **\*/completion.zsh**: Any file named `completion.zsh` is loaded
  last and is expected to setup autocomplete.
- **\*/install.sh**: Any file named `install.sh` is executed when you run `script/install`. To avoid being loaded automatically, its extension is `.sh`, not `.zsh`.
- **\*/\*.symlink**: Any file ending in `*.symlink` gets symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked in when you run `script/bootstrap`.

## Install ⚙️

Run this:

```sh
git clone https://github.com/holman/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

This will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`,
which sets up a few paths that'll be different on your particular machine.

`dot` is a simple script that installs some dependencies, sets sane macOS
defaults, and so on. Tweak this script, and occasionally run `dot` from
time to time to keep your environment fresh and up-to-date. You can find
this script in `bin/`.

## Thanks 🤍

> _I forked [Ryan Bates](http://github.com/ryanb)' excellent
> [dotfiles](http://github.com/ryanb/dotfiles) for a couple years before the
> weight of my changes and tweaks inspired me to finally roll my own. But Ryan's
> dotfiles were an easy way to get into bash customization, and then to jump ship
> to zsh a bit later. A decent amount of the code in these dotfiles stem or are
> inspired from Ryan's original project._
> 
> – [Holman](https://github.com/holman/dotfiles) 🙏

## Bugs 🐛

https://github.com/holman/dotfiles#bugs
