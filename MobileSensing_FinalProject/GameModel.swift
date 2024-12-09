import Foundation

// Stores Result Of A Game
struct GameResult {
    let outcome: GameOutcome
    let userGesture: HandPose
    let cpuGesture: HandPose
}

// Possible Gestures For Game
enum HandPose: String, CaseIterable {
    case rock = "✊"
    case paper = "✋"
    case scissors = "✌️"
}

// Result Of Game
enum GameOutcome: String {
    case win = "You Win!"
    case lose = "You Lose!"
    case tie = "You Tied"
}

// Contains Logic For Playing The Game
class GameModel {
        
    // Randomly Select Hand Position
    func randomHandPose() -> HandPose {
        return HandPose.allCases.randomElement()!
    }
    
    // Determine Game Winner
    func determineWinner(userGesture: HandPose, cpuGesture: HandPose) -> GameResult {
        let outcome: GameOutcome
        
        if userGesture == cpuGesture {
            outcome = .tie
        } else {
            switch (userGesture, cpuGesture) {
            case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
                outcome = .win
            default:
                outcome = .lose
            }
        }
        
        return GameResult(outcome: outcome, userGesture: userGesture, cpuGesture: cpuGesture)
    }
}

