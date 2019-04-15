//
//  TbPhotoThumbnail.swift
//  AnibeaR
//
//  Created by JinYoung Lee on 2017. 7. 3..
//  Copyright © 2017년 AnibeaR. All rights reserved.
//

import Foundation
import Photos

class PhotoThumbnail : UICollectionViewCell {
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var isHighlightView: UIView!
    
    private var photoLibraryCVC:PhotoLibraryCollectionViewController?
    private var assetURL:URL?
    private var onSelected:Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        isHighlightView.isHidden = true
        self.photoImage.contentMode = .scaleAspectFill
    }
    
    func bindPhotoVC(photoCVC:PhotoLibraryCollectionViewController) {
        photoLibraryCVC = photoCVC
    }
    
    func getAssetThumbnail(asset: PHAsset) {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isNetworkAccessAllowed = true
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: (photoLibraryCVC?.collectionViewContentSize)!, contentMode: .aspectFill, options: option, resultHandler: {(result, info)->Void in
            if result != nil {
                thumbnail = result!
                self.photoImage.image = thumbnail
                self.getURL(ofPhotoWith: asset, completionHandler: { (videoURL) in
                    self.assetURL = videoURL
                })
            }
        })
    }
    
    func onClick() -> Bool {
        guard self.photoImage.image != nil else {
            return false
        }
        onSelected = !onSelected
        isHighlightView.isHidden = !onSelected
        return onSelected
    }
    
    func getVideoURL() -> URL? {
        return assetURL
    }
    
    private func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}
