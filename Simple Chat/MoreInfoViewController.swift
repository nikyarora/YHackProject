//
//  MoreInfoViewController.swift
//  Simple Chat
//
//  Created by nathan on 12/3/17.
//  Copyright © 2017 Glenn R. Fisher. All rights reserved.
//

import UIKit

class MoreInfoViewController: UIViewController {

    var currentMessageScores: [[Double]]!
    var allMessageAnger: [Double]!
    
    @IBOutlet weak var anger: UIProgressView!
    @IBOutlet weak var disgust: UIProgressView!
    @IBOutlet weak var fear: UIProgressView!
    @IBOutlet weak var joy: UIProgressView!
    @IBOutlet weak var sadness: UIProgressView!
    
    @IBOutlet weak var analytical: UIProgressView!
    @IBOutlet weak var confident: UIProgressView!
    @IBOutlet weak var tentative: UIProgressView!
    
    @IBOutlet weak var openness: UIProgressView!
    @IBOutlet weak var conscientousness: UIProgressView!
    @IBOutlet weak var extraversion: UIProgressView!
    @IBOutlet weak var agreeableness: UIProgressView!
    @IBOutlet weak var emotionalRange: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        anger.setProgress(Float(currentMessageScores[0][0]), animated: true)
        disgust.setProgress(Float(currentMessageScores[0][1]), animated: true)
        fear.setProgress(Float(currentMessageScores[0][2]), animated: true)
        joy.setProgress(Float(currentMessageScores[0][3]), animated: true)
        sadness.setProgress(Float(currentMessageScores[0][4]), animated: true)
        
        analytical.setProgress(Float(currentMessageScores[1][0]), animated: true)
        confident.setProgress(Float(currentMessageScores[1][1]), animated: true)
        tentative.setProgress(Float(currentMessageScores[1][2]), animated: true)
        
        openness.setProgress(Float(currentMessageScores[2][0]), animated: true)
        conscientousness.setProgress(Float(currentMessageScores[2][1]), animated: true)
        extraversion.setProgress(Float(currentMessageScores[2][2]), animated: true)
        agreeableness.setProgress(Float(currentMessageScores[2][3]), animated: true)
        emotionalRange.setProgress(Float(currentMessageScores[2][4]), animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
