import Foundation

final class Store {
    static let changedNotification = Notification.Name("StoreChanged")
    private static let documentDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    static let shared = Store(url: documentDirectory)

    let baseURL: URL?
    var placeholder: URL?
    private(set) var rootFolder: Folder

    init(url: URL?) {
        baseURL = url
        placeholder = nil

        if let u = url,
            let data = try? Data(contentsOf: u.appendingPathComponent(.storeLocation)),
            let folder = try? JSONDecoder().decode(Folder.self, from: data) {
            rootFolder = folder
        } else {
            rootFolder = Folder(name: "", uuid: UUID())
        }

        rootFolder.store = self
    }

    func fileURL(for recording: Recording) -> URL? {
        return baseURL?.appendingPathComponent(recording.uuid.uuidString + ".m4a") ?? placeholder
    }

    func save(_ notifying: Item, userInfo: [AnyHashable: Any]) {
        if let url = baseURL,
            let data = try? JSONEncoder().encode(rootFolder) {
            try! data.write(to: url.appendingPathComponent(.storeLocation))
        }
        NotificationCenter.default.post(name: Store.changedNotification, object: notifying, userInfo: userInfo)
    }

    func item(atUUIDPath path: [UUID]) -> Item? {
        guard let first = path.first, first == rootFolder.uuid else { return nil }
        return rootFolder.item(atUUIDPath: ArraySlice(path))
    }

    func removeFile(for recording: Recording) {
        if let url = fileURL(for: recording), url != placeholder {
            _ = try? FileManager.default.removeItem(at: url)
        }
    }
}

fileprivate extension String {
    static let storeLocation = "store.json"
}
