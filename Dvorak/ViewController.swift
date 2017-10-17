//
//  ViewController.swift
//  Dvorak
//
//  Created by Anouk Stein on 9/20/14.
//  Copyright (c) 2014 Anouk Stein, M.D. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    @IBAction func linkToiTunes(_ sender: UIButton) {
        let appURL = URL(string:"itms-apps://itunes.apple.com/us/app/ianatomy/id328875702?mt=8&uo=4")
        UIApplication.shared.open(appURL!, options: [:], completionHandler: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instructionsLabel.text = "1. Settings \n\t- General \n\t\t- Keyboard -> Keyboards \n\t\t\t- Add New Keyboard \n\t\t\t\t- Dvorak Keyboard  \n\n2. Then use 🌐 button to switch keyboards."

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }

    func dismissKeyboard(){
        textField.resignFirstResponder()
    }
}

