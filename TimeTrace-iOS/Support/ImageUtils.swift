import UIKit

// 编辑页预览用的两张已裁切图，fileName 指向完整尺寸缩略图
nonisolated struct EditorPreviewImages: @unchecked Sendable {
    let fileName: String
    let pinned: UIImage
    let poster: UIImage
}

// 图片尺寸控制工具
enum ImageUtils {
    // 缩到最大边不超过 maxDimension，避免原图直接存盘导致体积和渲染过大
    nonisolated static func downscaled(_ image: UIImage, maxDimension: CGFloat = 2048) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // 按目标宽高比居中裁切 把最长边限制住 给预览直接铺
    nonisolated static func centerCropped(_ image: UIImage, aspectRatio: CGFloat, maxDimension: CGFloat = 1600) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0, aspectRatio > 0 else { return image }

        let imageRatio = size.width / size.height
        var cropWidth = size.width
        var cropHeight = size.height
        if imageRatio > aspectRatio {
            cropWidth = size.height * aspectRatio
        } else if imageRatio < aspectRatio {
            cropHeight = size.width / aspectRatio
        }

        let longest = max(cropWidth, cropHeight)
        let outputScale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: cropWidth * outputScale, height: cropHeight * outputScale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            let drawRect = CGRect(
                x: -(size.width - cropWidth) / 2 * outputScale,
                y: -(size.height - cropHeight) / 2 * outputScale,
                width: size.width * outputScale,
                height: size.height * outputScale
            )
            image.draw(in: drawRect)
        }
    }

    // 背景图存放的目录
    nonisolated static var backgroundsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // 把已经处理好的图写成 JPEG，成功就返回文件名
    @discardableResult
    nonisolated static func writeBackground(_ image: UIImage, fileName: String? = nil) -> String? {
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else { return nil }
        let name = fileName ?? "bg-\(UUID().uuidString).jpg"
        do {
            try jpeg.write(to: backgroundsDirectory.appendingPathComponent(name))
            return name
        } catch {
            return nil
        }
    }

    // 只记文件名不记完整路径，因为 App 每次重装容器路径都会变，记全路径会让老图全部失效
    nonisolated static func saveBackground(_ image: UIImage) -> String? {
        writeBackground(downscaled(image))
    }

    // 后台一次做完：两张预览裁切落盘，再按原先那样存一份完整尺寸缩略图备用
    nonisolated static func prepareEditorBackground(_ image: UIImage, posterAspect: CGFloat) -> EditorPreviewImages? {
        let source = downscaled(image)
        let pinned = centerCropped(source, aspectRatio: 16.0 / 9.0)
        let poster = centerCropped(source, aspectRatio: posterAspect)
        let id = UUID().uuidString
        // 完整尺寸缩略图给首页、详情当备用，记录里只记这个名字
        guard let fileName = writeBackground(source, fileName: "bg-\(id).jpg") else { return nil }
        writeBackground(pinned, fileName: "bg-\(id)-pinned.jpg")
        writeBackground(poster, fileName: "bg-\(id)-poster.jpg")
        return EditorPreviewImages(
            fileName: fileName,
            pinned: pinned,
            poster: poster
        )
    }

    // 按存下来的名字把图读出来
    // 老记录存的是完整路径，这里只取最后那段文件名，顺带把重装后失效的老路径一并修好
    nonisolated static func loadBackground(named name: String) -> UIImage? {
        let fileName = (name as NSString).lastPathComponent
        let url = backgroundsDirectory.appendingPathComponent(fileName)
        if let image = UIImage(contentsOfFile: url.path) { return image }
        // 样例数据用的是素材名，磁盘上没有对应文件
        return UIImage(named: name)
    }
}
