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
    var controllerRadius: CGFloat!
    var controllerViewCenter: CGPoint!
    
    var panGesture: UIPanGestureRecognizer!
    
    
    var viewRadius: CGFloat {
        return self.frame.height / 2
    }
    
    var viewCenter: CGPoint {
        return CGPoint(x: self.frame.width/2, y: self.frame.width/2)
    }
    
    var maxControllerRadius: CGFloat {
        get {
            return viewRadius
        }
    }
    
    var currentControllerAngle: CGFloat {
        return atan2(viewCenter.y - self.controllerView.center.y, viewCenter.x - self.controllerView.center.x);
    }
    
    var currentControllerRadius: CGFloat {
        return viewCenter.distanceTo(controllerView.center)
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
    
    @objc func handlePanGesture() {
        let translation = panGesture.translation(in: self)
        
        if panGesture.state == .began {
            // Save the view's original position.
            self.controllerViewCenter = controllerView.center
        }
        // Update the position for the .began, .changed, and .ended states
        if panGesture.state == .began || panGesture.state == .changed {
            // Add the X and Y translation to the view's original position.
            let newCenter = CGPoint(x: controllerViewCenter.x + translation.x, y: controllerViewCenter.y + translation.y)
            if controllerViewCenter.distanceTo(newCenter) <= (viewRadius) {
                print(translation)
                controllerView.center = newCenter
            }
        }
        else if panGesture.state == .ended || panGesture.state == .cancelled {
            controllerView.center = controllerViewCenter
        }
        
        if let delegate = delegate {
            delegate.joystickMoved(angle: currentControllerAngle, magnitude: currentControllerRadius / maxControllerRadius)
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

extension CGPoint {
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return CGFloat(sqrt(pow(self.x - point.x, 2) + pow(self.y - point.y, 2)))
    }
}
