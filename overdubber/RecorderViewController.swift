//
//  RecorderViewController.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 25/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//
// Based on https://www.hackingwithswift.com/example-code/media/how-to-record-audio-using-avaudiorecorder
//

import UIKit
import AVFoundation

class RecorderViewController: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var newLayer: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioPlayer2: AVAudioPlayer!
    var currentLayer:Int = 0
    
    let controller = Controller.init()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newLayer.isEnabled = false

        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record! TODO
                    }
                }
            }
        } catch {
            // failed to record! TODO
        }
    }
    
    func loadRecordingUI() {
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    func getFile() -> URL{
        return getDocumentsDirectory().appendingPathComponent("currentTake.m4a")
    }
    
    func getFileB() -> URL{
        return getDocumentsDirectory().appendingPathComponent("merged.m4a")
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    @IBAction func playTapped(_ sender: Any) {
        if audioPlayer == nil {
            playAudioFile()
        } else {
            audioPlayer.stop()
            audioPlayer = nil
        }
    }
    //should only be possible if something is recorded at current level. Guard?
    @IBAction func addLayerTapped(_ sender: Any) {
        if(currentLayer >= 1){
            controller.merge(audio1: getFile() as NSURL, audio2: getFileB() as NSURL)
        }
        
        currentLayer += 1
        newLayer.isEnabled = false
        recordButton.setTitle("Tap to Record", for: .normal) //refactor to new class - invoke method?
        
    }
    
    
    func startRecording() {
        let audioFilename = getFile()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordButton.setTitle("Tap to Stop", for: .normal)
            newLayer.isEnabled = true
        } catch {
            finishRecording(success: false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    //Playback
    
    func playAudioFile() {
        let file = getFile()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: file)
            audioPlayer?.play()
            
            if(currentLayer >= 1){ //this plays last two recordings. Merge down {0 to (curr-1)}?
                audioPlayer2 = try AVAudioPlayer(contentsOf: getFileB())
                audioPlayer2?.play()
            }
        }
        catch {
            print("playback error")
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
