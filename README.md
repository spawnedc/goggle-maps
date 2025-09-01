# GoggleMaps

**GoggleMaps** is a lightweight map replacement addon for vanilla **World of Warcraft 1.12.1**.
It brings a Google Maps–style experience to Azeroth, with zooming, dragging, and optional quest integration.

Unlike heavier addons (such as Carbonite), GoggleMaps is designed to stay minimal, fast, and easy to use.

Want to use this with TurtleWoW? You can use [GoggleMaps-Turtle](https://github.com/spawnedc/goggle-maps-turtle) alongside GoggleMaps.

---

## ✨ Features

- **Interactive world map replacement**
  - Click and drag to move the map
  - Scroll to zoom in and out

- **Dynamic overlays**
  - Zone textures displayed like stitched maps
  - When zoomed in, minimap textures replace zone overlays for higher detail
  - Currently supports **5 zones** with overlays (more can be enabled via future options)

- **Player tracking**
  - The map follows your position when not hovering over it with the mouse

- **Quest integration (pfQuest support)**
  - If **pfQuest** is loaded, quest icons and clusters will be displayed directly on the map

- **Lightweight design**
  - No bloated databases or heavy UI elements
  - Focused purely on navigation and clarity

---

## 📦 Installation

1. Download the latest release of **GoggleMaps**
2. Extract the folder into: `<WOW folder>\Interface\AddOns\`
3. Restart WoW and enable **GoggleMaps** from the AddOns menu at character select.

---

## ⚙️ Usage

- Open the world map (`M` by default), you can still open the game map using `ALT-M`
- Scroll to zoom in/out
- Left-click + drag to move the map
- Hover the mouse over the map to stop auto-follow
- If pfQuest is installed, quest objectives will appear automatically

---

## 📜 Compatibility

- **WoW Version:** 1.12.1 (Vanilla)
- **Optional Dependency:** [pfQuest](https://github.com/shagu/pfQuest)

---

## 🙌 Thanks

- Inspired by [Carbonite-vanilla](https://gitlab.com/knights-of-sunwell/carbonite-vanilla), huge thanks to [Ritual](https://gitlab.com/Rltual) for the backport
- existence of pfQuest, can't thank [shagu](https://github.com/shagu) enough
- [Turtle WoW wiki addon page](https://turtle-wow.fandom.com/wiki/Addons#For_Addon_Developers) was a massive resource

--

## 🛠️ A Little Backstory

This all began out of curiosity. I’ve always loved **Carbonite** for its mapping features, and when I stumbled upon the [Carbonite Vanilla backport](https://gitlab.com/knights-of-sunwell/carbonite-vanilla) by Ritual, I decided to dive in and see how it worked under the hood.

I spent some time reverse engineering the backport, exploring how it handled maps, overlays, and zooming. It felt like opening a little puzzle box from Vanilla WoW’s past.

From that exploration, I rewrote everything from scratch to create **Goggle Maps**: a lightweight, mapping-only addon for Vanilla and Turtle WoW. The goal was simple: fast, clean, and functional maps, with optional integration for addons like pfQuest and support for Turtle’s custom zones.

To make this possible, I also built a **toolkit** that automates the heavy lifting: extracting data from MPQ files, parsing DBCs, and generating the datasets that drive Goggle Maps. You can check it out here: [Goggle Maps Tools](https://github.com/spawnedc/goggle-maps-tools/). Just because I wrote too much Lua, I switched to my main language of choice: Javascript.

So while Carbonite inspired the journey, every line of **Goggle Maps** code is original.
