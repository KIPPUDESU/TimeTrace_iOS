import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum WatchBackgroundStore {
    static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("WatchBackgrounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func fileURL(named name: String) -> URL {
        directory.appendingPathComponent((name as NSString).lastPathComponent)
    }

    static func save(_ data: Data, named name: String) {
        try? data.write(to: fileURL(named: name), options: .atomic)
    }

    static func exists(named name: String?) -> Bool {
        guard let name, !name.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: fileURL(named: name).path)
    }

    static func removeAll(except keeping: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }
        for file in files where !keeping.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

#if canImport(UIKit)
    static func loadImage(named name: String?) -> UIImage? {
        guard let name, !name.isEmpty else { return nil }
        if let image = UIImage(contentsOfFile: fileURL(named: name).path) {
            return image
        }
        return UIImage(named: name)
    }
#endif

#if os(iOS)
    static func watchJPEG(from image: UIImage, maxDimension: CGFloat = 480, quality: CGFloat = 0.55) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let output: UIImage
        if longest > maxDimension, longest > 0 {
            let scale = maxDimension / longest
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            output = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        } else {
            output = image
        }
        return output.jpegData(compressionQuality: quality)
    }
#endif
}
