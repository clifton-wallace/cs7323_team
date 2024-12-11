//
//  GameScene.swift
//  MobileSensing_FinalProject
//
//  Created by Arman Kamal on 12/10/24.
//


import SpriteKit
import CoreMotion
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0
    var playAgainButton: SKLabelNode!
    var isGameOver = false
    
    // Timer variables to track time for score updates
    var lastUpdateTime: TimeInterval = 0
    var timeSinceLastScoreUpdate: TimeInterval = 0
    let scoreUpdateInterval: TimeInterval = 5 // Update score every 5 seconds
    
    // Jump variables
    let jumpImpulse: CGFloat = 20.0
    
    // Falling obstacle properties
    let obstacleSpawnInterval: TimeInterval = 2.0 // New obstacle every 2 seconds
    var timeSinceLastObstacle: TimeInterval = 0
    
    // Background music player
    var backgroundMusicPlayer: AVAudioPlayer?
    
    // Motion manager for device motion updates
    let motionManager = CMMotionManager()
    
    var activeObstacles: Int = 0 // Track the current number of active obstacles
    let baseObstacleCount: Int = 1 // Base number of obstacles to spawn

    
    override func didMove(to view: SKView) {
        // Set up physics world and delegate for collision detection
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8) // Default gravity
        
        // Set up the player using an image
        player = SKSpriteNode(imageNamed: "player") // Use the player image
        player.size = CGSize(width: 50, height: 50) // Set the size of the player
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false // Prevents the player from rotating
        player.physicsBody?.categoryBitMask = 0x1 << 0 // Player's category bitmask
        player.physicsBody?.contactTestBitMask = 0x1 << 1 // Detect contact with obstacles
        player.physicsBody?.collisionBitMask = 0 // No physical collision
        addChild(player)
        
        // Set up score label
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 90)
        addChild(scoreLabel)
        
        // Add the play again button but hide it initially
        playAgainButton = SKLabelNode(fontNamed: "Arial")
        playAgainButton.text = "Play Again"
        playAgainButton.fontSize = 36
        playAgainButton.fontColor = .green
        playAgainButton.position = CGPoint(x: size.width / 2, y: size.height / 2)
        playAgainButton.isHidden = true
        addChild(playAgainButton)
        
        
        // Play background music
        playBackgroundMusic()
        
        // Start device motion updates
        startDeviceMotionUpdates()
    }
    
    
    // Play background music
    func playBackgroundMusic() {
        if let musicURL = Bundle.main.url(forResource: "GameMusic", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1 // Loop infinitely
                backgroundMusicPlayer?.play()
            } catch {
                print("Error playing background music: \(error)")
            }
        }
    }
    

    // Start device motion updates
    func startDeviceMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
                    motionManager.deviceMotionUpdateInterval = 0.1 // Update interval in seconds
                    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                        guard let self = self, let data = data else { return }
                        self.updatePlayerPosition(with: data)
                        self.handleGyroData(rotation: data.rotationRate)
                        self.handleMagnetometerData(magneticField: data.magneticField)
                    }
                }
    }
    //Handle Gyro
    func handleGyroData(rotation: CMRotationRate) {
        let rotationSensitivity: CGFloat = 5.0
        player.zRotation += CGFloat(rotation.y) * rotationSensitivity
    }
    func handleMagnetometerData(magneticField: CMCalibratedMagneticField) {
            let tiltSensitivity: CGFloat = 0.01 // Adjust sensitivity
        player.position.x += CGFloat(magneticField.field.x) * tiltSensitivity
        }
    
    // Update player position based on device motion
    //Fused motion
    func updatePlayerPosition(with motionData: CMDeviceMotion) {
           // Access the user acceleration and combine it with gravity
           let acceleration = motionData.userAcceleration
           let gravity = motionData.gravity
           
           // Combine user acceleration with gravity for more realistic movement
           let combinedAcceleration = CGVector(dx: acceleration.x + gravity.x, dy: acceleration.y + gravity.y)
           
           // Update player position
           player.position.x += CGFloat(combinedAcceleration.dx * 20) // Adjust multiplier for sensitivity
           player.position.y += CGFloat(combinedAcceleration.dy * 20)
           
           // Keep player within screen bounds
           player.position.x = max(min(player.position.x, size.width), 0)
           player.position.y = max(min(player.position.y, size.height), 0)
       }


    // Spawn a new falling obstacle
    func spawnObstacle() {
        let obstacle = SKShapeNode(circleOfRadius: 20) // Create a circle shape
        obstacle.fillColor = .red // Set the color of the sphere
        obstacle.strokeColor = .clear
        // Spawn the obstacle at a random position along the top of the screen
        let xPosition = CGFloat.random(in: 0..<size.width)
        obstacle.position = CGPoint(x: xPosition, y: size.height)
        
        // Add physics to the obstacle to make it fall
        obstacle.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        obstacle.physicsBody?.isDynamic = true
        obstacle.physicsBody?.categoryBitMask = 0x1 << 1 // Obstacle's category bitmask
        obstacle.physicsBody?.contactTestBitMask = 0x1 << 0 // Detect contact with the player
        obstacle.physicsBody?.collisionBitMask = 0 // No physical collision
        addChild(obstacle)
        
        // Set the obstacle's linear velocity (making it fall faster or slower)
        obstacle.physicsBody?.velocity = CGVector(dx: 0, dy: -500)
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        // Track the time elapsed since the last frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Update score timer
        timeSinceLastScoreUpdate += deltaTime
        timeSinceLastObstacle += deltaTime

        // Update score
        if timeSinceLastScoreUpdate >= scoreUpdateInterval {
            score += 1
            scoreLabel.text = "Score: \(score)"
            timeSinceLastScoreUpdate = 0 // Reset timer
        }

        // Spawn obstacles
        if timeSinceLastObstacle >= obstacleSpawnInterval {
            spawnObstacle()
            timeSinceLastObstacle = 0
        }

        // Detect if player goes off-screen
        if player.position.y < 0 || player.position.x < 0 || player.position.x > size.width || player.position.y > size.height {
            gameOver() // End the game if player falls off the screen
        }
    }


    // Handle touches for jumping and restarting the game
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            for touch in touches {
                let location = touch.location(in: self)
                if playAgainButton.contains(location) {
                    restartGame()
                }
            }
        } else {
            // Jump logic: Apply an upward impulse to the player
            if let playerPhysicsBody = player.physicsBody {
                playerPhysicsBody.velocity = CGVector(dx: 0, dy: 0) // Reset vertical velocity before applying impulse
                playerPhysicsBody.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
            }
        }
    }

    // Detect collision between player and obstacle
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == 0x1 << 0 && bodyB.categoryBitMask == 0x1 << 1) ||
           (bodyB.categoryBitMask == 0x1 << 0 && bodyA.categoryBitMask == 0x1 << 1) {
            gameOver()
        }
    }

    // Stop the game and show "Play Again" button
    func gameOver() {
        isGameOver = true
        physicsWorld.speed = 0 // Stop physics simulation
        player.physicsBody?.isDynamic = false // Stop player movement
        playAgainButton.isHidden = false // Show play again button
        stopBackgroundMusic() // Stop background music
    }

    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
        
       override func willMove(from view: SKView) {
           motionManager.stopDeviceMotionUpdates()
       }

    // Restart the game
    func restartGame() {
        isGameOver = false
        score = 0
        scoreLabel.text = "Score: \(score)"
        playAgainButton.isHidden = true
        physicsWorld.speed = 1 // Resume physics simulation
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.physicsBody?.isDynamic = true
        lastUpdateTime = 0 // Reset the last update time
        timeSinceLastScoreUpdate = 0 // Reset the score timer
        
        // Remove all obstacles from the scene
        enumerateChildNodes(withName: "//*") { node, _ in
            if node != self.player && node != self.scoreLabel && node != self.playAgainButton {
                node.removeFromParent()
            }
        }
        
        // Restart background music
        playBackgroundMusic()
    }
}
