//
//  Controller.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 25/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//

import Foundation
import AVFoundation

class Controller{
    
    static let shared = Controller.init()
    var player:AVAudioPlayer?
    var assetExport:AVAssetExportSession?
    
    init() {
        
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFilePath(filename: String) -> URL{
        return Model.shared.getLibraryFolder().appendingPathComponent("\(filename).m4a") //export
    }
    
    
    func merge(audio1: URL, audio2:  URL) -> Bool
    {
        let composition = AVMutableComposition()
        
        let compositionAudioTrack1:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: 1)!
        let compositionAudioTrack2:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: 2)!
        
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        //let fileDestinationUrl = documentDirectoryURL.appendingPathComponent("resultmerge.m4a")
        let fileDestinationUrl = getFilePath(filename: "resultmerge")

        let filemanager = FileManager.default
        if (filemanager.fileExists(atPath: fileDestinationUrl.path))
        {
            do
            {
                try filemanager.removeItem(at: fileDestinationUrl)
                print("File \(fileDestinationUrl.lastPathComponent):Removed")
            }
            catch let error as NSError
            {
                NSLog("Error: \(error)")
            }
        }
        
        let url1 = audio1
        let url2 = audio2
        
        let avAsset1 = AVURLAsset(url: url1, options: nil)
        let avAsset2 = AVURLAsset(url: url2, options: nil)
        
        
        var tracks1 = avAsset1.tracks(withMediaType: AVMediaType.audio)
        var tracks2 = avAsset2.tracks(withMediaType: AVMediaType.audio)
        
        let assetTrack1:AVAssetTrack = tracks1[0]
        let assetTrack2:AVAssetTrack = tracks2[0]
        
        let duration1: CMTime = assetTrack1.timeRange.duration
        let duration2: CMTime = assetTrack2.timeRange.duration
        
        let timeRange1 = CMTimeRangeMake(start: CMTime.zero, duration: duration1)
        let timeRange2 = CMTimeRangeMake(start: CMTime.zero, duration: duration2)
        do
        {
            try compositionAudioTrack1.insertTimeRange(timeRange1, of: assetTrack1, at: CMTime.zero)
            try compositionAudioTrack2.insertTimeRange(timeRange2, of: assetTrack2, at: CMTime.zero)
            
        }
        catch
        {
            print(error)
            return false
        }
        
        let audioMix: AVMutableAudioMix = AVMutableAudioMix()
        var audioMixParam: [AVMutableAudioMixInputParameters] = []
        audioMixParam.append(AVMutableAudioMixInputParameters(track: assetTrack1))
        audioMixParam.append(AVMutableAudioMixInputParameters(track: assetTrack2))
        
        audioMix.inputParameters = audioMixParam
        
        assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.audioMix = audioMix
        assetExport?.outputFileType = AVFileType.m4a
        assetExport?.outputURL = fileDestinationUrl
        
        assetExport?.exportAsynchronously(completionHandler:
            {
                //print(self.assetExport!)
                switch self.assetExport!.status
                {
                case AVAssetExportSession.Status.failed:
                    print("failed \(self.assetExport?.error)")
                case AVAssetExportSession.Status.cancelled:
                    print("cancelled \(self.assetExport?.error)")
                case AVAssetExportSession.Status.unknown:
                    print("unknown\(self.assetExport?.error)")
                case AVAssetExportSession.Status.waiting:
                    print("waiting\(self.assetExport?.error)")
                case AVAssetExportSession.Status.exporting:
                    print("exporting\(self.assetExport?.error)")
                default:
                    print("complete")
                }
        })
        if(filemanager.fileExists(atPath: fileDestinationUrl.path)){
            return true
        }
        else{
            return false
        }
    }
    
    
    func merge(audio1: URL, audio2:  URL, filePath: URL) -> Bool
    {
        let composition = AVMutableComposition()
        
        let compositionAudioTrack1:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: 1)!
        let compositionAudioTrack2:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: 2)!
        
        let fileDestinationUrl = filePath
        
        let filemanager = FileManager.default
        if (filemanager.fileExists(atPath: fileDestinationUrl.path))
        {
            do
            {
                try filemanager.removeItem(at: fileDestinationUrl)
                print("File \(fileDestinationUrl.lastPathComponent):Removed")
            }
            catch let error as NSError
            {
                NSLog("Error: \(error)")
            }
        }
        
        let url1 = audio1
        let url2 = audio2
        
        let avAsset1 = AVURLAsset(url: url1, options: nil)
        let avAsset2 = AVURLAsset(url: url2, options: nil)
        
        
        var tracks1 = avAsset1.tracks(withMediaType: AVMediaType.audio)
        var tracks2 = avAsset2.tracks(withMediaType: AVMediaType.audio)
        
        let assetTrack1:AVAssetTrack = tracks1[0]
        let assetTrack2:AVAssetTrack = tracks2[0]
        
        let duration1: CMTime = assetTrack1.timeRange.duration
        let duration2: CMTime = assetTrack2.timeRange.duration
        
        let timeRange1 = CMTimeRangeMake(start: CMTime.zero, duration: duration1)
        let timeRange2 = CMTimeRangeMake(start: CMTime.zero, duration: duration2)
        do
        {
            try compositionAudioTrack1.insertTimeRange(timeRange1, of: assetTrack1, at: CMTime.zero)
            try compositionAudioTrack2.insertTimeRange(timeRange2, of: assetTrack2, at: CMTime.zero)
            
            //print(composition)
            //This should work
        }
        catch
        {
            print(error)
            return false
        }
        
        let audioMix: AVMutableAudioMix = AVMutableAudioMix()
        var audioMixParam: [AVMutableAudioMixInputParameters] = []
        audioMixParam.append(AVMutableAudioMixInputParameters(track: assetTrack1))
        audioMixParam.append(AVMutableAudioMixInputParameters(track: assetTrack2))
        
        audioMix.inputParameters = audioMixParam
        
        assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.audioMix = audioMix
        assetExport?.outputFileType = AVFileType.m4a
        assetExport?.outputURL = fileDestinationUrl
        
        assetExport?.exportAsynchronously(completionHandler:
            {
                //print(self.assetExport!)
                switch self.assetExport!.status
                {
                case AVAssetExportSession.Status.failed:
                    print("failed \(self.assetExport?.error)")
                case AVAssetExportSession.Status.cancelled:
                    print("cancelled \(self.assetExport?.error)")
                case AVAssetExportSession.Status.unknown:
                    print("unknown\(self.assetExport?.error)")
                case AVAssetExportSession.Status.waiting:
                    print("waiting\(self.assetExport?.error)")
                case AVAssetExportSession.Status.exporting:
                    print("exporting\(self.assetExport?.error)")
                default:
                    print("Merge complete \(fileDestinationUrl.lastPathComponent)")
                }
                
        })
        if(filemanager.fileExists(atPath: fileDestinationUrl.path)){
            return true
        }
        else{
            return false
        }
    }
}
