/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import AVFoundation
import ToneAnalyzerV3
import SpeechToTextV1
import ConversationV1
import TextToSpeechV1
import JSQMessagesViewController
import SwiftyJSON
import HxColor

class ViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    
    var conversation: Conversation!
    var speechToText: SpeechToText!
    var textToSpeech: TextToSpeech!
    var toneAnalyzer: ToneAnalyzer!
    
    var audioPlayer: AVAudioPlayer?
    var workspace = Credentials.ConversationWorkspace
    var context: Context?
    
    var allMessageScores: [[[Double]]]!
    var allMessageAnger: [Double]!
    var currentMessageScores: [[Double]]!
    var currentMessageEmotion: Double = 0.5

    var keyboardHeight:CGFloat = 0.0
    var infoView: UIView!
    var infoViewText: UITextView!
    var moreInfo: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allMessageScores = []
        allMessageAnger = [Double]()
        currentMessageScores = []
        currentMessageEmotion = 0.5
        
        setupInterface()
        setupSender()
        setupWatsonServices()
        startConversation()
    }
}

// MARK: Watson Services
extension ViewController {
    
    /// Instantiate the Watson services
    func setupWatsonServices() {
        conversation = Conversation(
            username: Credentials.ConversationUsername,
            password: Credentials.ConversationPassword,
            version: "2017-05-26"
        )
        speechToText = SpeechToText(
            username: Credentials.SpeechToTextUsername,
            password: Credentials.SpeechToTextPassword
        )
        textToSpeech = TextToSpeech(
            username: Credentials.TextToSpeechUsername,
            password: Credentials.TextToSpeechPassword
        )
        toneAnalyzer = ToneAnalyzer(
            username: Credentials.ToneAnalyzerUsername,
            password: Credentials.ToneAnalyzerPassword,
            version: "2017-05-26"
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let logo = UIImage(named: "logotop2")
        let imageView = UIImageView(image: logo)
        imageView.contentMode = .scaleAspectFit // set imageview's content mode
        self.navigationItem.titleView = imageView
    }
    
    
    /// Present an error message
    func failure(error: Error) {
        let alert = UIAlertController(
            title: "Watson Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.infoView.isHidden = true
    }
    
    /// Start a new conversation
    func startConversation() {
        
        let failure = { (error: Error) in print(error) }
        
        conversation.message(
            workspaceID: workspace,
            failure: failure,
            success: presentResponse
        )
    }
    
    /// Present a conversation reply and speak it to the user
    func presentResponse(_ response: MessageResponse) {
        let text = response.output.text.joined()
        context = response.context // save context to continue conversation
        
        // synthesize and speak the response
        textToSpeech.synthesize(text, failure: failure) { audio in
            self.audioPlayer = try! AVAudioPlayer(data: audio)
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
        }
        
        // create message
        let message = JSQMessage(
            senderId: User.watson.rawValue,
            displayName: User.getName(User.watson),
            text: text
        )
        
        // add message to chat window
        if let message = message {
            self.messages.append(message)
            DispatchQueue.main.async { self.finishSendingMessage() }
        }
    }
    
    /// Start transcribing microphone audio
    @objc func startTranscribing() {
        audioPlayer?.stop()
        var settings = RecognitionSettings(contentType: .opus)
        settings.interimResults = true
        speechToText.recognizeMicrophone(settings: settings, failure: failure) { results in
            self.inputToolbar.contentView.textView.text = results.bestTranscript
            self.inputToolbar.toggleSendButtonEnabled()
        }
    }
    
    /// Stop transcribing microphone audio
    @objc func stopTranscribing() {
        speechToText.stopRecognizeMicrophone()
    }
}

// MARK: Configuration
extension ViewController {
    
    func setupInterface() {
        // bubbles
        let factory = JSQMessagesBubbleImageFactory()
        let incomingColor = UIColor(red: 0.29, green: 0.44, blue: 0.54, alpha: 1)
        let outgoingColor = UIColor(0x9B9B9B)
        incomingBubble = factory!.incomingMessagesBubbleImage(with: incomingColor)
        outgoingBubble = factory!.outgoingMessagesBubbleImage(with: outgoingColor)
        
        // avatars
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        // microphone button
        let microphoneButton = UIButton(type: .custom)
        microphoneButton.setImage(#imageLiteral(resourceName: "microphone-hollow"), for: .normal)
        microphoneButton.setImage(#imageLiteral(resourceName: "microphone"), for: .highlighted)
        microphoneButton.addTarget(self, action: #selector(startTranscribing), for: .touchDown)
        microphoneButton.addTarget(self, action: #selector(stopTranscribing), for: .touchUpInside)
        microphoneButton.addTarget(self, action: #selector(stopTranscribing), for: .touchUpOutside)
        inputToolbar.contentView.leftBarButtonItem = microphoneButton
        
        // infoView
        self.infoView = UIView()

        self.infoView.backgroundColor = UIColor.jsq_messageBubbleLightGray()
        infoView.layer.cornerRadius = 6
        infoView.layer.masksToBounds = true
        self.view.addSubview(self.infoView)
        _ = self.infoView.anchor(self.view.topAnchor, left: self.view.leftAnchor, bottom: nil, right: self.view.rightAnchor, topConstant: 263, leftConstant: 6, bottomConstant: 6, rightConstant: 6, widthConstant: 0, heightConstant: 75)
        
        // MoreInfo Button
        self.moreInfo = UIButton(type: .system)
//        moreInfo.setTitle("More", for: .normal)
        moreInfo.setBackgroundImage(#imageLiteral(resourceName: "more"), for: .normal)
        
        moreInfo.setTitleColor(UIColor.blue, for: .normal)
//        moreInfo.backgroundColor = UIColor.yellow
        self.infoView.addSubview(moreInfo)
        _ = moreInfo.anchor(self.infoView.topAnchor, left: nil, bottom: self.infoView.bottomAnchor, right: self.infoView.rightAnchor, topConstant: 20, leftConstant: 16, bottomConstant: 20, rightConstant: 16, widthConstant: 34, heightConstant: 0)
        moreInfo.addTarget(self, action: #selector(goToMoreInfoView), for: .touchUpInside)
        
        // InfoText
        self.infoViewText = UITextView()
        self.infoViewText.backgroundColor = UIColor.clear
        self.infoViewText.text = "Customer Emotion"
        self.infoViewText.isEditable = false
        infoViewText.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        infoView.addSubview(self.infoViewText)
        
        let artributedText = NSMutableAttributedString(string:self.infoViewText.text, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium), NSForegroundColorAttributeName: UIColor.black])
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let length = artributedText.string.count
        artributedText.addAttributes([NSParagraphStyleAttributeName:paragraphStyle], range: NSRange(location: 0, length:length))
        
        infoViewText.attributedText = artributedText
        
        self.infoViewText.anchorToTop(self.infoView.topAnchor, left: self.infoView.leftAnchor, bottom: self.infoView.bottomAnchor, right: self.moreInfo.leftAnchor)
        
        self.infoView.isHidden = true
    }
    
    func goToMoreInfoView() {
        self.performSegue(withIdentifier: "goToMoreInfoView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "goToMoreInfoView" {
                if let dest = segue.destination as? MoreInfoViewController {
                    dest.currentMessageScores = self.currentMessageScores
                    dest.allMessageAnger = self.allMessageAnger
                }
            }
        }
    }
    
    func setupSender() {
        senderId = User.me.rawValue
        senderDisplayName = User.getName(User.me)
    }
    
    override func didPressSend(
        _ button: UIButton!,
        withMessageText text: String!,
        senderId: String!,
        senderDisplayName: String!,
        date: Date!) {
        
        let message = JSQMessage(
            senderId: User.me.rawValue,
            senderDisplayName: User.getName(User.me),
            date: date,
            text: text
        )
        
        if let message = message {
            self.messages.append(message)
            self.finishSendingMessage(animated: true)
        }
        
        // send text to conversation service
        let input = InputData(text: text)
        
        let request = MessageRequest(input: input, context: context)
        
        conversation.message(
            workspaceID: workspace,
            request: request,
            failure: failure,
            success: presentResponse
        )
        
        // send text to toneAnalyzer service
        toneAnalyzer.getTone(ofText: text, failure: failure) { tones in
            
            DispatchQueue.main.async() {
            
                let messageTones = tones.documentTone
                
                let emotionTones = messageTones[0]
                var emotionScores = [Double]()
                for tone in emotionTones.tones {
                    emotionScores.append(tone.score)
                }
                
                let languageTones = messageTones[1]
                var languageScores = [Double]()
                for tone in languageTones.tones {
                    languageScores.append(tone.score)
                }
                
                let socialTones = messageTones[2]
                var socialScores = [Double]()
                for tone in socialTones.tones {
                    socialScores.append(tone.score)
                }
                
                // Negative emotion level for anry/disgust
                self.currentMessageScores = [emotionScores, languageScores, socialScores]
                self.allMessageScores.append(self.currentMessageScores)
                
                var negativeEmotionLevel = self.currentMessageScores[0][0]      // Angry
                if negativeEmotionLevel < self.currentMessageScores[0][1] {     // Disgust More
                    negativeEmotionLevel = self.currentMessageScores[0][1]
                }
                
                self.allMessageAnger.append(negativeEmotionLevel)
                
                // Reload collection view data
                self.collectionView.reloadData()
                
                // Show the infoView
                if self.infoView.isHidden {
                    self.infoView.isHidden = false
                }
                
                // Show the dominant emotions
//                var emotionInfoText = ""
                var emotionNames = [String]()
                
                for categoryIndex in 0..<3 {
                    var categoryScores = self.currentMessageScores[categoryIndex]
                    for emotionIndex in 0..<(categoryScores.count) {
                        if (categoryScores[emotionIndex] > 0.5) {
                            emotionNames.append(toneCategoryList[categoryIndex][emotionIndex])
                        }
                    }
                }
                
                if (emotionNames.count > 0) {
                    let attributedText = NSMutableAttributedString(string: emotionNames[0], attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium), NSForegroundColorAttributeName: UIColor.black])
                    
                    for index in 1..<emotionNames.count {
                        attributedText.append(NSAttributedString(string: "  \(emotionNames[index])",  attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium), NSForegroundColorAttributeName: UIColor.black]))
                    }
                    
                    self.infoViewText.attributedText = attributedText
                }
            }
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        // required by super class
    }
    
    
    func getCurrentMessageEmotion() -> Double {
        return self.currentMessageScores[0][0]
    }
}

// MARK: Collection View Data Source
extension ViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int)
        -> Int
    {
        return messages.count
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageData!
    {
        return messages[indexPath.item]
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageBubbleImageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageBubbleImageDataSource!
    {
        let message = messages[indexPath.item]
        let isOutgoing = (message.senderId == senderId)
        let bubble = (isOutgoing) ? outgoingBubble : incomingBubble
        return bubble
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        avatarImageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageAvatarImageDataSource!
    {
        let message = messages[indexPath.item]
        return User.getAvatar(message.senderId)
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = super.collectionView(
            collectionView,
            cellForItemAt: indexPath
        )
        let jsqCell = cell as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        let isOutgoing = (message.senderId == senderId)
        
        if !isOutgoing {
            jsqCell.textView.textColor = UIColor.white
        } else {

//            row  1 3 5
//          count  1 2 3
            
            if (indexPath.row == self.allMessageAnger.count + self.allMessageAnger.count - 1) {
                let fraction = self.allMessageAnger[self.allMessageAnger.count - 1]
                print(fraction)
                print("hi")
                jsqCell.textView.textColor = colorWhite.interpolateRGBColorTo(end: colorRed, fraction: CGFloat(fraction))
            } else {
                 jsqCell.textView.textColor = UIColor.white
            }
        }
        
        return jsqCell
    }
}
