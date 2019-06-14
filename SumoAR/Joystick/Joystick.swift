//
//  Joystick.swift
//  SumoAR
//
//  Created by Enzo Maruffa Moreira on 13/06/19.
//  Copyright © 2019 Enzo Maruffa Moreira. All rights reserved.
//

import UIKit

class Joystick: UIView {
    
    var delegate: JoystickDelegate?
    
    var controllerView: UIView!
    private var controllerRadius: CGFloat!
    private var controllerViewCenter: CGPoint!
    
    private var panGesture: UIPanGestureRecognizer!
    
    
    var viewRadius: CGFloat {
        return self.frame.height / 2
    }
    
    private var viewCenter: CGPoint {
        return CGPoint(x: self.frame.width/2, y: self.frame.width/2)
    }
    
    var maxControllerRadius: CGFloat {
        return viewRadius
    }
    
    var currentControllerAngle: CGFloat {
        let angle = atan2(self.controllerView.center.y - viewCenter.y,  self.controllerView.center.x - viewCenter.x) / 2 + CGFloat.pi/2
        return angle < CGFloat.pi/2 ? (CGFloat.pi/2 - angle) : CGFloat.pi/2 - angle + CGFloat.pi
    }
    
    var currentControllerRadius: CGFloat {
        return viewCenter.distanceTo(controllerView.center)
    }
    
    var magnitude: CGFloat {
        return currentControllerRadius / maxControllerRadius
    }
    
    init(borderWidth: CGFloat = 5, controllerRadius: CGFloat) {
        super.init(frame: .zero)
        //self.backgroundView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: Double(backgroundRadius * 2), height: Double(backgroundRadius * 2))))

        self.controllerView = UIView(frame: .zero)
        //self.controllerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: Double(controllerRadius * 2), height: Double(controllerRadius * 2))))
//
//        self.totalRadius = totalRadius
        self.controllerRadius = controllerRadius
//
//        super.init(frame: CGRect(origin: .zero, size: CGSize(width: Double(totalRadius * 2), height: Double(totalRadius * 2))))
//
//        self.layer.cornerRadius = CGFloat(totalRadius)
//        backgroundView.layer.cornerRadius = CGFloat(backgroundRadius)
//        controllerView.layer.cornerRadius = CGFloat(controllerRadius)
        
        self.backgroundColor = .clear
        controllerView.backgroundColor = .white
        
        self.addSubview(controllerView)
        
        //constraints
        
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        
        controllerView.translatesAutoresizingMaskIntoConstraints = false
        
        controllerView.layer.borderWidth = 1
        controllerView.layer.borderColor = UIColor.black.cgColor
        
        NSLayoutConstraint.activate([
            controllerView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: controllerRadius),
            controllerView.heightAnchor.constraint(equalTo: controllerView.widthAnchor),
            controllerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            controllerView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        controllerView.addGestureRecognizer(panGesture)
        
        controllerViewCenter = .zero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.width/2
        
        self.controllerView.layer.cornerRadius = self.controllerView.frame.width/2
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    
    @objc private func handlePanGesture() {
        let translation = panGesture.translation(in: self)
        
        if panGesture.state == .began {
            // Save the view's original position.
            self.controllerViewCenter = controllerView.center
        }
        // Update the position for the .began, .changed, and .ended states
        if panGesture.state == .began || panGesture.state == .changed {
            // Add the X and Y translation to the view's original position.
            let newCenter = controllerViewCenter + translation
            if controllerViewCenter.distanceTo(newCenter) <= (viewRadius) {
                controllerView.center = newCenter
            } else { // Currently outside of the view
                let normalizedPoint = translation.normalized()
                controllerView.center = controllerViewCenter + normalizedPoint * maxControllerRadius
            }
        }
        else if panGesture.state == .ended || panGesture.state == .cancelled {
            controllerView.center = controllerViewCenter
        }
        
        if let delegate = delegate {
            delegate.joystickMoved(angle: currentControllerAngle, magnitude: magnitude)
        }
    }
    
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
