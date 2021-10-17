//
//  Bundle+Ext.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/11.
//

import Foundation


private class BundleFinder {}

extension Bundle {
    
    private static var bundle: Bundle? = nil
    
    static var normal_module: Bundle? = {
        let bundleName = "PhotoBrowser"

        var candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
//            Bundle(for: PhotoPreviewSheet.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]
        
        #if SWIFT_PACKAGE
        // For SWIFT_PACKAGE.
        candidates.append(Bundle.module.bundleURL)
        #endif

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        
        return nil
    }()
    


    static var zlPhotoBrowserBundle: Bundle? {
        return normal_module
    }
    
    class func resetLanguage() {
        self.bundle = nil
    }
    
    class func zlLocalizedString(_ key: String) -> String {
        if self.bundle == nil {
            guard let path = Bundle.zlPhotoBrowserBundle?.path(forResource: self.getLanguage(), ofType: "lproj") else {
                return ""
            }
            self.bundle = Bundle(path: path)
        }
        
        let value = self.bundle?.localizedString(forKey: key, value: nil, table: nil)
        return Bundle.main.localizedString(forKey: key, value: value, table: nil)
    }
    
    private class func getLanguage() -> String {
        var language = "en"
        
        switch CustomLanguageDeploy.language {
        case .system:
            language = Locale.preferredLanguages.first ?? "en"
            
            if language.hasPrefix("zh") {
                if language.range(of: "Hans") != nil {
                    language = "zh-Hans"
                } else {
                    language = "zh-Hant"
                }
            } else if language.hasPrefix("ja") {
                language = "ja-US"
            } else if language.hasPrefix("fr") {
                language = "fr"
            } else if language.hasPrefix("de") {
                language = "de"
            } else if language.hasPrefix("ru") {
                language = "ru"
            } else if language.hasPrefix("vi") {
                language = "vi"
            } else if language.hasPrefix("ko") {
                language = "ko"
            } else if language.hasPrefix("ms") {
                language = "ms"
            } else if language.hasPrefix("it") {
                language = "it"
            } else {
                language = "en"
            }
        case .chineseSimplified:
            language = "zh-Hans"
        case .chineseTraditional:
            language = "zh-Hant"
        case .english:
            language = "en"
        case .japanese:
            language = "ja-US"
        case .french:
            language = "fr"
        case .german:
            language = "de"
        case .russian:
            language = "ru"
        case .vietnamese:
            language = "vi"
        case .korean:
            language = "ko"
        case .malay:
            language = "ms"
        case .italian:
            language = "it"
        }
        
        return language
    }
    
    
}
