//
//  Tone.swift
//  Simple Chat
//
//  Created by nathan on 12/2/17.
//  Copyright © 2017 Glenn R. Fisher. All rights reserved.
//

import Foundation


let emotionToneList = ["Anger", "Disgust", "Fear", "Joy", "Sadness"]
//Anger 50, disgust , fear > < Joy 100
let languageToneList = ["Analytical", "Confident", "Tentative", ]
let socialToneList = ["Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Emotional Range"]
let toneCategoryList = [emotionToneList, languageToneList, socialToneList]

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
