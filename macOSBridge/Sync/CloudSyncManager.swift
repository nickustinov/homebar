//
//  CloudSyncManager.swift
//  macOSBridge
//
//  Manages iCloud sync using NSUbiquitousKeyValueStore for Pro users
//

import Foundation
import AppKit

final class CloudSyncManager {

    static let shared = CloudSyncManager()

    static let syncStatusChangedNotification = Notification.Name("CloudSyncManagerStatusChanged")

    private let defaults = UserDefaults.standard
    private let cloudStore = NSUbiquitousKeyValueStore.default

    private var isListening = false
    private var isApplyingCloudChanges = false
    private var periodicSyncTimer: Timer?
    private let syncInterval: TimeInterval = 3600 // 1 hour

    private enum Keys {
        static let syncEnabled = "cloudSyncEnabled"
        static let lastSyncTimestamp = "cloudSyncLastTimestamp"
    }

    // Keys that should be synced (per-home, will be suffixed with homeId)
    private let syncableKeyPrefixes = [
        "orderedFavouriteIds",
        "favouriteSceneIds",
        "favouriteServiceIds",
        "hiddenSceneIds",
        "hiddenServiceIds",
        "hiddenRoomIds",
        "deviceGroups",
        "shortcuts"
    ]

    private init() {}

    // MARK: - Public API

    var isSyncEnabled: Bool {
        get { defaults.bool(forKey: Keys.syncEnabled) }
        set {
            defaults.set(newValue, forKey: Keys.syncEnabled)
            if newValue && ProStatusCache.shared.isPro {
                startListening()
                uploadAllSyncableKeys()
            } else if !newValue {
                stopListening()
            }
            NotificationCenter.default.post(name: Self.syncStatusChangedNotification, object: nil)
        }
    }

    var lastSyncTimestamp: Date? {
        get { defaults.object(forKey: Keys.lastSyncTimestamp) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastSyncTimestamp) }
    }

    func syncNow() {
        print("[CloudSync] syncNow called — isPro: \(ProStatusCache.shared.isPro), isSyncEnabled: \(isSyncEnabled)")
        guard ProStatusCache.shared.isPro && isSyncEnabled else {
            print("[CloudSync] syncNow guard failed, aborting")
            return
        }
        uploadAllSyncableKeys()
        let syncResult = cloudStore.synchronize()
        print("[CloudSync] syncNow synchronize() returned: \(syncResult)")
        pullFromCloudStore()
        NotificationCenter.default.post(name: Self.syncStatusChangedNotification, object: nil)
    }

    func startListening() {
        print("[CloudSync] startListening called — isListening: \(isListening), isPro: \(ProStatusCache.shared.isPro), isSyncEnabled: \(isSyncEnabled)")
        guard !isListening else { return }
        guard ProStatusCache.shared.isPro && isSyncEnabled else { return }

        isListening = true
        print("[CloudSync] now listening for changes")

        // Listen for external iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )

        // Listen for local preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocalChange),
            name: PreferencesManager.preferencesChangedNotification,
            object: nil
        )

        // Synchronize to get any pending changes, then pull
        cloudStore.synchronize()
        pullFromCloudStore()

        // Pull again after a short delay to allow synchronize() to fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            print("[CloudSync] delayed pull after startup")
            self?.cloudStore.synchronize()
            self?.pullFromCloudStore()
        }

        // Pull when app becomes active (after sleep/switch)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBecameActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        // Start periodic sync
        periodicSyncTimer?.invalidate()
        periodicSyncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.periodicSync()
        }
        print("[CloudSync] periodic sync scheduled every \(Int(syncInterval / 60)) minutes")
    }

    func stopListening() {
        guard isListening else { return }
        isListening = false
        periodicSyncTimer?.invalidate()
        periodicSyncTimer = nil

        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )
        NotificationCenter.default.removeObserver(
            self,
            name: PreferencesManager.preferencesChangedNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: - Sync handlers

    @objc private func handleCloudChange(_ notification: Notification) {
        print("[CloudSync] handleCloudChange notification received")
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            print("[CloudSync] handleCloudChange — no userInfo or changeReason")
            return
        }

        print("[CloudSync] handleCloudChange — reason: \(changeReason) (server=0, initial=1, quota=2, accountChange=3)")

        // Only process server changes and initial sync downloads
        guard changeReason == NSUbiquitousKeyValueStoreServerChange ||
              changeReason == NSUbiquitousKeyValueStoreInitialSyncChange else {
            print("[CloudSync] handleCloudChange — ignoring reason \(changeReason)")
            return
        }

        guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            print("[CloudSync] handleCloudChange — no changedKeys in userInfo")
            return
        }

        print("[CloudSync] handleCloudChange — changedKeys: \(changedKeys)")
        applyCloudChanges(for: changedKeys)
    }

    @objc private func handleLocalChange(_ notification: Notification) {
        // Prevent feedback loop when applying cloud changes
        guard !isApplyingCloudChanges else {
            print("[CloudSync] handleLocalChange — skipping (applying cloud changes)")
            return
        }
        guard ProStatusCache.shared.isPro && isSyncEnabled else { return }

        print("[CloudSync] handleLocalChange — uploading")
        uploadAllSyncableKeys()
    }

    @objc private func handleAppBecameActive() {
        guard ProStatusCache.shared.isPro && isSyncEnabled else { return }
        print("[CloudSync] app became active — syncing")
        cloudStore.synchronize()
        pullFromCloudStore()
    }

    private func periodicSync() {
        guard ProStatusCache.shared.isPro && isSyncEnabled else { return }
        print("[CloudSync] periodic sync triggered")
        uploadAllSyncableKeys()
        cloudStore.synchronize()
        pullFromCloudStore()
    }

    // MARK: - Pull

    private func pullFromCloudStore() {
        guard let homeId = PreferencesManager.shared.currentHomeId else {
            print("[CloudSync] pullFromCloudStore — no currentHomeId, aborting")
            return
        }

        print("[CloudSync] pullFromCloudStore — homeId: \(homeId)")
        isApplyingCloudChanges = true
        defer { isApplyingCloudChanges = false }

        var appliedCount = 0
        for prefix in syncableKeyPrefixes {
            let key = "\(prefix)_\(homeId)"
            if let cloudValue = cloudStore.object(forKey: key) {
                let localValue = defaults.object(forKey: key)
                let cloudDesc = "\(cloudValue)"
                let localDesc = localValue.map { "\($0)" } ?? ""
                if cloudDesc != localDesc {
                    defaults.set(cloudValue, forKey: key)
                    print("[CloudSync]   pulled \(key) = \(cloudValue)")
                    appliedCount += 1
                } else {
                    print("[CloudSync]   unchanged \(key)")
                }
            } else {
                print("[CloudSync]   no cloud data for \(key)")
            }
        }

        if appliedCount > 0 {
            print("[CloudSync] pullFromCloudStore — applied \(appliedCount) keys")
            lastSyncTimestamp = Date()
            NotificationCenter.default.post(
                name: PreferencesManager.preferencesChangedNotification,
                object: nil
            )
        } else {
            print("[CloudSync] pullFromCloudStore — no new data from cloud")
        }
    }

    // MARK: - Upload

    private func uploadAllSyncableKeys() {
        guard let homeId = PreferencesManager.shared.currentHomeId else {
            print("[CloudSync] uploadAllSyncableKeys — no currentHomeId, aborting")
            return
        }

        print("[CloudSync] uploadAllSyncableKeys — homeId: \(homeId)")
        for prefix in syncableKeyPrefixes {
            let key = "\(prefix)_\(homeId)"
            let value = defaults.object(forKey: key)
            if let value = value {
                cloudStore.set(value, forKey: key)
                print("[CloudSync]   upload \(key) = \(value)")
            } else {
                print("[CloudSync]   skip \(key) (nil in UserDefaults)")
            }
        }

        let syncResult = cloudStore.synchronize()
        print("[CloudSync] uploadAllSyncableKeys synchronize() returned: \(syncResult)")
        lastSyncTimestamp = Date()
    }

    // MARK: - Download

    private func applyCloudChanges(for changedKeys: [String]) {
        print("[CloudSync] applyCloudChanges — keys: \(changedKeys)")
        isApplyingCloudChanges = true
        defer { isApplyingCloudChanges = false }

        var appliedCount = 0
        for key in changedKeys {
            // Only sync keys that match our syncable prefixes
            guard syncableKeyPrefixes.contains(where: { key.hasPrefix($0) }) else {
                print("[CloudSync]   skip \(key) (not syncable)")
                continue
            }

            if let value = cloudStore.object(forKey: key) {
                defaults.set(value, forKey: key)
                print("[CloudSync]   applied \(key) = \(value)")
                appliedCount += 1
            } else {
                defaults.removeObject(forKey: key)
                print("[CloudSync]   removed \(key)")
                appliedCount += 1
            }
        }

        print("[CloudSync] applyCloudChanges — applied \(appliedCount) keys")
        lastSyncTimestamp = Date()

        // Notify that preferences changed from cloud
        NotificationCenter.default.post(
            name: PreferencesManager.preferencesChangedNotification,
            object: nil
        )
    }
}
