import Foundation

// 让 Bundle 在运行时用指定语言的 .lproj 查字符串
// 放进 UserDefaults 的语言偏好，切到对应语言的 Localizable.strings

private var bundleKey: UInt8 = 0

final class BundleEx: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// 切换到指定语言的 .lproj，传 nil 恢复跟随系统
    static func setLanguage(_ language: String?) {
        object_setClass(Bundle.main, BundleEx.self)
        if let language,
           let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(Bundle.main, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            objc_setAssociatedObject(Bundle.main, &bundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}