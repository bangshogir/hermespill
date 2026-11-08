# Credits & Attribution

HermesPill would not exist without the work below.

## Upstream project

**Venu — Dynamic Notch for Windows**
- Author: Nakul Srivastava
- Source: https://github.com/imnakul/venu---Dynamic-Notch-for-Windows
- License: MIT

HermesPill is a fork of Venu. The original copyright notice is retained in
[`LICENSE`](LICENSE). The notch window, Direct2D rendering, glass/surface themes, media
controls, notifications, media/usage trackers, shelf, clipboard history, timers, calendar
and the settings GUI are all Venu's original work.

## What HermesPill changes

- Rebrand (name, window classes, registry keys, config paths, exe/product metadata).
- Hermes-focused Mission Control: documented local webhook integration
  (`notify` / `activity` / `usage`), plus `notch_send.py` and `notch_feeder.py` helpers.
- An original HermesPill logo (`assets/hermespill-logo.svg`).

## Third-party crates

All dependencies are MIT or Apache-2.0 licensed, including:
`egui`, `eframe`, `windows`, `image`, `serde`, `serde_json`, `dirs`, `parking_lot`.
See `Cargo.lock` for the full tree and each crate's own repository for its license text.
