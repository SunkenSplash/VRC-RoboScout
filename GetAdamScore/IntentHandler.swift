//
//  IntentHandler.swift
//  GetAdamScore
//
//  Created by William Castro on 4/20/23.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        switch intent {
            case is GetAdamScoreIntent:
                return GetAdamScoreIntentHandler()
            default:
                fatalError("No handler for this intent")
            }
    }
    
}
