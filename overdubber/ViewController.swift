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
