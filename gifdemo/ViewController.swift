//
//  AppDelegate.swift
//  gifdemo
//
//  Created by PavelMac on 27/02/2025.
//  Copyright © 2025 Mark. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var gifPlayerLayer: AVPlayerLayer?
    var gifPlayerItem: AVPlayerItem?
    
    @IBOutlet weak var gifTextContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let path = Bundle.main.path(forResource: "starting", ofType: "mp4") else {
            return
        }
        
        let url = URL(fileURLWithPath: path)
        gifPlayerItem = AVPlayerItem(url: url)
        let player =  AVPlayer(url: url)
        gifPlayerLayer = AVPlayerLayer(player: player)
        gifPlayerLayer?.frame = CGRect(x: 0, y: 0, width: gifTextContainerView.frame.width, height: gifTextContainerView.frame.height)
        gifPlayerLayer?.videoGravity = .resizeAspect
        gifTextContainerView.layer.addSublayer(gifPlayerLayer!)
        
        if let syncLayer = syncLayers(playerItem: player) {
           gifPlayerLayer?.addSublayer(syncLayer)
        }
    }
    
    func syncLayers(playerItem: AVPlayer) -> CALayer? {
        let synchronizedLayer = AVSynchronizedLayer(playerItem: playerItem.currentItem!)
        let textLayer = createGifAnimation()
        synchronizedLayer.addSublayer(textLayer!)
        synchronizedLayer.zPosition = 999
        synchronizedLayer.frame = CGRect(x: 0, y: 0, width: gifTextContainerView.frame.width, height: gifTextContainerView.frame.height)
        synchronizedLayer.frame.origin = .zero
        return synchronizedLayer
    }
    
    func createGifAnimation() -> CALayer? {
        let layers = CALayer()
        _ = 0
        for i in 0...20 {
            if let url = Bundle.main.url(forResource: "giphy", withExtension: "gif") {
                let gifLayer = CALayer()
                gifLayer.frame = CGRect(x: 0, y: 500, width: gifTextContainerView.frame.width, height: 200)
                gifLayer.beginTime = 1
                gifLayer.duration = 10
                if let gifAnimation = animationForGif(with: url) {
                    gifLayer.add(gifAnimation, forKey: "contents")
                    layers.addSublayer(gifLayer)
                }
            }
        }
        
        return layers
    }
    
    func animationForGif(with url: URL) -> CAKeyframeAnimation? {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.contents))
        var frames:[CGImage] = []
        var delayTimes: [CGFloat] = []
        var totalTime: CGFloat = 0.0
        guard let gifSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("Gif source error: \(url)")
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(gifSource)
        
        for i in 0..<frameCount {
            guard let frame = CGImageSourceCreateImageAtIndex(gifSource, i, nil) else {
                continue
            }
            guard let dic = CGImageSourceCopyPropertiesAtIndex(gifSource, i, nil) as? [AnyHashable: Any] else {
                continue
            }
            
            guard let gifDict: [AnyHashable: Any] = dic[kCGImagePropertyGIFDictionary] as? [AnyHashable: Any] else {
                continue
            }
            
            let delayTime = gifDict[kCGImagePropertyGIFDelayTime] as? CGFloat ?? 0
            
            frames.append(frame)
            delayTimes.append(delayTime)
            
            totalTime += delayTime
        }
        
        if frames.count == 0 {
            return nil
        }
        
        assert(frames.count == delayTimes.count)
        
        var times: [NSNumber] = []
        var currentTime: CGFloat = 0
        
        for i in 0..<delayTimes.count {
            times.append(NSNumber(value: Double(currentTime / totalTime)))
            currentTime += delayTimes[i]
        }
        animation.keyTimes = times
        animation.values = frames
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = totalTime
        animation.repeatCount = .infinity
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        
        return animation
    }
    
    @IBAction func startButtonAnimation(_ sender: Any) {
        gifPlayerLayer?.player?.seek(to: .zero)
        gifPlayerLayer?.player?.play()
    }
}
