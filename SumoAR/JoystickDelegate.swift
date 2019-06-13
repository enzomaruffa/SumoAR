//
//  JoystickDelegate.swift
//  SumoAR
//
//  Created by Enzo Maruffa Moreira on 13/06/19.
//  Copyright © 2019 Enzo Maruffa Moreira. All rights reserved.
//

import UIKit

protocol JoystickDelegate {
    
    func joystickMoved(angle: CGFloat, magnitude: CGFloat) // Angle from center, relative distance to center
    
}
