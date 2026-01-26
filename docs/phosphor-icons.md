# Phosphor icons system

This document describes the icon system used in Itsyhome after migrating from SF Symbols to Phosphor Icons.

## Icon naming convention

All Phosphor icons are bundled in `Assets.xcassets/PhosphorIcons/` with naming:
- Regular: `ph.{name}` (e.g., `ph.lightbulb`)
- Filled: `ph.{name}.fill` (e.g., `ph.lightbulb.fill`)

## PhosphorIcon utility (`macOSBridge/Utilities/PhosphorIcon.swift`)

```swift
PhosphorIcon.regular("lightbulb")      // Regular weight
PhosphorIcon.fill("lightbulb")         // Filled weight
PhosphorIcon.icon("lightbulb", filled: isOn)  // Auto-select based on state
```

## Accessory icon patterns

### Binary toggle (on/off state affects fill)
These use `PhosphorIcon.icon(name, filled: isOn)`:

| Type | Icon name | On color | Off color |
|------|-----------|----------|-----------|
| Light | `lightbulb` | `DS.Colors.lightOn` (yellow) | `DS.Colors.mutedForeground` |
| Switch | `power` | `DS.Colors.success` (green) | `DS.Colors.mutedForeground` |
| Outlet | `plug` | `DS.Colors.success` | `DS.Colors.mutedForeground` |
| Fan | `fan` | `DS.Colors.fanOn` (cyan) | `DS.Colors.mutedForeground` |
| Air purifier | `wind` | `DS.Colors.success` | `DS.Colors.mutedForeground` |

### Mode-based (icon changes based on mode)
These select different icons based on current mode:

| Type | Modes | Icons |
|------|-------|-------|
| Thermostat | off/heat/cool | `thermometer` / `fire` (orange) / `snowflake` (blue) |
| AC/HeaterCooler | off/idle/heating/cooling | `thermometer` / `thermometer` / `fire` / `snowflake` |
| Humidifier | off/humidifying/dehumidifying | `drop-half` / `drop-half` (blue) / `drop` (orange) |

### Discrete state (specific states)
These show specific icons for each state:

| Type | States | Icons |
|------|--------|-------|
| Lock | locked/unlocked | `lock` (fill) / `lock-open` (regular) |
| Garage door | closed/open/obstructed | `garage` (fill) / `garage` (regular) / `warning` |
| Security | disarmed/armed/triggered | `shield` / `shield-check` (fill) / `shield-warning` (fill) |
| Blinds | closed/open | `caret-up-down` (regular) / `caret-up-down` (fill) |

### Continuous value (slider-based)
These typically stay regular unless "active":

| Type | Icon | Fill behavior |
|------|------|---------------|
| Valve (irrigation) | `pipe` | Fill when active |
| Valve (shower) | `shower` | Fill when active |
| Valve (faucet) | `drop` | Fill when active |

## Sensor icons (read-only)

| Type | Icon |
|------|------|
| Temperature sensor | `thermometer` |
| Humidity sensor | `drop-half` |

## Room icons (inferred from name)

See `PhosphorIcon.iconNameForRoom()` - matches keywords to icons:
- living -> `couch`
- bedroom/bed -> `bed`
- kitchen -> `cooking-pot`
- bath -> `bathtub`
- office/study -> `desktop`
- garage -> `garage`
- garden/outdoor -> `tree`
- etc.

## Scene icons (inferred from name)

See `PhosphorIcon.iconNameForScene()` - matches keywords to icons:
- morning/sunrise/wake -> `sun-horizon`
- night/sleep/bedtime -> `moon`
- movie/cinema -> `film-strip`
- party -> `confetti`
- relax/chill -> `coffee`
- work/focus -> `briefcase`
- away/leave -> `airplane-takeoff`
- home/arrive -> `house`
- off/all off -> `power`
- on/all on -> `lightbulb`
- Default: `sparkle`

## Group icons

Default: `squares-four`
Users can choose from `PhosphorIcon.suggestedGroupIcons`

## UI icons (static references)

Common UI icons are exposed as static properties:
```swift
PhosphorIcon.star
PhosphorIcon.starFill
PhosphorIcon.eye
PhosphorIcon.pencil
PhosphorIcon.trash
PhosphorIcon.plus
PhosphorIcon.gear
PhosphorIcon.chevronRight
PhosphorIcon.warning
PhosphorIcon.refresh
// etc.
```

