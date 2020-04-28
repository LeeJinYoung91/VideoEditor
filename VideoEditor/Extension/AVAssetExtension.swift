//
//  AVAssetExtension.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2020/04/28.
//  Copyright © 2020 JinYoung Lee. All rights reserved.
//

import Foundation
extension AVAsset {
    func saveCurrentItemWithComposition(_ composition: AVVideoComposition, name: String = "temp", listener: ((Bool, URL?, String) -> Void)?) {
        let exporter = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetHighestQuality)
        let fileName = "\(name).mp4"
        let outputPath = URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
        if FileManager.default.fileExists(atPath: outputPath.path) {
            try! FileManager.default.removeItem(atPath: outputPath.path)
        }

        exporter?.outputURL = outputPath
        exporter?.outputFileType = AVFileType.mp4
        exporter?.shouldOptimizeForNetworkUse = true

        exporter?.videoComposition = composition
        exporter?.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
        exporter?.exportAsynchronously {
            listener?(exporter?.error == nil, outputPath, fileName)
        }
    }
    
    func setFilter(filterType: VideoFilterUtility.FILTER_TYPE) -> AVVideoComposition {
        return AVVideoComposition(asset: self) { (request) in
            let source = request.sourceImage
            if let output = VideoFilterUtility.shared.getFilteredCIImage(source, filterType: filterType) {
                request.finish(with: output, context: nil)
            } else {
                request.finish(with: NSError() as Error)
            }
        }
    }
}
