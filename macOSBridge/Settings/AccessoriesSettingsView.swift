//
//  AccessoriesSettingsView.swift
//  macOSBridge
//
//  Accessories settings tab with favourites and visibility toggles
//

import AppKit

// MARK: - Main view

class AccessoriesSettingsView: NSView {

    private let stackView = NSStackView()
    private var menuData: MenuData?
    private var needsRebuild = false

    // Favourites table (embedded in content)
    private var favouritesTableView: NSTableView?
    private var favouriteItems: [FavouriteItem] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        stackView.orientation = .vertical
        stackView.spacing = 0
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        if needsRebuild {
            needsRebuild = false
            rebuildContent()
        }
    }

    func configure(with data: MenuData) {
        self.menuData = data
        PreferencesManager.shared.currentHomeId = data.selectedHomeId
        needsRebuild = true
        needsLayout = true
    }

    private func rebuildFavouritesList() {
        guard let data = menuData else {
            favouriteItems = []
            return
        }

        let preferences = PreferencesManager.shared

        let sceneLookup = Dictionary(uniqueKeysWithValues: data.scenes.map { ($0.uniqueIdentifier, $0) })
        let serviceLookup = Dictionary(uniqueKeysWithValues: data.accessories.flatMap { $0.services }.map { ($0.uniqueIdentifier, $0) })

        var items: [FavouriteItem] = []

        for id in preferences.orderedFavouriteIds {
            if let scene = sceneLookup[id] {
                items.append(FavouriteItem(kind: .scene(scene), id: id, name: scene.name))
            } else if let service = serviceLookup[id] {
                items.append(FavouriteItem(kind: .service(service), id: id, name: service.name))
            }
        }

        favouriteItems = items
    }

    private func rebuildContent() {
        rebuildFavouritesList()

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        favouritesTableView = nil

        guard let data = menuData else { return }

        let preferences = PreferencesManager.shared
        let rowHeight = FavouritesRowLayout.rowHeight
        let headerHeight: CGFloat = 32
        let sectionSpacing: CGFloat = 12

        let excludedTypes: Set<String> = [
            ServiceTypes.temperatureSensor,
            ServiceTypes.humiditySensor
        ]

        let typeOrder: [String] = [
            ServiceTypes.lightbulb,
            ServiceTypes.switch,
            ServiceTypes.outlet,
            ServiceTypes.fan,
            ServiceTypes.heaterCooler,
            ServiceTypes.thermostat,
            ServiceTypes.windowCovering,
            ServiceTypes.lock,
            ServiceTypes.garageDoorOpener
        ]

        var servicesByRoom: [String: [ServiceData]] = [:]
        var noRoomServices: [ServiceData] = []

        for accessory in data.accessories {
            for service in accessory.services {
                guard !excludedTypes.contains(service.serviceType) else { continue }

                if let roomId = service.roomIdentifier {
                    servicesByRoom[roomId, default: []].append(service)
                } else {
                    noRoomServices.append(service)
                }
            }
        }

        // Favourites section
        if !favouriteItems.isEmpty {
            let favouritesHeader = FavouritesSectionHeader(
                title: "Favourites",
                icon: NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
            )
            addView(favouritesHeader, height: headerHeight)
            addSpacer(height: 12)

            let tableHeight = CGFloat(favouriteItems.count) * rowHeight
            let tableContainer = createFavouritesTable(height: tableHeight)
            addView(tableContainer, height: tableHeight)

            addSpacer(height: sectionSpacing * 2)
        }

        // Scenes section
        if !data.scenes.isEmpty {
            let scenesHeader = FavouritesSectionHeader(
                title: "Scenes",
                icon: NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil),
                isHidden: preferences.hideScenesSection,
                showEyeButton: true
            )
            scenesHeader.onVisibilityToggled = { [weak self] in
                preferences.hideScenesSection.toggle()
                self?.needsRebuild = true
                self?.needsLayout = true
            }
            addView(scenesHeader, height: headerHeight)

            let isScenesHidden = preferences.hideScenesSection
            for scene in data.scenes {
                let isFavourite = preferences.isFavourite(sceneId: scene.uniqueIdentifier)
                let isSceneHidden = preferences.isHidden(sceneId: scene.uniqueIdentifier)
                let row = FavouritesRowView(
                    itemType: .scene(scene),
                    isFavourite: isFavourite,
                    isItemHidden: isSceneHidden,
                    isSectionHidden: isScenesHidden
                )
                row.onFavouriteToggled = { [weak self] in
                    preferences.toggleFavourite(sceneId: scene.uniqueIdentifier)
                    self?.needsRebuild = true
                    self?.needsLayout = true
                }
                row.onVisibilityToggled = { [weak self] in
                    preferences.toggleHidden(sceneId: scene.uniqueIdentifier)
                    self?.needsRebuild = true
                    self?.needsLayout = true
                }
                addView(row, height: rowHeight)
            }

            addSpacer(height: sectionSpacing)
        }

        // Room sections
        for room in data.rooms {
            guard let services = servicesByRoom[room.uniqueIdentifier], !services.isEmpty else { continue }

            let roomIcon = IconMapping.iconForRoom(room.name)
            let roomId = room.uniqueIdentifier

            let header = FavouritesSectionHeader(
                title: room.name,
                icon: roomIcon,
                isHidden: preferences.isHidden(roomId: roomId),
                showEyeButton: true
            )
            header.onVisibilityToggled = { [weak self] in
                preferences.toggleHidden(roomId: roomId)
                self?.needsRebuild = true
                self?.needsLayout = true
            }
            addView(header, height: headerHeight)

            let sortedServices = services.sorted { s1, s2 in
                let idx1 = typeOrder.firstIndex(of: s1.serviceType) ?? Int.max
                let idx2 = typeOrder.firstIndex(of: s2.serviceType) ?? Int.max
                if idx1 != idx2 {
                    return idx1 < idx2
                }
                return s1.name < s2.name
            }

            let isRoomHidden = preferences.isHidden(roomId: roomId)
            for service in sortedServices {
                let isFavourite = preferences.isFavourite(serviceId: service.uniqueIdentifier)
                let isItemHidden = preferences.isHidden(serviceId: service.uniqueIdentifier)
                let row = FavouritesRowView(
                    itemType: .service(service),
                    isFavourite: isFavourite,
                    isItemHidden: isItemHidden,
                    isSectionHidden: isRoomHidden
                )
                row.onFavouriteToggled = { [weak self] in
                    preferences.toggleFavourite(serviceId: service.uniqueIdentifier)
                    self?.needsRebuild = true
                    self?.needsLayout = true
                }
                row.onVisibilityToggled = { [weak self] in
                    preferences.toggleHidden(serviceId: service.uniqueIdentifier)
                    self?.needsRebuild = true
                    self?.needsLayout = true
                }
                addView(row, height: rowHeight)
            }

            addSpacer(height: sectionSpacing)
        }

        // Other section
        if !noRoomServices.isEmpty {
            let header = FavouritesSectionHeader(
                title: "Other",
                icon: NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
            )
            addView(header, height: headerHeight)

            let sortedServices = noRoomServices.sorted { s1, s2 in
                let idx1 = typeOrder.firstIndex(of: s1.serviceType) ?? Int.max
                let idx2 = typeOrder.firstIndex(of: s2.serviceType) ?? Int.max
                if idx1 != idx2 {
                    return idx1 < idx2
                }
                return s1.name < s2.name
            }

            for service in sortedServices {
                let isFavourite = preferences.isFavourite(serviceId: service.uniqueIdentifier)
                let isItemHidden = preferences.isHidden(serviceId: service.uniqueIdentifier)
                let row = FavouritesRowView(
                    itemType: .service(service),
                    isFavourite: isFavourite,
                    isItemHidden: isItemHidden
                )
                row.onFavouriteToggled = { [weak self] in
                    preferences.toggleFavourite(serviceId: service.uniqueIdentifier)
                    self?.needsRebuild = true
                    self?.needsLayout = true
                }
                row.onVisibilityToggled = { [weak self] in
                    preferences.toggleHidden(serviceId: service.uniqueIdentifier)
                    self?.needsRebuild = true
                    self?.needsLayout = true
                }
                addView(row, height: rowHeight)
            }

            addSpacer(height: sectionSpacing)
        }
    }

    private func addView(_ view: NSView, height: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    private func addSpacer(height: CGFloat) {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    private func createFavouritesTable(height: CGFloat) -> NSView {
        let tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = FavouritesRowLayout.rowHeight
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none
        tableView.registerForDraggedTypes([.favouriteItem])
        tableView.draggingDestinationFeedbackStyle = .gap
        tableView.allowsMultipleSelection = false
        tableView.usesAutomaticRowHeights = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        self.favouritesTableView = tableView

        let container = NSView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: container.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
}

// MARK: - Favourites Table View Delegate/DataSource

extension AccessoriesSettingsView: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return favouriteItems.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = favouriteItems[row]
        let rowView = DraggableFavouriteRowView(item: item)
        rowView.onRemove = { [weak self] in
            let preferences = PreferencesManager.shared
            switch item.kind {
            case .scene:
                preferences.toggleFavourite(sceneId: item.id)
            case .service:
                preferences.toggleFavourite(serviceId: item.id)
            }
            self?.needsRebuild = true
            self?.needsLayout = true
        }
        return rowView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return FavouritesRowLayout.rowHeight
    }

    // MARK: - Drag and Drop

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = favouriteItems[row]
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(item.id, forType: .favouriteItem)
        return pasteboardItem
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return []
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems,
              let pasteboardItem = items.first,
              let draggedId = pasteboardItem.string(forType: .favouriteItem),
              let originalRow = favouriteItems.firstIndex(where: { $0.id == draggedId }) else {
            return false
        }

        var newRow = row
        if originalRow < newRow {
            newRow -= 1
        }

        if originalRow == newRow {
            return false
        }

        PreferencesManager.shared.moveFavourite(from: originalRow, to: newRow)

        rebuildFavouritesList()

        tableView.beginUpdates()
        tableView.moveRow(at: originalRow, to: newRow)
        tableView.endUpdates()

        return true
    }
}
