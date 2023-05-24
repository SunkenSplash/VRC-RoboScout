//
//  GetAdamScoreHandler.swift
//  GetAdamScore
//
//  Created by William Castro on 4/20/23.
//

import Foundation
import Intents
import CoreML

class GetAdamScoreIntentHandler: NSObject, GetAdamScoreIntentHandling {
    
    let adam_score_map = [
        "low",
        "low mid",
        "mid",
        "high mid",
        "high",
        "very high"
    ]
    
    func handle(intent: GetAdamScoreIntent, completion: @escaping (GetAdamScoreIntentResponse) -> Void) {
        if let number = intent.teamNumber {
            guard let model = try? AdamScore(configuration: MLModelConfiguration()) else {
                completion(GetAdamScoreIntentResponse.failure(failureReason: "Could not load AdamScore model."))
                return
            }
            let API = RoboScoutAPI()
            let team = Team(number: number)
            if team.id == 0 {
                completion(GetAdamScoreIntentResponse.failure(failureReason: "I couldn't find a team with that number."))
            }
            let world_skills = API.world_skills_for(team: team)
            let vrc_data_analysis = API.vrc_data_analysis_for(team: team, fetch: true)
            let avg_rank = team.average_ranking(season: 173)
            guard let score = try? model.prediction(world_skills_ranking: Double(world_skills.ranking), trueskill_ranking: Double(vrc_data_analysis.trueskill_ranking), average_qualification_ranking: avg_rank, ccwm: Double(vrc_data_analysis.ccwm), winrate: Double(vrc_data_analysis.total_wins) / Double(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties)) else {
                completion(GetAdamScoreIntentResponse.failure(failureReason: "There was a runtime error with the AdamScore model."))
                return
            }
            completion(GetAdamScoreIntentResponse.success(teamNumber: team.number.split(separator: "").joined(separator: " "), adamScore: adam_score_map[Int(score.adamscore)]))
        } else {
            completion(GetAdamScoreIntentResponse.failure(failureReason: "Please provide a team number."))
        }
    }
    
    func resolveTeamNumber(for intent: GetAdamScoreIntent, with completion: @escaping (GetAdamScoreTeamNumberResolutionResult) -> Void) {
        if let number = intent.teamNumber, !number.isEmpty {
            completion(GetAdamScoreTeamNumberResolutionResult.success(with: number))
        } else {
            completion(GetAdamScoreTeamNumberResolutionResult.unsupported(forReason: .noNumber))
        }
    }
}
