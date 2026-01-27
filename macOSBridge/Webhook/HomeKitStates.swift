//
//  HomeKitStates.swift
//  macOSBridge
//
//  Enums for HomeKit characteristic state values
//

import Foundation

/// Thermostat heating/cooling states (HMCharacteristicValueCurrentHeatingCooling)
enum ThermostatState: Int {
    case off = 0
    case heat = 1
    case cool = 2

    var label: String {
        switch self {
        case .off: return "off"
        case .heat: return "heat"
        case .cool: return "cool"
        }
    }

    init(rawValue: Int, isTarget: Bool = false) {
        switch rawValue {
        case 1: self = .heat
        case 2: self = .cool
        default: self = .off
        }
    }
}

/// Target heating/cooling states including auto (HMCharacteristicValueTargetHeatingCooling)
enum TargetThermostatState: Int {
    case off = 0
    case heat = 1
    case cool = 2
    case auto = 3

    var label: String {
        switch self {
        case .off: return "off"
        case .heat: return "heat"
        case .cool: return "cool"
        case .auto: return "auto"
        }
    }
}

/// Heater-cooler target states (HMCharacteristicValueTargetHeaterCoolerState)
enum HeaterCoolerState: Int {
    case auto = 0
    case heat = 1
    case cool = 2

    var label: String {
        switch self {
        case .auto: return "auto"
        case .heat: return "heat"
        case .cool: return "cool"
        }
    }
}

/// Garage door/door states (HMCharacteristicValueDoorState)
enum DoorState: Int {
    case open = 0
    case closed = 1
    case opening = 2
    case closing = 3
    case stopped = 4

    var label: String {
        switch self {
        case .open: return "open"
        case .closed: return "closed"
        case .opening: return "opening"
        case .closing: return "closing"
        case .stopped: return "stopped"
        }
    }
}

/// Lock states (HMCharacteristicValueLockMechanismState)
enum LockState: Int {
    case unsecured = 0
    case secured = 1
    case jammed = 2
    case unknown = 3

    var isLocked: Bool {
        self == .secured
    }
}
