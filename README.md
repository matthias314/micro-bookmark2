# micro-bookmark2

This repository contains a bookmark plugin
for the [micro](https://github.com/zyedidia/micro) editor.
It is inspired by the plugin [micro-bookmark](https://github.com/haqk/micro-bookmark).
However, the implementation is simplified through the use of
the `onBeforeTextEvent` callback.

**A [custom version](https://github.com/matthias314/micro/tree/m3/onbeforetextevent)
of micro is currently required to use this plugin.
Also note that this plugin is under development. Everything can change at any time.**

## Usage

- `Ctrl-F2`: set or unset (toggle) bookmark
- `Ctrl-Shift-F2`: clear all bookmarks
- `F2`: jump to next bookmark
- `Shift-F2`: jump to previous bookmark

## Installation

Create a directory `~/.config/micro/plug/bookmark2` and store the file `bookmark2.lua` there.
Alternatively, clone this repository into such a directory,
```
git clone https://github.com/matthias314/micro-bookmark2.git ~/.config/micro/plug/bookmark2
```
