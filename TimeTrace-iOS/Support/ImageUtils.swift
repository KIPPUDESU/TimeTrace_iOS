import UIKit

// 图片尺寸控制工具
enum ImageUtils {
    // 缩到最大边不超过 maxDimension，避免原图直接存盘导致体积和渲染过大
    static func downscaled(_ image: UIImage, maxDimension: CGFloat = 2048) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // 背景图存放的目录
    static var backgroundsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // 存一张背景图，成功就返回文件名
    // 只记文件名不记完整路径，因为 App 每次重装容器路径都会变，记全路径会让老图全部失效
    static func saveBackground(_ image: UIImage) -> String? {
        let resized = downscaled(image)
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return nil }
        let fileName = "bg-\(UUID().uuidString).jpg"
        do {
            try jpeg.write(to: backgroundsDirectory.appendingPathComponent(fileName))
            return fileName
        } catch {
            return nil
        }
    }

    // 按存下来的名字把图读出来
    // 老记录存的是完整路径，这里只取最后那段文件名，顺带把重装后失效的老路径一并修好
    static func loadBackground(named name: String) -> UIImage? {
        let fileName = (name as NSString).lastPathComponent
        let url = backgroundsDirectory.appendingPathComponent(fileName)
        if let image = UIImage(contentsOfFile: url.path) { return image }
        // 样例数据用的是素材名，磁盘上没有对应文件
        return UIImage(named: name)
    }
}
