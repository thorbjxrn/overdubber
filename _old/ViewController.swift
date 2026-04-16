//
//  ViewController.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 26/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var btnExplore: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /*//DEBUG
        
        let stringPath = Bundle.main.url(forResource: "mp3", withExtension: "m4a")!
        let stringPath2 = Bundle.main.url(forResource: "example", withExtension: "m4a")!
        
        let C = Controller.init()
        C.merge(audio1: stringPath, audio2: stringPath2)
        */

        // Do any additional setup after loading the view.
    }
    
    @IBAction func note(_ sender: Any) {
        self.toastError(string: "SoundCloud integration coming soon")
    }
    
    func toastError(string:String){
        let error = UIAlertController(title: "!", message: string, preferredStyle: .alert)
        error.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(error, animated: true)
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
