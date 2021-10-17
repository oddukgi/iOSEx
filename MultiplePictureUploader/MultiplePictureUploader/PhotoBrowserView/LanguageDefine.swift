//
//  LanguageDefine.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/11.
//

import Foundation


enum LanguageType: Int {
    case system
    case chineseSimplified
    case chineseTraditional
    case english
    case japanese
    case french
    case german
    case russian
    case vietnamese
    case korean
    case malay
    case italian
}



/// Language deploy
struct CustomLanguageDeploy {
    
    static var language: LanguageType = .system
    static var deploy: [LocalLanguageKey: String] = [:]
    
    /// Language for framework.
    public var languageType: LanguageType = .system {
        didSet {
            CustomLanguageDeploy.language = self.languageType
            Bundle.resetLanguage()
        }
    }
    
    
    /// Developers can customize languages.
    /// - example: If you needs to replace
    /// key: .loading, value: "loading, waiting please" language,
    /// The dictionary that needs to be passed in is [.loading: "text to be replaced"].
    /// - warning: Please pay attention to the placeholders contained in languages when changing, such as %ld, %@.
    public var customLanguageKeyValue: [LocalLanguageKey: String] = [:] {
        didSet {
            CustomLanguageDeploy.deploy = self.customLanguageKeyValue
        }
    }

}

struct LocalLanguageKey: Hashable {
    
     let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Camera
    public static let previewCamera = LocalLanguageKey(rawValue: "previewCamera")
    
    /// Record
    public static let previewCameraRecord = LocalLanguageKey(rawValue: "previewCameraRecord")
    
    /// Album
    public static let previewAlbum =    LocalLanguageKey(rawValue: "previewAlbum")
    
    /// Cancel
    public static let cancel =  LocalLanguageKey(rawValue: "cancel")
    
    /// No Photo
    public static let noPhotoTips = LocalLanguageKey(rawValue: "noPhotoTips")
    
    /// loading, waiting please
    public static let loading = LocalLanguageKey(rawValue: "loading")
    
    /// waiting...
    public static let hudLoading = LocalLanguageKey(rawValue: "hudLoading")
    
    /// Done
    public static let done = LocalLanguageKey(rawValue: "done")
    
    /// OK
    public static let ok = LocalLanguageKey(rawValue: "ok")
    
    /// Request timed out 
    public static let timeout = LocalLanguageKey(rawValue: "timeout")
    
    /// Allow %@ to access your album in \"Settings\"->\"Privacy\"->\"Photos\"
    public static let noPhotoLibratyAuthority = LocalLanguageKey(rawValue: "noPhotoLibratyAuthority")
    
    /// Please allow %@ to access your device's camera in \"Settings\"->\"Privacy\"->\"Camera\"
    public static let noCameraAuthority = LocalLanguageKey(rawValue: "noCameraAuthority")
    
    /// Unable to record audio. Go to \"Settings\" > \"%@\" and enable microphone access.
    public static let noMicrophoneAuthority = LocalLanguageKey(rawValue: "noMicrophoneAuthority")
    
    /// Camera is unavailable
    public static let cameraUnavailable = LocalLanguageKey(rawValue: "cameraUnavailable")
    
    /// Keep Recording
    public static let keepRecording = LocalLanguageKey(rawValue: "keepRecording")
    
    /// Go to Settings
    public static let gotoSettings = LocalLanguageKey(rawValue: "gotoSettings")
    
    /// Photos
    public static let photo = LocalLanguageKey(rawValue: "photo")
    
    /// Full Image
    public static let originalPhoto = LocalLanguageKey(rawValue: "originalPhoto")
    
    /// Back
    public static let back = LocalLanguageKey(rawValue: "back")
    
    /// Edit
    public static let edit = LocalLanguageKey(rawValue: "edit")
    
    /// Done
    public static let editFinish = LocalLanguageKey(rawValue: "editFinish")
    
    /// Undo
    public static let revert = LocalLanguageKey(rawValue: "revert")
    
    /// Preview
    public static let preview = LocalLanguageKey(rawValue: "preview")
    
    /// Unable to select video
    public static let notAllowMixSelect = LocalLanguageKey(rawValue: "notAllowMixSelect")
    
    /// Save
    public static let save = LocalLanguageKey(rawValue: "save")
    
    /// Failed to save the image
    public static let saveImageError = LocalLanguageKey(rawValue: "saveImageError")
    
    /// Failed to save the video
    public static let saveVideoError = LocalLanguageKey(rawValue: "saveVideoError")
    
    /// Max select count: %ld
    public static let exceededMaxSelectCount = LocalLanguageKey(rawValue: "exceededMaxSelectCount")
    
    /// Max count for video selection: %ld
    public static let exceededMaxVideoSelectCount = LocalLanguageKey(rawValue: "exceededMaxVideoSelectCount")
    
    /// Min count for video selection: %ld
    public static let lessThanMinVideoSelectCount = LocalLanguageKey(rawValue: "lessThanMinVideoSelectCount")
    
    /// Unable to select video with a duration longer than %lds
    public static let longerThanMaxVideoDuration = LocalLanguageKey(rawValue: "longerThanMaxVideoDuration")
    
    /// Unable to select video with a duration shorter than %lds
    public static let shorterThanMaxVideoDuration = LocalLanguageKey(rawValue: "shorterThanMaxVideoDuration")
    
    /// Unable to sync from iCloud
    public static let iCloudVideoLoadFaild = LocalLanguageKey(rawValue: "iCloudVideoLoadFaild")
    
    /// loading failed (图片加载失败)
    public static let imageLoadFailed = LocalLanguageKey(rawValue: "imageLoadFailed")
    
    /// Tap to take photo and hold to record video
    public static let customCameraTips = LocalLanguageKey(rawValue: "customCameraTips")
    
    /// Tap to take photo
    public static let customCameraTakePhotoTips = LocalLanguageKey(rawValue: "customCameraTakePhotoTips")
    
    /// hold to record video
    public static let customCameraRecordVideoTips = LocalLanguageKey(rawValue: "customCameraRecordVideoTips")
    
    /// Record at least %lds
    public static let minRecordTimeTips = LocalLanguageKey(rawValue: "minRecordTimeTips")
    
    /// Recents
    public static let cameraRoll = LocalLanguageKey(rawValue: "cameraRoll")
    
    /// Panoramas
    public static let panoramas = LocalLanguageKey(rawValue: "panoramas")
    
    /// Videos
    public static let videos = LocalLanguageKey(rawValue: "videos")
    
    /// Favorites
    public static let favorites = LocalLanguageKey(rawValue: "favorites")
    
    /// Time-Lapse
    public static let timelapses = LocalLanguageKey(rawValue: "timelapses")
    
    /// Recently Added
    public static let recentlyAdded = LocalLanguageKey(rawValue: "recentlyAdded")
    
    /// Bursts
    public static let bursts = LocalLanguageKey(rawValue: "bursts")
    
    /// Slo-mo
    public static let slomoVideos = LocalLanguageKey(rawValue: "slomoVideos")
    
    /// Selfies
    public static let selfPortraits = LocalLanguageKey(rawValue: "selfPortraits")
    
    /// Screenshots
    public static let screenshots = LocalLanguageKey(rawValue: "screenshots")
    
    /// Portrait
    public static let depthEffect = LocalLanguageKey(rawValue: "depthEffect")
    
    /// Live Photo
    public static let livePhotos = LocalLanguageKey(rawValue: "livePhotos")
    
    /// Animated
    public static let animated = LocalLanguageKey(rawValue: "animated")
    
    /// My Photo Stream
    public static let myPhotoStream = LocalLanguageKey(rawValue: "myPhotoStream")
    
    /// All Photos
    public static let noTitleAlbumListPlaceholder = LocalLanguageKey(rawValue: "noTitleAlbumListPlaceholder")
    
    /// Unable to access all photos, go to settings
    public static let unableToAccessAllPhotos = LocalLanguageKey(rawValue: "unableToAccessAllPhotos")
    
    /// Drag here to remove
    public static let textStickerRemoveTips = LocalLanguageKey(rawValue: "textStickerRemoveTips")
    
}


func localLanguageTextValue(_ key: LocalLanguageKey) -> String {
    if let value = CustomLanguageDeploy.deploy[key] {
        return value
    }
    return Bundle.zlLocalizedString(key.rawValue)
}
