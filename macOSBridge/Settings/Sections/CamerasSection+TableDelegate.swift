//
//  CamerasSection+TableDelegate.swift
//  macOSBridge
//
//  Table delegate and drag-and-drop support for cameras section
//

import AppKit

extension CamerasSection: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        cameras.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        createCameraRowView(camera: cameras[row], row: row)
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let chipLines = computeChipLines(for: cameras[row].uniqueIdentifier)
        if chipLines == 0 { return 36 }
        return 36 + 6 + CGFloat(chipLines) * 20 + CGFloat(chipLines - 1) * 4 + 8
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        false
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isGroupRowStyle = false
        return rowView
    }

    // MARK: - Drag and drop

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard ProStatusCache.shared.isPro else { return nil }
        let camera = cameras[row]
        let pb = NSPasteboardItem()
        pb.setString(camera.uniqueIdentifier, forType: .cameraItem)
        return pb
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        dropOperation == .above ? .move : []
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems,
              let pb = items.first,
              let draggedId = pb.string(forType: .cameraItem),
              let originalRow = cameras.firstIndex(where: { $0.uniqueIdentifier == draggedId }) else {
            return false
        }

        var newRow = row
        if originalRow < newRow { newRow -= 1 }
        if originalRow == newRow { return false }

        // Update order in preferences
        var order = cameras.map { $0.uniqueIdentifier }
        let item = order.remove(at: originalRow)
        order.insert(item, at: newRow)
        PreferencesManager.shared.cameraOrder = order

        // Rebuild to avoid stale row rendering
        DispatchQueue.main.async { [weak self] in
            self?.rebuildContent()
        }

        return true
    }
}
