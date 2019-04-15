//
//  PhotoLibraryCollectionViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 26..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos

class PhotoLibraryCollectionViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private var m_resultAssets:[PHAsset]?
    private weak var m_parentVC:UIViewController?
    private var videoURLList:NSMutableArray?
    var collectionViewContentSize: CGSize {
        let numCellsPerRow: CGFloat = 3
        let spaceBetweenCells: CGFloat = 2
        let dim = ((self.view.frame.size.width) - (numCellsPerRow - 1) * spaceBetweenCells) / numCellsPerRow
        
        return CGSize(width:dim, height:dim)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoURLList = NSMutableArray()
        m_resultAssets = NSArray() as? [PHAsset]
        self.collectionView?.register(UINib(nibName: "PhotoThumbnail", bundle: nil), forCellWithReuseIdentifier: "id_photoThumbnail")
        self.fetchPHImage()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Merge", style: .done, target: self, action: #selector(startMergeVideos))
    }
    
    func bindParentVC(vc : UIViewController) {
        m_parentVC = vc
    }
    
    private func fetchPHImage() {
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil)
        let options = PHFetchOptions()
        
        for i in 0..<fetchResult.count {
            let collection = fetchResult[i]
            let assetResult = PHAsset.fetchAssets(in: collection, options: options)
            
            for i in 0..<assetResult.count {
                m_resultAssets?.insert(assetResult[i], at: i)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.collectionViewContentSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:PhotoThumbnail = collectionView.dequeueReusableCell(withReuseIdentifier: "id_photoThumbnail", for: indexPath) as! PhotoThumbnail
        cell.bindPhotoVC(photoCVC: self)
        cell.getAssetThumbnail(asset: (m_resultAssets?[indexPath.row])!)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell:PhotoThumbnail = collectionView.cellForItem(at: indexPath) as? PhotoThumbnail {
            if let videoURL = cell.getVideoURL() {
                cell.onClick() ? videoURLList?.add(videoURL) : videoURLList?.remove(videoURL)
            }
        }
    }
    
    private func isListContainValue(item:Any) -> Bool{
        if let list = videoURLList {
            return list.contains(item)
        }
        
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (m_resultAssets?.count)!
    }
    
    @objc func startMergeVideos() {
        guard videoURLList != nil else{
            return
        }
        
        let alert = UIAlertController(title: "Merging", message: "On merging video...", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        
        var assetList:[AVAsset] = [AVAsset]()
        for urlList in videoURLList! {
            if let videoURL = urlList as? URL {
                assetList.append(AVAsset(url: videoURL))
            }
        }
        VideoUtility.shared.mergedVideo(videos: assetList, successListener: { (videoURL) in
            if let mergedViewController:MergedVideoViewController = self.storyboard?.instantiateViewController(withIdentifier: "id_mergeVideo") as? MergedVideoViewController {
                mergedViewController.bindMergedVideoURL(url: videoURL)
                alert.dismiss(animated: true, completion: {
                    self.navigationController?.pushViewController(mergedViewController, animated: true)
                })
            }
        }, errorListener: {
            alert.dismiss(animated: true, completion: nil)
        })
    }
}
