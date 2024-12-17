//
//  GameViewController2.swift
//  MobileSensing_FinalProject
//
//  Created by Arman Kamal on 12/10/24.
//

import UIKit
import SpriteKit

class BonusGameViewController: UIViewController {

    // create instance GameScene with size equal to view controller bounds
    lazy var scene:GameScene = {
        return GameScene(size: view.bounds.size)
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure the view is an SKView before casting
        guard let skView = view as? SKView else {
            fatalError("View of GameViewController is not an SKView")
        }

        //setup game scene
        //let skView = view as! SKView  // for rendenering SpriteKit scences (the view in storyboard must be an SKView)
        skView.showsFPS = true // show some debugging of the FPS in corner of the screen
        skView.showsNodeCount = true // show how many active objects/sprite are in the scene
        skView.ignoresSiblingOrder = true // don't track who entered scene first (i.e. ignore order of the nodes in the node heirarchy when rendering)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)  //repalce any currently presented scene with new scene (i.e. start the game)
    }

    
    // don't show the time and status bar (default behavior) at the top while game is running
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    /* move the score label to the right and left on the view controller by 10 units
    @IBAction func moveRight(_ sender: Any) {
        self.scene.moveScoreNode(by: 10)
    }
    
    @IBAction func moveLeft(_ sender: Any) {
        self.scene.moveScoreNode(by: -10)
    }
     */

}
