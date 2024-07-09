#!/bin/bash
pkill -f "nlogout"

# install the nim language to compile nlogout
sudo pacman -S nim --noconfirm --needed

# Installl modules used in nlogout
yes | nimble install parsetoml
yes | nimble install nigui

# xsetroot -name ""  <--- why?

# Compile nlogout with nim and create binrary in current location this script is ran in, the run after compiled
nim compile --run --define:release --opt:size --app:gui --outdir:. src/nlogout.nim 

sudo cp bin/nlogout /usr/bin

#Maybe copy config.toml to user .config/nlogout/ ???
