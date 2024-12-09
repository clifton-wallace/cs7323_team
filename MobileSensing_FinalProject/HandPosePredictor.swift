import CoreML
import Vision

// Class Contains Logic To Perform Prediction Of Hand Pose
class HandPosePredictor {
    //Maps joint names from Vision framework to human-readable names
    private let jointNameMapping: [String: String] = [
        "VNHLKTTIP": "thumbTip",
        "VNHLKTIP": "thumbIP",
        "VNHLKTMP": "thumbMP",
        "VNHLKTCMC": "thumbCMC",
        "VNHLKITIP": "indexTip",
        "VNHLKIDIP": "indexDIP",
        "VNHLKIPIP": "indexPIP",
        "VNHLKIMCP": "indexMCP",
        "VNHLKMTIP": "middleTip",
        "VNHLKMDIP": "middleDIP",
        "VNHLKMIP": "middlePIP",
        "VNHLKMMCP": "middleMCP",
        "VNHLKRTIP": "ringTip",
        "VNHLKRDIP": "ringDIP",
        "VNHLKRPIP": "ringPIP",
        "VNHLKRMCP": "ringMCP",
        "VNHLKPTIP": "pinkyTip",
        "VNHLKPDIP": "pinkyDIP",
        "VNHLKPPIP": "pinkyPIP",
        "VNHLKPMCP": "pinkyMCP",
        "VNHLKWRI": "wrist"
    ]
    
    private let coordinateConfidence: Float
    private let boostedTree: BoostedTree
    
    init(coordinateConfidence: Float) {
        self.coordinateConfidence = coordinateConfidence
        self.boostedTree = try! BoostedTree(configuration: MLModelConfiguration())
    }
    
    // Process Observation and Return Prediction
    func predict(observation: VNHumanHandPoseObservation) -> String? {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return nil }
        
        var featureVector: [Double] = []
        
        // Sort points and map to features
        let sortedPoints = recognizedPoints
            .map { (jointName, point) -> (String, CGPoint) in
                let humanReadableName = jointNameMapping[jointName.rawValue.rawValue] ?? jointName.rawValue.rawValue
                if point.confidence > coordinateConfidence {
                    return (humanReadableName, point.location)
                } else {
                    return (humanReadableName, CGPoint(x: 0, y: 0))
                }
            }
            .sorted { $0.0 < $1.0 }

        for (_, location) in sortedPoints {
            featureVector.append(Double(location.x))
            featureVector.append(Double(location.y))
        }
        
        // Convert features to MLMultiArray
        guard let multiArray = try? MLMultiArray(shape: [NSNumber(value: featureVector.count)], dataType: .double) else {
            print("Error: Could not create MLMultiArray")
            return nil
        }
        for (index, value) in featureVector.enumerated() {
            multiArray[index] = NSNumber(value: value)
        }

        // Predict using BoostedTree
        do {
            let input = BoostedTreeInput(sequence: multiArray)
            let prediction = try boostedTree.prediction(input: input)
            return prediction.target
        } catch {
            print("Error during boosted_tree prediction: \(error)")
            return nil
        }
    }
}
