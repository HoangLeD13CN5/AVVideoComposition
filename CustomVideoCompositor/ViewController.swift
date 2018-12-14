//
//  ViewController.swift
//  AVPlayerLayerBug
//
//  Created by Clay Garrett on 11/16/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Photos

class ViewController: UIViewController{
    
    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var drawView: UIView!
    @IBOutlet weak var playerView: ViewDraw!
    @IBOutlet weak var exportVideoShow: UIView!
    
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    private var playerLayer1: AVPlayerLayer?
    private var player1: AVPlayer?
    private var playerItem1: AVPlayerItem?
      var isPlayingVideo = false
    
    var image:UIImage?
    var exportUrl:URL!
    let videoUrl: URL = URL(fileURLWithPath: Bundle.main.path(forResource: "VfE_html5", ofType: "mp4")!)
    var indexCGTime:CMTime = CMTimeMake(1, 30)
    
    override func viewDidLoad() {
        initPlayerView()
    }
    
    func initPlayerView(){
        playerItem = AVPlayerItem(url: videoUrl)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = self.playerView.bounds
        self.playerView.layer.addSublayer(playerLayer!)
        self.playVideo()
    }
    
    @IBOutlet weak var btnPlayOrPause: UIButton!
    func playVideo(){
        if !self.isPlayingVideo {
            self.isPlayingVideo = true
            self.btnPlayOrPause.setTitle("Pause", for: .normal)
            player?.play()
        }
    }
    
    func pauseVideo() {
        if self.isPlayingVideo {
            self.isPlayingVideo = false
            self.btnPlayOrPause.setTitle("Play", for: .normal)
            player?.pause()
        }
    }
    
    
    @IBAction func playPause(_ sender: Any) {
        if self.isPlayingVideo {
            self.indexCGTime = (player?.currentItem?.currentTime())!
            pauseVideo()
        }else {
            playVideo()
        }
    }
    
    @IBOutlet weak var imageVIew: UIImageView!
    
    @objc func initPlayerViewExport(){
        playerItem1 = AVPlayerItem(url: exportUrl)
        player1 = AVPlayer(playerItem: playerItem1)
        playerLayer1 = AVPlayerLayer(player: player1)
        playerLayer1?.frame = self.exportVideoShow.bounds
        self.exportVideoShow.layer.addSublayer(playerLayer1!)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player1?.currentItem, queue: .main) {[weak self] _  in
            self?.player1?.seek(to: CMTime(value: 0, timescale: 1))
            self?.player1?.play()
        }
        self.player1?.play()
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func export(_ sender: Any) {
        image = self.drawView.asImage()
        self.imageVIew.image = image
        self.imageVIew.isHidden = true
        self.addImageForVideo()
    }
    
}

extension ViewController {
    func addImageForVideo() {
        // remove existing export file if it exists
        let baseDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        exportUrl = (baseDirectory.appendingPathComponent("export.mov", isDirectory: false) as NSURL).filePathURL!
        deleteExistingFile(url: exportUrl)
        
        // init variables
        let videoAsset: AVAsset = AVAsset(url: videoUrl) as AVAsset
        let tracks = videoAsset.tracks(withMediaType: AVMediaTypeVideo)
        let videoAssetTrack = tracks.first!
        
        // build video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = CustomVideoCompositor.self
        videoComposition.renderSize = CGSize(width: videoAssetTrack.naturalSize.width, height: videoAssetTrack.naturalSize.height)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        // build instructions
        let instructionTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(20, 1))
        // we're overlaying this on our source video. here, our source video is 1080 x 1080
        // so even though our final export is 320 x 320, if we want full coverage of the video with our watermark,
        // then we need to make our watermark frame 1080 x 1080
        let image = self.image!.cgImage
        let watermarkFrame = CGRect(x: 0, y: 0, width: videoAssetTrack.naturalSize.width, height: videoAssetTrack.naturalSize.height)
        let instruction = WatermarkCompositionInstruction(timeRange: instructionTimeRange, watermarkImage: image!, watermarkFrame: watermarkFrame)
        
        // build instructions
        let instructionTimeRange1 = CMTimeRangeMake(CMTimeMake(20, 1), videoAssetTrack.timeRange.duration)
        // we're overlaying this on our source video. here, our source video is 1080 x 1080
        // so even though our final export is 320 x 320, if we want full coverage of the video with our watermark,
        // then we need to make our watermark frame 1080 x 1080
        let image1 = UIImage(named: "panda.png")!.cgImage
        let watermarkFrame1 = CGRect(x: 0, y: 0, width: 320, height:320)
        let instruction1 = WatermarkCompositionInstruction(timeRange: instructionTimeRange1, watermarkImage: image1!, watermarkFrame: watermarkFrame1)
        
        videoComposition.instructions = [instruction,instruction1]
        
        // create exporter and export
        let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exporter!.videoComposition = videoComposition
        exporter!.outputURL = exportUrl
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.exportAsynchronously() {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter!)
            }
        }
    }
    
    func deleteExistingFile(url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        }
        catch _ as NSError {
            
        }
    }
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        guard
            session.status == AVAssetExportSessionStatus.completed,
            let outputURL = session.outputURL
            else {
                print("Error")
                return
        }
        
        let saveVideoToPhotos = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            }) { saved, error in
                let success = saved && (error == nil)
                let title = success ? "Success" : "Error"
                let message = success ? "Video saved" : "Failed to save video"

                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(action:UIAlertAction!) in
                    self.initPlayerViewExport()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }

        // Ensure permission to access Photo Library
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    saveVideoToPhotos()
                }
            }
        } else {
            saveVideoToPhotos()
        }
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}
