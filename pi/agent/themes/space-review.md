# 🚀 Space Theme Colour Review

> *"Houston, we have a theme."*

---

## 🪐 Core UI Colours

| Token | Value | Preview |
|-------|-------|---------|
| `accent` | `#b967ff` | **Nebula purple** — the star of the show |
| `border` | `#5a6370` | Subtle stellar boundary |
| `borderAccent` | `#00f0ff` | Cosmic cyan highlight |
| `success` | `#06d6a0` | Earth green — all systems go |
| `error` | `#ef476f` | Mars red — abort mission |
| `warning` | `#ff6b35` | Rocket flame — caution thrusters |
| `muted` | `#8b95a5` | Star dim — secondary intel |
| `dim` | `#5a6370` | Star faint — tertiary telemetry |
| `text` | `#e0e6ed` | Starlight — primary comms |

---

## 🌌 Backgrounds

| Token | Value | Purpose |
|-------|-------|---------|
| `userMessageBg` | `#131624` | Your transmissions from the cockpit |
| `customMessageBg` | `#1c1025` | Extension probe reports |
| `toolPendingBg` | `#090b12` | Scanning sector... |
| `toolSuccessBg` | `#0b1f1a` | Target acquired |
| `toolErrorBg` | `#1f0b14` | Hull breach detected |
| `selectedBg` | `#1e2338` | Nav lock engaged |

---

## 📝 Markdown Rendering

# Heading 1 — Mission Briefing
## Heading 2 — Trajectory Plot
### Heading 3 — Fuel Status

This is **bold text** and *italic text* in the void.

> "The Earth is the cradle of humanity, but mankind cannot stay in the cradle forever."
> — Tsiolkovsky

Here's an `inline code` snippet and a [hyperlink to the stars](https://example.com).

- 🌟 List item alpha
- 🪐 List item beta
- 🚀 List item gamma

```js
// Engine ignition sequence
const liftoff = () => {
  const thrust = 7600; // kN
  const destination = "Mars";
  return `T-minus 0 — ${destination} bound!`;
};
```

---

## 🔧 Syntax Highlighting

```python
# astrophysics.py
class Rocket:
    def __init__(self, name: str, thrust: float):
        self.name = name
        self.thrust = thrust  # 7600 kN
        self.status = "idle"

    def ignite(self) -> bool:
        if self.fuel > 0:
            self.status = "launching"
            return True
        return False

saturn_v = Rocket("Saturn V", 35100.0)
saturn_v.ignite()
```

---

## 🛠️ Diff Preview

```diff
+ Added orbital insertion burn
+ RCS thrusters online
- Removed manual override
- Aborted landing sequence
```

---

## 🧠 Thinking Levels

| Level | Colour | Meaning |
|-------|--------|---------|
| `thinkingOff` | `#161a28` | Engines cold |
| `thinkingMinimal` | `#5a6370` | Gyros spinning |
| `thinkingLow` | `#118ab2` | Sensors warming |
| `thinkingMedium` | `#00a8b3` | Telemetry flowing |
| `thinkingHigh` | `#7a3db8` | Warp drive engaged |
| `thinkingXhigh` | `#d78aff` | Singularity imminent |

---

## ⚡ Bash Mode Indicator

When you hit `!` for bash, the border glows **`#ff6b35`** — like rocket exhaust.

---

## 🎨 Full Variable Palette

| Variable | Hex | Description |
|----------|-----|-------------|
| `nebula` | `#b967ff` | Deep space purple |
| `nebulaBright` | `#d78aff` | Bright nebula glow |
| `nebulaDim` | `#7a3db8` | Faint nebula haze |
| `cosmicCyan` | `#00f0ff` | Electric stellar blue |
| `cosmicCyanDim` | `#00a8b3` | Deeper cyan |
| `rocketFlame` | `#ff6b35` | Main engine orange |
| `rocketGlow` | `#ff9e42` | Amber afterburn |
| `starlight` | `#e0e6ed` | Crisp white star |
| `starDim` | `#8b95a5` | Distant grey star |
| `starFaint` | `#5a6370` | Barely visible |
| `void` | `#0d0f18` | Main terminal bg |
| `voidDeep` | `#090b12` | Deepest black |
| `voidShallow` | `#161a28` | Elevated surface |
| `voidWarm` | `#1c1025` | Warm dark panel |
| `planetGold` | `#ffd166` | Saturnian gold |
| `marsRed` | `#ef476f` | Mars alert red |
| `earthGreen` | `#06d6a0` | Earth success green |
| `cometTail` | `#118ab2` | Comet blue trail |
| `saturnRing` | `#a78bfa` | Purple ring hue |

---

*Theme: `space` · File: `~/.pi/agent/themes/space.json`*
