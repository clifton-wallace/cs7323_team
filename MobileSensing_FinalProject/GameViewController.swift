import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var captureSession: AVCaptureSession?   //Manages the flow of data from the camera
    private var videoDeviceInput: AVCaptureDeviceInput?  //Represents the camera device input
    private var previewLayer: AVCaptureVideoPreviewLayer!  //Displays the camera feed
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private var handPoints: [CGPoint] = []  //Stores the coordinates of detected hand points
    private let coordinateConfidence: Float = 0.5 //Confidence threshold for detected points
    private var shouldCaptureData = false  //to control data capture
    private var shouldPredict = false
    
    @IBOutlet weak var cameraView: UIView!  //displaying the camera feed
    @IBOutlet weak var gamesPlayedLabel: UILabel! //Number Of Games Played
    @IBOutlet weak var pointsLabel: UILabel! //Points Scored By User
    @IBOutlet weak var playButton: UIButton!     // Play button
    private var countdownLabel: UILabel!  // Count down label
    private var gameResultLabel: UILabel!  // Result / Outcome Of Game
    private var overlayView: UIView!  // View That Overlays Image
        
    var handPoseTimer: Timer?  //timer for generating a randomly chosen hand pose label
    var countdownTimer: Timer?  //count down timer
    let countdownValue: Int = 3  // 3 seconds countdown
    var points: Int = 0  // Points variable to track the user's points
    var games: Int = 0 // Number of games played
    
    let gameModel = GameModel() //Model Has Game Logic
    let scoringModel = ScoringModel() //Model Has Scoring Logic And Score Persistance
    private var handPosePredictor: HandPosePredictor!  //Prediction Class
    
    // Initialize Major UI Elements
    override func viewDidLoad() {
        super.viewDidLoad()
        handPosePredictor = HandPosePredictor(coordinateConfidence: coordinateConfidence) // Intialize Predictor
        setupCamera()  //initialize the camera
        setupUI()  //setup the UI elements
    }
    
    // Configure UI Elements
    private func setupUI() {
        self.updateScore()

    }
    
    // Configure Overlay
    // Trying To Create A More Game Like User Experiance
    // This Was Easier To Do In Code - A Lot Of Positioning Issues Using UI
    private func setupOverlay() {
        // Overlay Sits On Top of Camera
        let overlayView = UIView(frame: cameraView.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.addSubview(overlayView)
        overlayView.isHidden = true
        self.overlayView = overlayView
        
        // Countdown Label
        let countdownLabel = UILabel()
        countdownLabel.text = "3"
        countdownLabel.font = UIFont.systemFont(ofSize: 75, weight: .bold)
        countdownLabel.textColor = .yellow
        countdownLabel.textAlignment = .center
        countdownLabel.isHidden = true
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(countdownLabel)
        self.countdownLabel = countdownLabel
        
        // Game Result Label
        let gameResultLabel = UILabel()
        gameResultLabel.text = "Result"
        gameResultLabel.font = UIFont.systemFont(ofSize: 75, weight: .bold)
        gameResultLabel.textColor = .yellow
        gameResultLabel.textAlignment = .center
        gameResultLabel.isHidden = true
        gameResultLabel.translatesAutoresizingMaskIntoConstraints = false
        gameResultLabel.numberOfLines = 0
        gameResultLabel.lineBreakMode = .byWordWrapping
        overlayView.addSubview(gameResultLabel)
        self.gameResultLabel = gameResultLabel
        
        // Position Controls To Overlay
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
            
            countdownLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
                
            gameResultLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            gameResultLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
        ])
      

    }
    
    // Set Up Camera To Capture Video
    private func setupCamera() {
        // Changed To Prevent Blocking
        // To Address XCode Warning - Code From ChatGPT
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession = AVCaptureSession()  //initialize the capture session
            guard let captureSession = self.captureSession else { return }
            
            //try to get front camera as the input device
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  captureSession.canAddInput(videoDeviceInput) else {
                return
            }
            
            self.videoDeviceInput = videoDeviceInput  //add the video input to the capture session
            captureSession.addInput(videoDeviceInput)  //for capturing video frames from the captured video data
            
            //check if the capture session can accept the video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))  //set the viewcontroller as the delegate to handle sample video buffer
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput) //add video output to capture session to start receiving video data & send it to the view controller for processing
            }
            
            // Prepare preview layer on main thread
            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) //create layer to display live video feed from camera on screen
                self.previewLayer.videoGravity = .resizeAspect  //ensure that video fills the screen while maintining aspect ratio
                self.previewLayer.frame = self.cameraView.bounds
                self.cameraView.layer.addSublayer(self.previewLayer)  //add this layer as sublayer allowing the camera feed to be shown on screen
                
                self.setupOverlay() // Setup Overlay - Has To Be Here Or It Ends Up Behind The Camera View
            }
            captureSession.startRunning() //start the capture session
        }
    }
    
    // MARK: UI Event Handlers
    // Action for Play button
    // Start And Display Timer
    // When Timer Is Done, Capture User Gesture And Determine Winner
    @IBAction func playButtonTapped(_ sender: UIButton) {
        self.playButton.isEnabled = false  // Disable To Prevent Double Tap
        self.overlayView.isHidden = false  // Show Overlay
        
        var countdown = countdownValue
        showCountdown("READY!")
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
          
            if countdown > 0 {
                self.showCountdown("\(countdown)")
            }
            else if countdown == 0 {
                self.showCountdown("GO!")
                self.shouldPredict = true
            }
            else {
                     timer.invalidate()
                     self.shouldPredict = false
                     
                     // Check if hand is detected after countdown finishes
                if self.handPoints.isEmpty{
                         self.showNoHandDetectedAlert()
                    self.resetScreen();
                     }
                 }
            self.handPoints.removeAll()
            countdown -= 1
        }
    }
    
    // Helper function to display an alert
    func showNoHandDetectedAlert() {
        print("DEBUG: Showing alert!") // Debugging log
        let alert = UIAlertController(title: "No Hand Detected",
                                       message: "Please ensure your hand is visible to the camera and try again.",
                                       preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    // MARK: UI Functions
  
    // Reset Overlay Values
    func resetScreen() {
        self.countdownLabel?.text = "\(countdownValue)"
        self.countdownLabel?.isHidden = true
        
        self.gameResultLabel?.text = ""
        self.gameResultLabel?.isHidden = false
        
        self.overlayView.isHidden = true
        
        self.playButton.isEnabled = true
    }
    
    // Show Countdown - Displays Countdown Label And Hides Other Controls
    func showCountdown(_ countdown: String) {
        DispatchQueue.main.async {
            self.countdownLabel?.isHidden = true
            self.countdownLabel?.text = "" // Clear
            self.countdownLabel?.text = countdown
            self.countdownLabel?.isHidden = false
            self.gameResultLabel?.isHidden = true
        }
    }
    
    // Show Result Of Game
    func showResult(userGesture: String, cpuGesture: String, result: String) {
        DispatchQueue.main.async {
            let displayResult = """
            \(result)
            You: \(userGesture)
            CPU: \(cpuGesture)
            """
            
            self.countdownLabel?.isHidden = true
            self.gameResultLabel?.text = displayResult
            self.gameResultLabel?.isHidden = false
            
            // Reset the screen after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.resetScreen()
            }
        }
    }
    
    // Updates The Score And Games On Tghe Screen
    func updateScore() {
        let formattedScore = String(format: "%05d", self.points)
        let formattedGames = String(format: "%05d", self.games)

        DispatchQueue.main.async {
            self.pointsLabel?.text = "Score: \(formattedScore)"
            self.gamesPlayedLabel?.text = "Games: \(formattedGames)"
            
            if let segueTemplates = self.value(forKey: "storyboardSegueTemplates") as? [NSObject] {
                for template in segueTemplates {
                    print("Segue identifier: \(template.value(forKey: "identifier") ?? "No identifier")")
                }
            }

            // Show Every 2 Consecutive Wins
            if self.points >= 20 && self.points % 20 == 0 {
                self.startGame()
            }
        }
    }
  
    // Trigger Bonus Game
    func startGame() {
        print("Game Started")
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "startGameSegue", sender: self)
        }
    }
    
    // MARK: Game Functions
    // Capture Gestures And Play Game
    func playGame(target: String) -> GameResult {
        let cpuGesture = gameModel.randomHandPose()
        
        guard let userGesture = GameModel.MapPose(input: target) else {
            // Should Not Get Here
            print("Invalid input. Unable to determine user's hand pose.")
            return GameResult(outcome: GameOutcome.invalidInput, userGesture: HandPose.unknown, cpuGesture: cpuGesture)
        }

        let result = gameModel.determineWinner(userGesture: userGesture, cpuGesture: cpuGesture)
        showResult(userGesture: result.userGesture.rawValue, cpuGesture: result.cpuGesture.rawValue, result: result.outcome.rawValue)
        
        scoringModel.addGameResult(GameResult(outcome: result.outcome, userGesture: userGesture, cpuGesture: cpuGesture))
        self.points = scoringModel.currentScore
        self.games += 1
        updateScore()
        
        return result
    }
       
    //MARK: -- Detection of Hand Pose
    // Capture Video And Process Hand Pose Data
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Extract the pixel buffer from the sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]) // Create img request handler to perform vision request on img data
        do {
            try requestHandler.perform([handPoseRequest]) // Try to perform hand pose request using the img handler
            
            // Check if the request has results with observations
            if let observations = handPoseRequest.results, !observations.isEmpty {
                let observation = observations.first! // Assuming only one hand is detected
                if shouldPredict {
                    if let target = handPosePredictor.predict(observation: observation) {
                        print("Gesture: \(target)")
                        _ = self.playGame(target: target)
                    }
                    shouldPredict = false
                }
                processHandPose(observation)  // Process to show position on the screen
                
            }
        } catch {
            print("Error performing hand pose request: \(error)")
        }
    }
    
    // Capture Data And Update Screen
    private func processHandPose(_ observation: VNHumanHandPoseObservation) {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return } // Get recognized points from the observation
        
        handPoints.removeAll() // Clear the points first
        
        // From each recognized point, check if its confidence > 50%, then only add them to the handPoints array
        for (_, point) in recognizedPoints {
            if point.confidence > coordinateConfidence {
                handPoints.append(point.location)
            }
        }
        
        DispatchQueue.main.async {
            //self.displayHandPoints() // Display the hand points
        }
    }
       
    //display red circles at hand points for visual feedback
    private func displayHandPoints() {
        cameraView.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })  //to ensure old hand points are cleared before drawing new ones
        
        guard let previewLayer = previewLayer else { return }  //ensure that preview layer is not nil
        
        //iterate over each hand point
        for point in handPoints {
            let normalizedPoint = CGPoint(x: point.x, y: 1 - point.y)  //invert y coordinates of normalized point from vision framework for visualization
            let convertedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)  //convert normalized points to coordinate space of preview layer
            
            let circleLayer = CAShapeLayer()  //create new shaper layer for each hand point
            
            // circular path of 5 pts radius and fill color as red going clockwise
            let circlePath = UIBezierPath(
                arcCenter: convertedPoint,
                radius: 5,
                startAngle: 0,
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = UIColor.red.cgColor
            cameraView.layer.addSublayer(circleLayer)  //overlay circles on hand joints
        }
    }
        
}
    

