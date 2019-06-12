//
//  ViewController.swift
//  SumoAR
//
//  Created by Enzo Maruffa Moreira on 12/06/19.
//  Copyright © 2019 Enzo Maruffa Moreira. All rights reserved.
//

import UIKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
    }
}
