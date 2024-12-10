import Foundation

// Struct That Represents Data Saved
// Stores Games Played And Results
// And Gestures
struct ScoringData: Codable {
    var games: [GameResult]
    var gestureCounts: [HandPose: Int]
    var highScore: Int
}

// Manages Storing Score Information Between Sessions
class ScoringModel {
    private let plistFileName = "Scores.plist"
    private var games: [GameResult] = []
    private var gestureCounts: [HandPose: Int] = [:]
    
    // High Score Data
    private var currentScorePersist: Int = 0
    private var highScorePersist: Int = 0
    
    // MARK: Properties
    // Metrics Pulled From Stored Data Arrays
    var gamesPlayed: Int {
        return games.count
    }
    
    var highScore: Int {
        return highScorePersist
    }
    
    var currentScore: Int {
        return currentScorePersist
    }
    
    var longestWinningStreak: Int {
        return calculateStreak(for: .win)
    }
    
    var longestLosingStreak: Int {
        return calculateStreak(for: .lose)
    }
    
    var longestTieStreak: Int {
        return calculateStreak(for: .tie)
    }
    
    var mostCommonGesture: HandPose? {
        return gestureCounts.max(by: { $0.value < $1.value })?.key
    }
  
    
    // Constructor Loads Data
    init() {
        loadData()
    }
    
    // MARK: Public Methods
    // Store Results Of Game
    func addGameResult(_ result: GameResult) {
        // Update Result History
        games.append(result)
        updateGestureCounts(for: result.userGesture)
        
        // Calc New Score
        var scoreChange: Int = 0
        if result.outcome == .win {
            scoreChange = 10
        } else if result.outcome == .lose {
            scoreChange = -10
        }
        
        // Store Current And High Score
        currentScorePersist += scoreChange
        if currentScorePersist > highScorePersist {
            highScorePersist = currentScorePersist
        }
        
        saveData()
    }
    
    // Reset the scoring data
    func reset() {
        games.removeAll()
        gestureCounts.removeAll()
        currentScorePersist = 0
        highScorePersist = 0
        saveData()
    }
    
    // MARK: Persist Methods
    // Save Data To PList
    private func saveData() {
        let scoringData = ScoringData(games: games, gestureCounts: gestureCounts, highScore: highScorePersist)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        if let data = try? encoder.encode(scoringData) {
            let fileURL = getPlistURL()
            try? data.write(to: fileURL)
        }
    }
    
    // Retrieve Data From PList
    private func loadData() {
        let fileURL = getPlistURL()
        let decoder = PropertyListDecoder()
        
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode(ScoringData.self, from: data) {
            self.games = decoded.games
            self.gestureCounts = decoded.gestureCounts
            self.highScorePersist = decoded.highScore
        }
    }
    
    // MARK: Helper Methods
    // Get Path To PList
    private func getPlistURL() -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(plistFileName)
    }
    
    // Update Array Of Gestures
    private func updateGestureCounts(for gesture: HandPose) {
        gestureCounts[gesture, default: 0] += 1
    }
    
    // Gets The Longest Streak For The Given Outcome
    private func calculateStreak(for outcome: GameOutcome) -> Int {
        var maxStreak = 0
        var currentStreak = 0
        
        for game in games {
            if game.outcome == outcome {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
}

