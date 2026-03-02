import AVFoundation
import UIKit

class VideoManager {
    static let shared = VideoManager()
    private var currentAsset: AVAsset?
    private let fileManager = FileManager.default
    
    private init() {}
    
    func loadVideo(path: String) throws {
        guard fileManager.fileExists(atPath: path) else {
            throw VideoError.fileNotFound
        }
        let url = URL(fileURLWithPath: path)
        currentAsset = AVAsset(url: url)
    }
    
    func trimVideo(
        startTimeMs: Int64,
        endTimeMs: Int64,
        includeAudio: Bool = true,
        outputWidth: Int? = nil,
        outputHeight: Int? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let asset = currentAsset else {
            completion(.failure(VideoError.noVideoLoaded))
            return
        }
        
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let preferredPreset = preferredExportPreset(
            compatiblePresets: compatiblePresets,
            outputWidth: outputWidth,
            outputHeight: outputHeight
        )

        guard compatiblePresets.contains(preferredPreset) else {
            completion(.failure(VideoError.unsupportedFormat))
            return
        }
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: preferredPreset
        ) else {
            completion(.failure(VideoError.exportSessionFailed))
            return
        }

        // Use cacheDir like Android
        let timestamp = Int64(Date().timeIntervalSince1970)
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let outputURL = cacheDir.appendingPathComponent("video_trimmer_\(timestamp).mp4")
        
        // Delete any existing file
        try? fileManager.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Convert milliseconds to CMTime
        let startTime = CMTime(value: startTimeMs, timescale: 1000)
        let endTime = CMTime(value: endTimeMs, timescale: 1000)
        
        // Validate time range against asset duration
        let duration = CMTimeGetSeconds(asset.duration) * 1000
        guard startTimeMs >= 0 && endTimeMs <= Int64(duration) && endTimeMs > startTimeMs else {
            completion(.failure(VideoError.invalidTimeRange))
            return
        }
        
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        exportSession.timeRange = timeRange
        
        // Handle audio
        let audioTracks = asset.tracks(withMediaType: .audio)
        if !includeAudio && !audioTracks.isEmpty {
            let audioMix = AVMutableAudioMix()
            let audioParameters = AVMutableAudioMixInputParameters(track: audioTracks[0])
            audioParameters.setVolume(0.0, at: .zero)
            audioMix.inputParameters = [audioParameters]
            exportSession.audioMix = audioMix
        }
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL.path))
            case .failed:
                completion(.failure(exportSession.error ?? VideoError.exportFailed))
            case .cancelled:
                completion(.failure(VideoError.exportCancelled))
            default:
                completion(.failure(VideoError.unknown))
            }
        }
    }

    private func preferredExportPreset(
        compatiblePresets: [String],
        outputWidth: Int?,
        outputHeight: Int?
    ) -> String {
        guard let outputWidth, let outputHeight else {
            return compatiblePresets.contains(AVAssetExportPresetHighestQuality)
                ? AVAssetExportPresetHighestQuality
                : AVAssetExportPresetMediumQuality
        }

        let normalizedMaxDimension = max(outputWidth, outputHeight)

        let candidates: [String]
        if normalizedMaxDimension <= 640 {
            candidates = [
                AVAssetExportPreset640x480,
                AVAssetExportPreset960x540,
                AVAssetExportPresetMediumQuality,
            ]
        } else if normalizedMaxDimension <= 960 {
            candidates = [
                AVAssetExportPreset960x540,
                AVAssetExportPreset1280x720,
                AVAssetExportPresetMediumQuality,
            ]
        } else {
            candidates = [
                AVAssetExportPreset1280x720,
                AVAssetExportPresetHighestQuality,
                AVAssetExportPresetMediumQuality,
            ]
        }

        for candidate in candidates where compatiblePresets.contains(candidate) {
            return candidate
        }

        return compatiblePresets.contains(AVAssetExportPresetHighestQuality)
            ? AVAssetExportPresetHighestQuality
            : AVAssetExportPresetMediumQuality
    }
    
    func generateThumbnail(atMs position: Int64, size: CGSize?, quality: Int) throws -> String {
        guard let asset = currentAsset else {
            throw VideoError.noVideoLoaded
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let size = size {
            generator.maximumSize = size
        }
        
        // Convert milliseconds to CMTime
        let time = CMTime(value: position, timescale: 1000)
        let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
        let image = UIImage(cgImage: imageRef)
        
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("video_trimmer_\(timestamp).jpg")
        
        guard let data = image.jpegData(compressionQuality: CGFloat(quality) / 100),
              let _ = try? data.write(to: outputURL) else {
            throw VideoError.thumbnailGenerationFailed
        }
        
        return outputURL.path
    }
    
    func clearCache() {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let enumerator = fileManager.enumerator(at: tempDirectory, includingPropertiesForKeys: nil)

        while let url = enumerator?.nextObject() as? URL {
            if (url.pathExtension == "mp4" || url.pathExtension == "jpg") &&
               url.lastPathComponent.hasPrefix("video_trimmer") {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}

enum VideoError: LocalizedError {
    case fileNotFound
    case noVideoLoaded
    case unsupportedFormat
    case exportSessionFailed
    case exportFailed
    case exportCancelled
    case thumbnailGenerationFailed
    case unknown
    case invalidTimeRange
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Video file not found"
        case .noVideoLoaded:
            return "No video is currently loaded"
        case .unsupportedFormat:
            return "Video format is not supported"
        case .exportSessionFailed:
            return "Failed to create export session"
        case .exportFailed:
            return "Failed to export video"
        case .exportCancelled:
            return "Video export was cancelled"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .unknown:
            return "An unknown error occurred"
        case .invalidTimeRange:
            return "Invalid time range. Start time must be non-negative and end time must be greater than start time and within video duration"
        }
    }
}
