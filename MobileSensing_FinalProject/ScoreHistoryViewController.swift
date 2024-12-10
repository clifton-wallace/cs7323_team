import UIKit
import AVFoundation
import Vision

class ScoreHistoryViewController: UITableViewController {
   
   
    private let scoringModel = ScoringModel()
    private var scoreHistory: [(String, String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadScoreHistory()
    }
    
    private func setupUI() {
        title = "Score History"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    // MARK: Table Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scoreHistory.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let metric = scoreHistory[indexPath.row]
        cell.textLabel?.text = "\(metric.0): \(metric.1)"
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    // Build Array Of Metric To Bind To Table
    private func loadScoreHistory() {
        scoreHistory = [
            ("Games Played", "\(scoringModel.gamesPlayed)"),
            ("High Score", "\(scoringModel.highScore)"),
            ("Current Session Score", "\(scoringModel.currentScore)"),
            ("Longest Winning Streak", "\(scoringModel.longestWinningStreak)"),
            ("Longest Losing Streak", "\(scoringModel.longestLosingStreak)"),
            ("Longest Tie Streak", "\(scoringModel.longestTieStreak)"),
            ("Most Common Gesture", scoringModel.mostCommonGesture?.rawValue ?? "None")
        ]
        tableView.reloadData()
    }
}
