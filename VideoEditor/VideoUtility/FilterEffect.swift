//
//  FilterEffect.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 27..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import UIKit

extension CIImage {    
    struct CIEffectKeys {
        static let InputHighlightAmount = "inputHighlightAmount"
        static let InputShadowAmount = "inputShadowAmount"
    }
    
    @objc func noneEffect() -> CIImage? {
        return self
    }
    
    func invertColorEffect() -> CIImage? {
        guard let colorInvert = CIFilter(name: "CIColorInvert") else {
            return nil
        }
        colorInvert.setValue(self, forKey: kCIInputImageKey)
        return colorInvert.outputImage
    }
    
    @objc func vignetteEffect() -> CIImage? {
        guard let vignetteFilter = CIFilter(name: "CIVignetteEffect") else {
            return nil
        }
        vignetteFilter.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        vignetteFilter.setValue(center, forKey: kCIInputCenterKey)
        vignetteFilter.setValue(self.extent.size.height/2, forKey: kCIInputRadiusKey)        
        
        return vignetteFilter.outputImage
    }
    
   @objc func photoInstantEffect() -> CIImage? {
        guard let ohotoEffectInstant = CIFilter(name: "CIPhotoEffectInstant") else {
            return nil
        }
        ohotoEffectInstant.setValue(self, forKey: kCIInputImageKey)
        return ohotoEffectInstant.outputImage
    }
    
    @objc func crystallizeEffect() -> CIImage? {
        guard let crystallize = CIFilter(name: "CICrystallize") else {
            return nil
        }
        crystallize.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        crystallize.setValue(center, forKey: kCIInputCenterKey)
        crystallize.setValue(15, forKey: kCIInputRadiusKey)
        
        return crystallize.outputImage
    }
    
    @objc func comicEffect() -> CIImage? {
        guard let comicEffect = CIFilter(name: "CIComicEffect") else {
            return nil
        }
        comicEffect.setValue(self, forKey: kCIInputImageKey)
        return comicEffect.outputImage
    }
    
    @objc func bloomEffect() -> CIImage? {
        guard let bloom = CIFilter(name: "CIBloom") else {
            return nil
        }
        bloom.setValue(self, forKey: kCIInputImageKey)
        bloom.setValue(self.extent.size.height/2, forKey: kCIInputRadiusKey)
        bloom.setValue(1, forKey: kCIInputIntensityKey)
        
        return bloom.outputImage
    }
    
    @objc func edgesEffect() -> CIImage? {
        guard let edges = CIFilter(name: "CIEdges") else {
            return nil
        }
        edges.setValue(self, forKey: kCIInputImageKey)
        edges.setValue(0.5, forKey: kCIInputIntensityKey)
        
        return edges.outputImage
    }
    
    @objc func edgeWorkEffect() -> CIImage? {
        guard let edgeWork = CIFilter(name: "CIEdgeWork") else {
            return nil
        }
        edgeWork.setValue(self, forKey: kCIInputImageKey)
        edgeWork.setValue(1, forKey: kCIInputRadiusKey)
        
        return edgeWork.outputImage
    }
    
    @objc func gloomEffect() -> CIImage? {
        guard let gloom = CIFilter(name: "CIGloom") else {
            return nil
        }
        gloom.setValue(self, forKey: kCIInputImageKey)
        gloom.setValue(self.extent.size.height/2, forKey: kCIInputRadiusKey)
        gloom.setValue(1, forKey: kCIInputIntensityKey)
        
        return gloom.outputImage
    }
    
    @objc func hexagonalPixellateEffect() -> CIImage? {
        guard let hexagonalPixellate = CIFilter(name: "CIHexagonalPixellate") else {
            return nil
        }
        hexagonalPixellate.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        hexagonalPixellate.setValue(center, forKey: kCIInputCenterKey)
        hexagonalPixellate.setValue(8, forKey: kCIInputScaleKey)
        
        return hexagonalPixellate.outputImage
    }
    
    @objc func highlightShadowAdjust() -> CIImage? {
        guard let highlightShadowAdjust = CIFilter(name: "CIHighlightShadowAdjust") else {
            return nil
        }
        highlightShadowAdjust.setValue(self, forKey: kCIInputImageKey)
        highlightShadowAdjust.setValue(1, forKey: CIEffectKeys.InputHighlightAmount)
        highlightShadowAdjust.setValue(1, forKey: CIEffectKeys.InputShadowAmount)
        
        return highlightShadowAdjust.outputImage
    }
    
    @objc func pixellateEffect() -> CIImage? {
        guard let pixellate = CIFilter(name: "CIPixellate") else {
            return nil
        }
        pixellate.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        pixellate.setValue(center, forKey: kCIInputCenterKey)
        pixellate.setValue(8, forKey: kCIInputScaleKey)
        
        return pixellate.outputImage
    }
    
    @objc func pointillizeEffect() -> CIImage? {
        guard let pointillize = CIFilter(name: "CIPointillize") else {
            return nil
        }
        pointillize.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        pointillize.setValue(center, forKey: kCIInputCenterKey)
        pointillize.setValue(10, forKey: kCIInputRadiusKey)
        
        return pointillize.outputImage
    }
}
