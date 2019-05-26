//
//  RecorderViewController.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 25/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//
// Based on https://www.hackingwithswift.com/example-code/media/how-to-record-audio-using-avaudiorecorder
//
// More complete resource: https://github.com/SwiftArchitect/SO-32342486/blob/master/SO-32342486/ViewController.swift

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
        return getDocumentsDirectory().appendingPathComponent("dub\(currentLayer).m4a")
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    @IBAction func playTapped(_ sender: Any) {
        playAudioFile()
    }
    //should only be possible if something is recorded at current level. Guard?
    @IBAction func addLayerTapped(_ sender: Any) {
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
    // POSSIBLE idea: Keep all layers as files, then initialize through closures a way to play all at once.
    func playAudioFile() {
        if(audioPlayer == nil || !audioPlayer.isPlaying){
                do {
                let file = getDocumentsDirectory().appendingPathComponent("dub\(currentLayer).m4a")
                
                //try AVAudioPlayer(contentsOf: file).play()
                audioPlayer = try AVAudioPlayer(contentsOf: file)
                audioPlayer.play()
                    
                    if(currentLayer>0){
                        let file2 = getDocumentsDirectory().appendingPathComponent("dub\(currentLayer-1).m4a")
                        if(FileManager.default.fileExists(atPath: file2.absoluteString)){
                            print("Play 2. file")
                            audioPlayer2 = try AVAudioPlayer(contentsOf: file2)
                            audioPlayer2.play()
                        }
                    }
            }
            catch {
                print("playback error")
            }
        }else{
            audioPlayer.stop()
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
