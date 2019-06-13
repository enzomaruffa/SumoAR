//
//  SelectViewController.swift
//  SumoAR
//
//  Created by Enzo Maruffa Moreira on 12/06/19.
//  Copyright © 2019 Enzo Maruffa Moreira. All rights reserved.
//

import UIKit

class SelectViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "hostSegue" {
            let vc = segue.destination as! GameViewController
            vc.isHost = true
        } else if segue.identifier == "joinSegue" {
            let vc = segue.destination as! GameViewController
            vc.isHost = false
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
