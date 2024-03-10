//
//  PastePalManager.swift
//  PastePal
//
//  Created by Pratik Ray on 10/03/24.
//

import Foundation
import SwiftUI

class PastePalManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    @Published var filteredItems: [ClipboardItem] = []
    @Published var searchQuery: String = ""

    init() {
        startClipboardMonitoring()
        loadClipboardItems()
    }

    private func startClipboardMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleClipboardChange), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleClipboardChange() {
        if let newContent = NSPasteboard.general.string(forType: .string) {
            addItem(content: newContent)
        }
        applySearchFilter()
    }

    private func loadClipboardItems() {
        if let data = UserDefaults.standard.data(forKey: "clipboardItems"),
           let loadedItems = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            clipboardItems = loadedItems
        }
        applySearchFilter()
    }

    private func saveClipboardItems() {
        if let encodedData = try? JSONEncoder().encode(clipboardItems) {
            UserDefaults.standard.set(encodedData, forKey: "clipboardItems")
        }
    }

    private func applySearchFilter() {
        if searchQuery.isEmpty {
            filteredItems = clipboardItems
        } else {
            filteredItems = clipboardItems.filter { $0.content.localizedCaseInsensitiveContains(searchQuery) }
        }
    }

    func addItem(content: String, copiedFrom: String? = nil) {
        if let existingItemIndex = clipboardItems.firstIndex(where: { $0.content == content }) {
            clipboardItems[existingItemIndex].timestamp = Date()
            clipboardItems[existingItemIndex].copiedFrom = copiedFrom
        } else {
            let newItem = ClipboardItem(content: content, timestamp: Date(), copiedFrom: copiedFrom)
            clipboardItems.insert(newItem, at: 0)
        }
        saveClipboardItems()
        applySearchFilter()
    }

    func copyToClipboard(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([content as NSString])
    }

    func deleteClipboardItem(_ item: ClipboardItem) {
        guard let index = clipboardItems.firstIndex(where: { $0.id == item.id }) else { return }
        clipboardItems.remove(at: index)
        saveClipboardItems()
        applySearchFilter()
    }

    func clearClipboard() {
        clipboardItems.removeAll()
        saveClipboardItems()
        applySearchFilter()
    }
}

