//
//  Tone.swift
//  Simple Chat
//
//  Created by nathan on 12/2/17.
//  Copyright © 2017 Glenn R. Fisher. All rights reserved.
//

import Foundation

//let toneCategoryName = ["Emotion Tone", "Language Tone", "Social Tone"]
let emotionTone = ["Anger", "Disgust", "Fear", "Joy", "Sadness"]
let languageTone = ["analytical", "confident", "tentative", ]
let socialTone = ["Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Emotional Range"]

@objc class Tone: NSObject {
    let id: String!
    let name: String!
    let score: Double!
    
    init(id: String, name: String, score: Double) {
        self.id = id
        self.name = name
        self.score = score
    }
}
