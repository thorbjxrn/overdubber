//
//  RecorderViewController.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 25/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//
// Based on https://www.hackingwithswift.com/example-code/media/how-to-record-audio-using-avaudiorecorder
//
// For future refacotring: https://github.com/SwiftArchitect/SO-32342486/blob/master/SO-32342486/ViewController.swift
//
// Docu: https://developer.apple.com/documentation/avfoundation/avmutablecompositiontrack
// More: https://developer.apple.com/documentation/avfoundation/avassetexportsession

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
    var version = 0
    var somethingRecorded = false
    
    var child = SpinnerViewController()

    
    override func viewDidLoad() {
        Model.shared.clearRec()
        super.viewDidLoad()
        newLayer.isEnabled = false
        playBtn.isEnabled = false

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
        return Model.shared.getRecordingFolder().appendingPathComponent("project\(version).m4a")
    }
    
    @IBAction func export(_ sender: Any) {
        print("export")
        if(self.somethingRecorded){
            while(Controller.shared.assetExport?.progress ?? 1.0 < 1.0){
                createSpinnerView()
                sleep(2)
            }
            print(Controller.shared.assetExport?.progress)
            if(currentLayer>1){
                print("Merge down")
                if Controller.shared.merge(audio1: Model.shared.getRecordingFolder().appendingPathComponent("project\(version).m4a"), audio2: Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer).m4a"), filePath: Model.shared.getRecordingFolder().appendingPathComponent("project\(version+1).m4a"))
                {
                    version += 1
                    print("Merge success?")
                }
                
            }
            else if(currentLayer>0){
                print("First merge down")
                
                if Controller.shared.merge(audio1: Model.shared.getRecordingFolder().appendingPathComponent("dub0.m4a"), audio2: Model.shared.getRecordingFolder().appendingPathComponent("dub1.m4a"), filePath: Model.shared.getRecordingFolder().appendingPathComponent("project0.m4a"))
                {
                    print("Merge success?")
                }
            }
        }
        //Let Export do its thing. TODO this will merge down so abort errors might accur.
        //Do same as add layer button:
        newLayer.isEnabled = false
        somethingRecorded = false
        recordButton.setTitle("Tap to Record", for: .normal)
        currentLayer += 1
        
        while(Controller.shared.assetExport?.progress ?? 1.0 < 1.0){
            createSpinnerView()
            sleep(2)
        }
        
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
                try FileManager.default.copyItem(at: self.getProjectFile(), to: Model.shared.getLibraryFolder().appendingPathComponent("\(name).m4a"))
                //self.removeSpinner()
                
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
            newLayer.isEnabled = false
        } else {
            finishRecording(success: true)
            somethingRecorded = true
            playBtn.isEnabled = true
            newLayer.isEnabled = true
            if(Controller.shared.assetExport?.progress ?? 1.0 < 1.0){
                createSpinnerView()
            }
        }
    }
    
    @IBAction func playTapped(_ sender: Any) {
        playAudioFile()
    }
    //should only be possible if something is recorded at current level. Guard?
    @IBAction func addLayerTapped(_ sender: Any) {
        
        newLayer.isEnabled = false
        somethingRecorded = false
        recordButton.setTitle("Tap to Record", for: .normal) //refactor to new class - invoke method?
        
        addLayer()
    }
    
    func addLayer(){
        if(audioPlayer != nil){
            audioPlayer.stop()
        }
        if(audioPlayer2 != nil){
            audioPlayer2?.stop()
        }
        
        while(Controller.shared.assetExport?.progress ?? 1.0 < 1.0){
            createSpinnerView()
            sleep(2)
        }
        print(Controller.shared.assetExport?.progress)
        if(currentLayer>1){
            print("Merge down")
            if Controller.shared.merge(audio1: Model.shared.getRecordingFolder().appendingPathComponent("project\(version).m4a"), audio2: Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer).m4a"), filePath: Model.shared.getRecordingFolder().appendingPathComponent("project\(version+1).m4a"))
            {
                version += 1
                print("Merge success?")
            }
            
        }
        else if(currentLayer>0){
            print("First merge down")
            
            if Controller.shared.merge(audio1: Model.shared.getRecordingFolder().appendingPathComponent("dub0.m4a"), audio2: Model.shared.getRecordingFolder().appendingPathComponent("dub1.m4a"), filePath: Model.shared.getRecordingFolder().appendingPathComponent("project0.m4a"))
            {
                print("Merge success?")
            }
        }
        
        if(Controller.shared.assetExport?.progress ?? 1.0 < 1.0){
            createSpinnerView()
        }
        
        print((Model.shared.getRecList()!).map{$0.lastPathComponent})
        currentLayer += 1
        layersLabel.text = "Layers: \(currentLayer)"
        
        
    }
    
    func createSpinnerView() {
        let child = SpinnerViewController()
        
        // add the spinner view controller
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        // wait two seconds to simulate some work happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
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
        
        //Dubbing requires playback
        do{
            if(audioPlayer != nil){
                audioPlayer.stop()
            }
            if(audioPlayer2 != nil){
                audioPlayer2?.stop()
            }
            
            var file2 = Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer-1).m4a")
            if(currentLayer>1){
                file2 = getProjectFile()
            }
            if(FileManager.default.fileExists(atPath: String(file2.absoluteString.dropFirst(8)))){
                print("Play 2. file: \(getProjectFile().lastPathComponent)")
                audioPlayer2 = try AVAudioPlayer(contentsOf: file2)
                audioPlayer2.play()
            }
        }catch{
            print("UnderDub error")
        }
        
        
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
    // There is some issue with notplaying the second from last recorded bit? TODO
    func playAudioFile() {
        
        if(audioPlayer == nil || !audioPlayer.isPlaying){
            if(somethingRecorded){
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
                            print("Play 2. file: \(getProjectFile().lastPathComponent)")
                            audioPlayer2 = try AVAudioPlayer(contentsOf: file2)
                            audioPlayer2.play()
                        }
                    }
                }
                catch {
                    print("playback error")
                }
            }
            else{
                do{
                    if(currentLayer>0){
                        print("layer \(currentLayer)")
                        var file2 = Model.shared.getRecordingFolder().appendingPathComponent("dub\(currentLayer-1).m4a")
                        if(currentLayer>1){
                            file2 = getProjectFile()
                        }
                        if(FileManager.default.fileExists(atPath: String(file2.absoluteString.dropFirst(8)))){
                            print("Play 2. file: \(getProjectFile().lastPathComponent)")
                            audioPlayer2 = try AVAudioPlayer(contentsOf: file2)
                            audioPlayer2.play()
                        }
                    }
                }
                catch {
                    print("playback error")
                }
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
