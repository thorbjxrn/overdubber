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
    
    @IBOutlet weak var layersLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var newLayer: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioPlayer2: AVAudioPlayer!
    var currentLayer:Int = 0

    
    override func viewDidLoad() {
        Model.shared.clearRec()
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
        return Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer).m4a")
    }
    
    func getProjectFile() -> URL{
        return Model.shared.getRecordingFolder().appendingPathComponent("project.m4a")
    }
    
    @IBAction func export(_ sender: Any) {
        print("export")
        
        let alert = UIAlertController(title: "Export as:", message: nil, preferredStyle: .alert)
        alert.addTextField{(name) in
            name.placeholder = "Filename"
        }
        let action = UIAlertAction(title: "Export", style: .default){(_) in
            guard let name = alert.textFields?[0].text else { return }
            if(name == ""){
                self.toastError(string: "This is required.")
                return
            }
            if(name.contains(" ")){
                self.toastError(string: "No spaces allowed")
                return
            }
            
            
            do{
                try FileManager.default.copyItem(at: self.getFile(), to: Model.shared.getLibraryFolder().appendingPathComponent("\(name).m4a"))
                self.performSegue(withIdentifier: "exportSeg", sender: nil)
                print("File copied to lib folder")
                let added = UIAlertController(title: "Export Complete", message: "", preferredStyle: .alert)
                added.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(added, animated: true)
            }catch{
                print("Copy Failed.")
                self.toastError(string: "FileSystem error")
            }
        }
        alert.addAction(action)
        present(alert, animated: true)
        
        
    }
    
    func toastError(string:String){
        let error = UIAlertController(title: "Error", message: string, preferredStyle: .alert)
        error.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(error, animated: true)
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
        
        newLayer.isEnabled = false
        recordButton.setTitle("Tap to Record", for: .normal) //refactor to new class - invoke method?
        
        addLayer()
    }
    
    func addLayer(){
        /*guard audioPlayer.isPlaying else{
            print("No new layer")
            return
        }*/
        if(currentLayer>1){
            print("First merge down")
            if Controller.shared.merge(audio1: Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer).m4a") as NSURL, audio2: Model.shared.getRecordingFolder().appendingPathComponent("project.m4a") as NSURL, filePath: getProjectFile()) {
                print("Merge success?")
            }
            
        }
        else if(currentLayer>0){
            print("merge down")
            if Controller.shared.merge(audio1: Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer).m4a") as NSURL, audio2: Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer-1).m4a") as NSURL, filePath: getProjectFile()) {
                print("Merge success?")
            }
        }
        print((Model.shared.getRecList()!).map{$0.lastPathComponent})
        currentLayer += 1
        layersLabel.text = "Layers: \(currentLayer)"
        
        
    }
    
    
    func startRecording() {
        let audioFilename = getFile()
        
        let settings = [AVSampleRateKey : NSNumber(value: Float(44100.0)),
                        AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC)),
                        AVNumberOfChannelsKey : NSNumber(value: Int32(1)),
                        AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue))]
        
        /*[
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]*/
        
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
                let file = getFile()
                //try AVAudioPlayer(contentsOf: file).play()
                audioPlayer = try AVAudioPlayer(contentsOf: file)
                audioPlayer.play()
                    
                    if(currentLayer>0){
                        print("layer \(currentLayer)")
                        var file2 = Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer-1).m4a")
                        if(currentLayer>1){
                            file2 = getProjectFile()
                        }
                        if(FileManager.default.fileExists(atPath: String(file2.absoluteString.dropFirst(8)))){
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
