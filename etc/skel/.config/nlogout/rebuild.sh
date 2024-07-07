#!/bin/bash
pkill -f "nlogout"

sudo pacman -S nim --noconfirm --needed
yes | nimble install parsetoml
yes | nimble install nigui


xsetroot -name ""
nim compile nlogout.nim

sudo cp nlogout /usr/bin
