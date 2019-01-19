// inspiration
// > http://www.mikitamanko.com/blog/2017/05/21/swift-how-to-record-a-screen-video-or-convert-images-to-videos/

import Foundation
import AVKit
import AVFoundation

class RenderAnimation {
  
  private func duration(audioUrl: URL) -> Double {
    let asset = AVURLAsset(url: audioUrl)
    return Double(CMTimeGetSeconds(asset.duration))
  }
  
  private func addAudioTrack(composition: AVMutableComposition, audioUrl: URL) {
    let compositionAudioTrack: AVMutableCompositionTrack = composition.addMutableTrack(
      withMediaType: AVMediaType.audio,
      preferredTrackID: CMPersistentTrackID()
    )!
    
    let aAudioAsset: AVAsset = AVAsset(url: audioUrl)
    let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
    
    try! compositionAudioTrack.insertTimeRange(
      aAudioAssetTrack.timeRange,
      of: aAudioAssetTrack,
      at: CMTime.zero
    )
  }
  
  func renderAnimation(
    screenWidth: CGFloat,
    screenHeight: CGFloat,
    animationLayer: CALayer,
    audioUrl: URL,
    complete: @escaping(_:URL?)->()
  ) {
    
    do {
      // because AVVideoCompositionCoreAnimationTool  cant render animation without bg video
      // we have to fake it with 1s long black screen video (for lower size)
      // text is not rendered: https://stackoverflow.com/questions/10281872/catextlayer-doesnt-appear-in-an-avmutablecomposition-when-running-from-a-unit-t
      let videoResourceName = "unecessaryVideo"
      guard let path = Bundle.main.path(forResource: videoResourceName, ofType: "mp4") else {
        debugPrint("video \(videoResourceName) is not found")
        return
      }
      let videoUrl = URL(fileURLWithPath: path)
      
      let composition = AVMutableComposition()
      let vidAsset = AVURLAsset(url: videoUrl)
      
      // https://stackoverflow.com/questions/31155003/swift-avplayer-how-to-get-length-of-mp3-file-from-url
      let durationOfVoice = duration(audioUrl: audioUrl)
      
      // get video track
      let videoTrack = vidAsset.tracks(withMediaType: AVMediaType.video)[0]
      let vid_timerange = CMTimeRangeMake(
        start: CMTime.zero,
        duration: CMTime(seconds: durationOfVoice, preferredTimescale: 1)
      )
      
      let compositionvideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(
        withMediaType: AVMediaType.video,
        preferredTrackID: CMPersistentTrackID()
      )!
      
      try compositionvideoTrack.insertTimeRange(vid_timerange, of: videoTrack, at: CMTime.zero)
      compositionvideoTrack.preferredTransform = videoTrack.preferredTransform
      
      // Add audio track.
      // ----------------
      // https://stackoverflow.com/a/27084039/8995887 ??? wtf apple?
      addAudioTrack(composition: composition, audioUrl: audioUrl)
      // ----------------
      
      // setup base video layer
      // Original video from frontal camera.
      let videolayer = CALayer()
      // here we can change size of video (only video, not whole animation)
      videolayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
      videolayer.opacity = 1.0
      
      // Combine layers
      let parentlayer = CALayer()
      parentlayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
      parentlayer.addSublayer(videolayer)
      // add whole aniamation
      parentlayer.addSublayer(animationLayer)
      
      parentlayer.isGeometryFlipped = true
      
      let layercomposition = AVMutableVideoComposition()
      let FPS: Int32 = 33
      layercomposition.frameDuration = CMTimeMake(value: 1, timescale: FPS)
      layercomposition.renderScale = 1.0
      layercomposition.renderSize = CGSize(width: screenWidth, height: screenHeight)
      
      // Enable animation for video layers
      layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(
        postProcessingAsVideoLayers: [videolayer],
        in: parentlayer
      )
      
      
      // instruction for watermark
      let instruction = AVMutableVideoCompositionInstruction()
      instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
      let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
      layerinstruction.setTransform(videoTrack.preferredTransform, at: CMTime.zero)
      instruction.layerInstructions = [layerinstruction] as [AVVideoCompositionLayerInstruction]
      layercomposition.instructions = [instruction] as [AVVideoCompositionInstructionProtocol]
      
      // Clear url.
      let movieDestinationUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "/exported_animation.mp4")
      try? FileManager().removeItem(at: movieDestinationUrl)
      
      // Use AVAssetExportSession to export video
      let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
      assetExport?.outputFileType = AVFileType.mov
      assetExport?.outputURL = movieDestinationUrl
      assetExport?.videoComposition = layercomposition
      
      assetExport?.exportAsynchronously(completionHandler: {
        switch assetExport!.status {
        case AVAssetExportSession.Status.failed:
          print("failed")
          print(assetExport?.error ?? "unknown error")
          complete(nil)
        case AVAssetExportSession.Status.cancelled:
          print("cancelled")
          print(assetExport?.error ?? "unknown error")
          complete(nil)
        default:
          print("Movie complete")
          complete(movieDestinationUrl)
        }
      })
    } catch {
      print("VideoWatermarker->getWatermarkLayer everything is baaaad =(")
    }
  }
  
}
