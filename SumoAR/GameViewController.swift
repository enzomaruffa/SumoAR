//
//  GameViewController.swift
//  SumoAR
//
//  Created by Enzo Maruffa Moreira on 12/06/19.
//  Copyright © 2019 Enzo Maruffa Moreira. All rights reserved.
//

import UIKit
import ARKit
import RealityKit
import MultipeerConnectivity

class GameViewController: UIViewController {

    
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var isHost: Bool!
    
    @IBOutlet var arView: ARView!
    
    let bounds: Float = 0.4
    var ball: ModelEntity!
    var map: ModelEntity!
    
    var arena: ModelEntity!
    
    var hasCreatedMap = false
    
    var joystickView: Joystick!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        arView.scene.subscribe(to: SceneEvents.Update.self, { event in
            self.updateBall()
        } )
        
        ball = try! Entity.loadModel(named: "soccerBall")
        map = try! Entity.loadModel(named: "map")
        
        createJoystick()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        createNetwork()
    }
    
    func createJoystick() {
        joystickView = Joystick(borderWidth: 5, controllerRadius: 0.4)
        
        joystickView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(joystickView)
        
        NSLayoutConstraint.activate([
            joystickView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20),
            joystickView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            joystickView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.4),
            joystickView.heightAnchor.constraint(equalTo: joystickView.widthAnchor)
        ])
    }
    
    func createNetwork() {
        guard self.mcSession == nil else {
            return
        }
        
        let gameName = "enzo-sumo"
        let myPeerID = MCPeerID(displayName: UIDevice.current.name)
        
        self.mcSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.mcSession!.delegate = self

//        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController
//
//        while let presentedViewController = topMostViewController?.presentedViewController {
//            topMostViewController = presentedViewController
//        }
//
//        print(topMostViewController)
        
        if isHost {
//            let advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: gameName)
//            advertiser.delegate = self
//            advertiser.startAdvertisingPeer()
            
            mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: gameName, discoveryInfo: nil, session: self.mcSession!)
            mcAdvertiserAssistant.start()
            
            print("Advertising!")
            
        } else {
//            let browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: gameName)
//            browser.delegate = self
//            browser.startBrowsingForPeers()
            
            let mcBrowser = MCBrowserViewController(serviceType: gameName, session: self.mcSession!)
            mcBrowser.delegate = self
            present(mcBrowser, animated: true)
            
            print("Browsing!")
        }
        
        
        arView.scene.synchronizationService = try? MultipeerConnectivityService(session: self.mcSession!)
    }
    
    func createMap(anchor: AnchorEntity) {
        
        let arenaHeight: Float = bounds * 1.3
        let arenaDiameter: Float = bounds
        
        let planeDiameter = arenaDiameter*100
        
        //creates supporting plane
        let planeMesh = MeshResource.generateBox(width: planeDiameter, height: 0.01, depth: planeDiameter)
        
        let planeMaterial = SimpleMaterial(color: .white, isMetallic: false)//OcclusionMaterial()
        
        let planeShape = ShapeResource.generateBox(width: planeDiameter, height: 0.01, depth: planeDiameter)
        
        let plane = ModelEntity(mesh: planeMesh, materials: [planeMaterial], collisionShape: planeShape, mass: 1)
        
        plane.physicsBody?.isTranslationLocked = (x: true, y: true, z: true)
        plane.physicsBody?.isRotationLocked = (x: true, y: true, z: true)
        plane.position = SIMD3(x: 0, y: 0, z: 0)
        
        anchor.addChild(plane)
        
//        let arenaMesh = MeshResource.generateBox(width: arenaDiameter, height: arenaHeight, depth: arenaDiameter)
//
//        let arenaMaterial = SimpleMaterial(color: .red, isMetallic: true)
//
//        let arenaShape = ShapeResource.generateBox(width: arenaDiameter, height: arenaHeight, depth: arenaDiameter)
//
//        let arena = ModelEntity(mesh: arenaMesh, materials: [arenaMaterial], collisionShape: arenaShape, mass: 100)
//
//        arena.position = SIMD3(x: 0, y: arenaHeight/2 + 0.001, z: 0)
//
//        anchor.addChild(arena)
        
        map.generateCollisionShapes(recursive: true)
        let mapPhysics = PhysicsBodyComponent(shapes: map.collision!.shapes, mass: 10000, material: .default, mode: .dynamic)
        map.physicsBody = mapPhysics
        
        let mapY = Float(-0.3)//0.002
        
        map.setScale(SIMD3(repeating:0.1), relativeTo: arena)
        print(map.scale(relativeTo: arena))
        
        map.position = SIMD3(x: 0, y: mapY, z: 0)
        map.name = "map"
        
        anchor.addChild(map)
        
        
        //creates ball
        
        ball.generateCollisionShapes(recursive: true)
        let ballPhysics = PhysicsBodyComponent(massProperties: PhysicsMassProperties(mass: 0.2), material: .default, mode: .dynamic)
        ball.physicsBody = ballPhysics
        
        let ballY = arenaHeight + 0.4 //0.002
        
        ball.setScale(SIMD3(repeating:0.02), relativeTo: arena)
        print(ball.scale(relativeTo: arena))
        
        ball.position = SIMD3(x: 0, y: ballY, z: 0)
        ball.name = "ball"
        
        anchor.addChild(ball)
    }
    
    @IBAction func tapDone(_ sender: UITapGestureRecognizer) {
        
        if !isHost || hasCreatedMap {
            let tapLocation = sender.location(in: arView)
            
            let entities = arView.entities(at: tapLocation)
            
            if let ball = entities.filter( {$0.name == "ball"} ).first as? ModelEntity {
                
                if !isHost {
                    ball.requestOwnership { result in
                        if result == .granted {
                            ball.applyLinearImpulse(SIMD3(x: 0, y: 0.003, z: 0), relativeTo: nil)
                        }
                    }
                    
                } else {
                    ball.applyLinearImpulse(SIMD3(x: 0, y: 0.003, z: 0), relativeTo: nil)
                }
            }
            
        } else {
            
            print("Trying to create map")
            
            guard let result = arView.raycast(from: sender.location(in: arView), allowing: .estimatedPlane, alignment: .horizontal).first else {
                print("Can't create!")
                return
            }
            
            print("Creating")
            
            // creates anchor
            let arAnchor = ARAnchor(name: "gameAnchor", transform: result.worldTransform)
            print(result.worldTransform)
            arView.session.add(anchor: arAnchor)
            
            
            let anchorEntity = AnchorEntity(raycastResult: result)
            arView.scene.addAnchor(anchorEntity)
            
            createMap(anchor: anchorEntity)
            
            hasCreatedMap = true
        }
    }
    
    func updateBall() {
        
        let magnitude = joystickView.magnitude
        let angle = joystickView.currentControllerAngle
        
        if magnitude == 0 {
            return
        }
        
        //angle 0 = forward
        //angle pi/4 = left
        //angle pi/2 = backwards
        //angle 3pi/2 = right
        
        //get direction that camera is facing. y axis is not important.
        let cameraTransform = arView.cameraTransform
        let cameraDirection = cameraTransform.rotation.axis
        //let cameraPosition = cameraTransform.translation
        
        var ballForwardDirection = (cameraDirection)
        let ballForwardDirectionLength = sqrt(ballForwardDirection.x * ballForwardDirection.x + ballForwardDirection.y * ballForwardDirection.y + ballForwardDirection.z * ballForwardDirection.z)
        ballForwardDirection = SIMD3(x: ballForwardDirection.x/ballForwardDirectionLength, y: ballForwardDirection.y/ballForwardDirectionLength, z: ballForwardDirection.z / ballForwardDirectionLength)
        
        let leftX = Float(ballForwardDirection.x * cos(Float.pi * 1.5) - ballForwardDirection.z * sin(Float.pi * 1.5))
        let leftZ = Float(ballForwardDirection.x * sin(Float.pi * 1.5) - ballForwardDirection.z * cos(Float.pi * 1.5))
        
        let ballLeftDirection = SIMD3(x: leftX, y: 0, z: leftZ)
        
        let forwardAmount = Float(cos(angle*2))
        let leftAmount = Float(sin(angle*2))
        
        // angulo 0: sin 0, cos 1
        
        print("angle", angle*2)
        print("forwardAmount", forwardAmount)
        print("leftAmount", leftAmount)
        
        let forceVector = forwardAmount * ballForwardDirection +  leftAmount * ballLeftDirection
        
        print(forceVector)
        //clear forces
        let maxForceUnit = -CGFloat(0.01)
        let forceUnit = Float(magnitude * maxForceUnit)
        
        let force = SIMD3(x: forceVector.x * forceUnit, y: 0.0001, z: forceVector.z * forceUnit)
        
        //apply force proportional to magnitude
        ball.addForce(force, relativeTo: nil)
        //
        print("Joystick moved! Angle: ", angle, ", magnitude: ", magnitude)
        
    }
    
    @IBAction func jumpPressed(_ sender: Any) {
        ball.applyLinearImpulse(SIMD3(x: 0, y: 0.002, z: 0), relativeTo: nil)
    }
}

//extension GameViewController : MCNearbyServiceAdvertiserDelegate {
//
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        print("Received invitation")
//        invitationHandler(true, self.mcSession)
//        advertiser.stopAdvertisingPeer()
//    }
//
//}

extension GameViewController : MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
}
//
//
//extension GameViewController : MCNearbyServiceBrowserDelegate {
//
//    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
//        print("Found peer", peerID)
//        browser.invitePeer(peerID, to: self.mcSession!, withContext: nil, timeout: 10)
//        browser.stopBrowsingForPeers()
//    }
//
//    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
//
//    }
//
//
//}


extension GameViewController : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }

    
}

extension GameViewController : JoystickDelegate {
    
    func joystickMoved(angle: CGFloat, magnitude: CGFloat) {
        
        if magnitude == 0 {
            return
        }
        
        //angle 0 = forward
        //angle pi/4 = left
        //angle pi/2 = backwards
        //angle 3pi/2 = right
        
        //get direction that camera is facing. y axis is not important.
        let cameraTransform = arView.cameraTransform
        let cameraDirection = cameraTransform.rotation.axis
        //let cameraPosition = cameraTransform.translation
        
        var ballForwardDirection = (cameraDirection)
        let ballForwardDirectionLength = sqrt(ballForwardDirection.x * ballForwardDirection.x + ballForwardDirection.y * ballForwardDirection.y + ballForwardDirection.z * ballForwardDirection.z)
        ballForwardDirection = SIMD3(x: ballForwardDirection.x/ballForwardDirectionLength, y: ballForwardDirection.y/ballForwardDirectionLength, z: ballForwardDirection.z / ballForwardDirectionLength)
        
        let leftX = Float(ballForwardDirection.x * cos(Float.pi * 1.5) - ballForwardDirection.z * sin(Float.pi * 1.5))
        let leftZ = Float(ballForwardDirection.x * sin(Float.pi * 1.5) - ballForwardDirection.z * cos(Float.pi * 1.5))
        
        let ballLeftDirection = SIMD3(x: leftX, y: 0, z: leftZ)
        
        let forwardAmount = Float(cos(angle*2))
        let leftAmount = Float(sin(angle*2))
        
        // angulo 0: sin 0, cos 1
        
        print("angle", angle*2)
        print("forwardAmount", forwardAmount)
        print("leftAmount", leftAmount)
        
        let forceVector = forwardAmount * ballForwardDirection +  leftAmount * ballLeftDirection
        
        print(forceVector)
        //clear forces
        let maxForceUnit = -CGFloat(0.01)
        let forceUnit = Float(magnitude * maxForceUnit)
        
        let force = SIMD3(x: forceVector.x * forceUnit, y: 0.0001, z: forceVector.z * forceUnit)
        
        //apply force proportional to magnitude
        ball.addForce(force, relativeTo: nil)
        //
        print("Joystick moved! Angle: ", angle, ", magnitude: ", magnitude)
    }
    
}

// SIMD3 extension
