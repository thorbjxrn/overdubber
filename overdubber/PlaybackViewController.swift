//
//  ViewController.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 25/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//

import UIKit
import AVFoundation

class PlaybackViewController: UIViewController {
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var playBtn: UIButton!
    
    var audioPlayer:AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.setProgress(0, animated: false)
        
    }
    @IBAction func play(_ sender: Any) {
            if(audioPlayer == nil || !audioPlayer.isPlaying){
                do {
                    let file =  Model.shared.getLibList()![0]//test
                    audioPlayer = try AVAudioPlayer(contentsOf: file)
                    audioPlayer.play()
                    
                    playBtn.setTitle("Stop", for: .normal)
                }
                catch {
                    print("playback or file error")
                }
            }else{
                audioPlayer.stop()
                playBtn.setTitle("Play", for: .normal)
            }
    }
    /*
     progressLink = CADisplayLink(target: self,
     selector: #selector(ViewController.playerProgress))
     if let progressLink = progressLink {
     progressLink.preferredFramesPerSecond = 2
     progressLink.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
     }
     *//*
     
    @objc func playerProgress() {
        var progress = Float(0)
        if let audioPlayer = audioPlayer {
            progress = ((audioPlayer.duration > 0)
                ? Float(audioPlayer.currentTime/audioPlayer.duration)
                : 0)
        }
        progressView.setProgress(progress, animated: true)
    }*/
}

