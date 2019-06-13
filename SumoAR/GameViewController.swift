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
    
    
    var mcSession: MCSession!
    var isHost: Bool!
    
    @IBOutlet var arView: ARView!
    
    let bounds: Float = 0.4
    var ball: ModelEntity!
    var arena: ModelEntity!
    
    var hasCreatedMap = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        createNetwork()
    }
    
    func createNetwork() {
        let gameName = "enzo-sumo-game"
        let myPeerID = MCPeerID(displayName: UIDevice.current.name)
        
        mcSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self

//        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController
//
//        while let presentedViewController = topMostViewController?.presentedViewController {
//            topMostViewController = presentedViewController
//        }
//
//        print(topMostViewController)
        
        if isHost {
            let advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: gameName)
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()
            
            print("Advertising!")
            
        } else {
            let browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: gameName)
            browser.delegate = self
            
        //self.present(MCBrowserViewController(browser: browser, session: mcSession), animated: true)
            browser.startBrowsingForPeers()
            
            print("Browsing!")
        }
        
        
        arView.scene.synchronizationService = try? MultipeerConnectivityService(session: mcSession)
    }
    
    func createMap(anchor: AnchorEntity) {
        
        let arenaHeight: Float = bounds * 1.3
        let arenaDiameter: Float = bounds
        
        //creates supporting plane
        let planeMesh = MeshResource.generateBox(width: arenaDiameter*1.5, height: 0.01, depth: arenaDiameter*1.5)
        
        let planeMaterial = SimpleMaterial(color: .black, isMetallic: true)//OcclusionMaterial()
        
        let planeShape = ShapeResource.generateBox(width: arenaDiameter, height: 0.01, depth: arenaDiameter)
        
        let plane = ModelEntity(mesh: planeMesh, materials: [planeMaterial], collisionShape: planeShape, mass: 1)
        
        plane.physicsBody?.isTranslationLocked = (x: true, y: true, z: true)
        plane.physicsBody?.isRotationLocked = (x: true, y: true, z: true)
        //plane.physicsBody?.mode = .static
        plane.position = SIMD3(x: 0, y: -0.3, z: 0)
        
        anchor.addChild(plane)
        //creates arena
        
        let arenaMesh = MeshResource.generateBox(width: arenaDiameter, height: arenaHeight, depth: arenaDiameter)
        
        let arenaMaterial = SimpleMaterial(color: .red, isMetallic: true)
        
        let arenaShape = ShapeResource.generateBox(width: arenaDiameter, height: arenaHeight, depth: arenaDiameter)
        
        let arena = ModelEntity(mesh: arenaMesh, materials: [arenaMaterial], collisionShape: arenaShape, mass: 100)
        
        arena.position = SIMD3(x: 0, y: arenaHeight/2 + 0.001, z: 0)
        
        anchor.addChild(arena)
        
        //creates ball
        ball = try! Entity.loadModel(named: "soccerBall")
        
        
        ball.generateCollisionShapes(recursive: true)
        let ballPhysics = PhysicsBodyComponent(massProperties: PhysicsMassProperties(mass: 0.2), material: .default, mode: .dynamic)
        ball.physicsBody = ballPhysics
        
        let ballY = arenaHeight + 0.4 //0.002
        
        //print(((ball.model?.mesh.bounds.radius)! * 2))
        //print(ballY)
        //ball.scale = SIMD3(repeating: 0.5)
        ball.setScale(SIMD3(repeating:0.03), relativeTo: arena)
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
                ball.applyLinearImpulse(SIMD3(x: 0, y: 0.003, z: 0), relativeTo: nil)
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
            
//            let anchorEntity = AnchorEntity(anchor: arAnchor)
//            arView.scene.addAnchor(anchorEntity)
            
            createMap(anchor: anchorEntity)
            
            hasCreatedMap = true
        }
    }
    
}

extension GameViewController : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("received invitation")
        invitationHandler(true, self.mcSession)
        advertiser.stopAdvertisingPeer()
    }
    
}



extension GameViewController : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer", peerID)
        browser.invitePeer(peerID, to: self.mcSession, withContext: nil, timeout: 10)
        browser.stopBrowsingForPeers()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    
    
}


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
