# OpenMap Waypoints

A small companion to [OpenMap](https://www.curseforge.com/wow/addons/openmap) for WoW: Forever (Interface 16001):
its map pin **Import** also takes TomTom waypoints, as Wowhead and guides give them.

## Use

Open OpenMap's pin list (`/openmap pins`), click **Import**, paste the waypoints (Ctrl-V) and click **Add the pins**.
Any of these, one or many, on separate lines or run together:

    /way #1429 41.5 65.8 Marshal Dughan
    /way Elwynn Forest 41.5 65.8 Marshal Dughan
    /way Elwynn 41.5 65.8
    /way 41.5 65.8 Somewhere in the zone you're in

- `#1429` is a map ID. Retail map IDs that aren't on this client are skipped.
- A zone's name can be the whole name or a short part of it, as long as only one zone matches.
- With no zone, the waypoint is in the zone you're in.
- The rest of the line becomes the pin's note.

Waypoints that can't be read are listed in chat. OpenMap's own pin codes (`OMPINS1:...`) still import as before.

## Also

OpenMap's drawing tools (**Draw on the map**) show in front of the map's border and the quest log beside it,
instead of behind them. Blizzard's **Map Pin** button is hidden: on OpenMap's map it does nothing (OpenMap takes
the click it waits for), and OpenMap's **Drop a pin** and Ctrl-click do what it's for.

## How it works

When you click **Add the pins**, the waypoints are turned into OpenMap's own pin code just before OpenMap reads the box,
so OpenMap adds them as it would any shared code. Nothing of OpenMap's is changed.

## Install

Download the zip from the latest release and extract it into `_forever_\Interface\AddOns`, or from this repo:

    powershell -ExecutionPolicy Bypass -File scripts/install-local.ps1

## Developing / releasing

- Test local changes: `.\scripts\install-local.ps1` copies the addon folder into WoW: Forever's `AddOns`, then `/reload`.
- After a WoW patch: bump `## Interface:` in `OpenMapWaypoints/OpenMapWaypoints.toc`.
- Release: `git tag v1.0.1 && git push --tags`. The [Release workflow](.github/workflows/release.yml) stamps the
  version into the TOC, builds the zip (with a `release.json` for the Forever flavor) and publishes the GitHub release.

## License

MIT ([`LICENSE`](LICENSE), also included in the addon folder).
