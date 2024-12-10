import Foundation

// Stores Result Of A Game
struct GameResult: Codable {
    let outcome: GameOutcome
    let userGesture: HandPose
    let cpuGesture: HandPose
}

// Possible Gestures For Game
enum HandPose: String, CaseIterable, Codable {
    case rock = "✊"
    case paper = "✋"
    case scissors = "✌️"
    case unknown = "☹️"
}

// Result Of Game
enum GameOutcome: String, Codable {
    case win = "You Win!"
    case lose = "You Lose!"
    case tie = "You Tied"
    case invalidInput = "ERROR!"
}

// Contains Logic For Playing The Game
class GameModel {
        
    // Randomly Select Hand Position - Do Not Return Unknwon
    func randomHandPose() -> HandPose {
        return HandPose.allCases.filter { $0 != .unknown }.randomElement()!
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
    
    // Map To Enum Because It Has Emojis - ARG
    static func MapPose(input: String) -> HandPose? {
        let normalizedInput = input.lowercased()
        switch normalizedInput {
        case "rock":
            return .rock
        case "paper":
            return .paper
        case "scissors":
            return .scissors
        default:
            return .unknown
        }
    }
}

