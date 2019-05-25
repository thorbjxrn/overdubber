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
    init() {
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFilePath(filename: String) -> URL{
        return getDocumentsDirectory().appendingPathComponent("\(filename).m4a")
    }
    
    func merge(audio1: NSURL, audio2:  NSURL) -> Bool{
        let composition = AVMutableComposition()
        let compositionAudioTrack1:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
        let compositionAudioTrack2:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
        
        //let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        let fileDestinationUrl = getFilePath(filename: "merged") //TODO : dynamic names and export/record folders
        
        let filemanager = FileManager.default
        if (filemanager.fileExists(atPath: fileDestinationUrl.path))
        {
            do
            {
                try filemanager.removeItem(at: fileDestinationUrl)
            }
            catch let error as NSError
            {
                NSLog("Error: \(error)")
            }
        }
        
        let url1 = audio1
        let url2 = audio2
        
        let avAsset1 = AVURLAsset(url: url1 as URL, options: nil)
        let avAsset2 = AVURLAsset(url: url2 as URL, options: nil)
        
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
        }
        
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.outputFileType = AVFileType.m4a
        assetExport?.outputURL = fileDestinationUrl
        assetExport?.exportAsynchronously(completionHandler:{
                switch assetExport!.status{
                case AVAssetExportSession.Status.failed:
                    print("failed \(assetExport?.error)")
                case AVAssetExportSession.Status.cancelled:
                    print("cancelled \(assetExport?.error)")
                case AVAssetExportSession.Status.unknown:
                    print("unknown\(assetExport?.error)")
                case AVAssetExportSession.Status.waiting:
                    print("waiting\(assetExport?.error)")
                case AVAssetExportSession.Status.exporting:
                    print("exporting\(assetExport?.error)")
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
}
