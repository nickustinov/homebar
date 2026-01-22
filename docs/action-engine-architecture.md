# Action engine architecture

## Overview

The Action Engine is the foundation for all Pro features: a unified API to execute device actions and resolve human-readable names to HomeKit services.

## Architecture diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      External Inputs                         │
│  URL Schemes │ CLI │ Webhooks │ Stream Deck │ Hotkeys       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     ActionEngine                             │
│  execute(target: String, action: Action) → ActionResult      │
└──────────────────────────┬──────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
┌─────────────────────────┐  ┌─────────────────────────────────┐
│    DeviceResolver       │  │    Mac2iOS Bridge               │
│  resolve(query) →       │  │  writeCharacteristic()          │
│    [ServiceData]        │  │  executeScene()                 │
└─────────────────────────┘  └─────────────────────────────────┘
```

## Components

### DeviceResolver

Resolves human-readable identifiers to HomeKit services.

**Supported query formats:**
- UUID: `"ABC123-DEF456-..."`
- Type.Room: `"light.bedroom"`, `"switch.kitchen"`
- Name: `"Bedroom Light"`, `"Kitchen Switch"`
- Scene: `"scene.goodnight"`, `"Goodnight"`
- Room wildcard: `"bedroom.*"`, `"all bedroom"`
- Type wildcard: `"*.light"`, `"all lights"`

**Resolution results:**
- `services([ServiceData])` - matched one or more services
- `scene(SceneData)` - matched a scene
- `notFound(String)` - no matches
- `ambiguous([ServiceData])` - multiple matches needing clarification

**Matching strategy (in order):**
1. Exact UUID match - if query looks like UUID, match directly
2. Exact name match - case-insensitive match on service/scene name
3. Type.Room format - parse "light.bedroom" → type=lightbulb, room=bedroom
4. Fuzzy room match - "bedroom" matches room name containing "bedroom"
5. Wildcards - "all lights", "bedroom.*" patterns
6. Scene prefix - "scene.goodnight" or just scene name

### ActionEngine

Unified API for executing HomeKit actions.

**Supported actions:**
- Power: `toggle`, `turnOn`, `turnOff`
- Brightness: `setBrightness(0-100)`
- Color: `setColor(hue, saturation)`, `setColorTemp(mired)`
- Position (blinds): `setPosition(0-100)`
- Thermostat: `setTargetTemp(Double)`, `setMode(ThermostatMode)`
- Lock: `lock`, `unlock`
- Scene: `executeScene`, `reverseScene`

**Execution flow:**
```swift
func execute(target: String, action: Action) -> ActionResult {
    guard let bridge = bridge else { return .error(.bridgeUnavailable) }
    guard let data = menuData else { return .error(.bridgeUnavailable) }

    let resolved = DeviceResolver.resolve(target, in: data)

    switch resolved {
    case .services(let services):
        return executeOnServices(services, action: action)
    case .scene(let scene):
        return executeScene(scene, action: action)
    case .notFound(let query):
        return .error(.targetNotFound(query))
    case .ambiguous(let options):
        return .error(.ambiguousTarget(options.map { $0.name }))
    }
}
```

### ActionParser

Parses string commands into Action + target (for URL schemes, CLI).

**Example commands:**
- `"toggle light.bedroom"`
- `"set brightness 50 bedroom light"`
- `"turn on all lights"`
- `"execute scene goodnight"`

## File locations

```
macOSBridge/
├── ActionEngine/
│   ├── DeviceResolver.swift
│   ├── ActionEngine.swift
│   └── ActionParser.swift

macOSBridgeTests/
├── ActionEngineTests/
│   ├── DeviceResolverTests.swift
│   ├── ActionEngineTests.swift
│   └── ActionParserTests.swift
```

## Integration with existing code

**MacOSController changes:**
- Create ActionEngine instance
- Pass menuData to ActionEngine when received
- Replace `toggleService()` with ActionEngine calls
- HotkeyManager uses ActionEngine

## Future extensions

Once this foundation is in place:
- **URL schemes**: Parse URL → ActionParser → ActionEngine
- **CLI tool**: Parse args → ActionParser → ActionEngine (via XPC)
- **Webhooks**: Parse JSON → ActionParser → ActionEngine
- **Device Groups**: Groups stored in preferences, DeviceResolver expands them
