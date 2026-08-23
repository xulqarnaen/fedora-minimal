# Omarchy CAVA Visualizer

A live CAVA audio spectrum visualizer for the Omarchy shell bar.

## Install

```bash
omarchy plugin add https://github.com/YOUR_USERNAME/omarchy-cava.git --enable
omarchy bar put io.github.ibr.cava --section left
```

The plugin requires `cava` to be installed.

## Controls

- Left click: toggle the active MPRIS player's play/pause state
- Right click: open or focus CAVA in a terminal

## Settings

The default CAVA configuration is in `cava.conf`. Bar settings can be added
to the widget entry in `~/.config/omarchy/shell.json`, for example:

```json
{
  "id": "io.github.ibr.cava",
  "bars": 18,
  "height": 20,
  "barWidth": 3,
  "barGap": 2
}
```
