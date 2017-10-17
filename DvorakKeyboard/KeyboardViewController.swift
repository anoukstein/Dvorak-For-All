//
//  KeyboardViewController.swift
//  DvorakKeyboard
//
//  Created by Anouk Stein on 9/20/14.
//  Copyright (c) 2014 Anouk Stein, M.D. All rights reserved.
// From: http://www.appdesignvault.com/ios-8-custom-keyboard-extension/

import UIKit

@IBDesignable open class RoundedButton: UIButton {
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(0.2 * bounds.size.width, 8.0)
        accessibilityTraits = UIAccessibilityTraitKeyboardKey
        clipsToBounds = true
    }
    
    func imageFromColor(_ color: UIColor) -> UIImage
    {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}


class KeyboardViewController: UIInputViewController {
    
    var IS_IPAD_PRO_LARGE  = (UIScreen.main.bounds.size.width >= 1366 || UIScreen.main.bounds.size.height >= 1366)
    
    let lexicon = getEntries()
    
    var systemLexicon:UILexicon?
    let textChecker = UITextChecker()
    var word = ""
    var lastCharacter = ""
    var lastInput = ""
    var allText = ""
    var isNewSentence = false
    var timer: Timer!
    
    @IBOutlet weak var capsLockButton: RoundedButton!
    var isCapOn = false
    var isCapsLockOn = false{
        didSet{
            isCapOn = self.isCapsLockOn
        }
    }
    let capButtonTag = 100
    var cancelTap = false
    
    struct Keys{
        static let capsOff = "⇧"
        static let caps = "⬆︎"
        static let capsLockSymbol = "⇪"
        static let capsLock = "caps lock"
        static let delete = "⬅︎"
        static let nextKeyboard = "🌐"
        static let hideKeyboard = "⌨️"
        static let space = "space"
        static let enter = "return"
    }
    
    fileprivate func isCharacterButton(_ title: String)->Bool{
        switch title {
        case Keys.capsOff, Keys.caps, Keys.capsLockSymbol, Keys.capsLock, Keys.delete, Keys.nextKeyboard, Keys.hideKeyboard, Keys.enter, "ABC", "abc", "123" , "#+=" :
            return false
        default :
            return true
        }
    }
    
    
    struct Keyboard{
        static let Uppercase = "Uppercase"
        static let Lowercase = "Lowercase"
        static let Numbers = "Numbers"
        static let Symbols = "Symbols"
        //IS_IPAD_PRO_LARGE
        static let Uppercase_numbers = "Uppercase_numbers"
        static let Lowercase_numbers = "Lowercase_numbers"
        static let SymbolsLarge = "SymbolsLarge"
    }
    var currentKeyboard = "" 
    
    @IBOutlet weak var text1: UIButton!
    @IBOutlet weak var text2: UIButton!
    @IBOutlet weak var text3: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //adjustHeight()
        loadKeyboardNib()
        
        //Set up
        setupSpellCheck()
    }
    
    fileprivate func setupSpellCheck(){
        let _ = getEntries()
        self.requestSupplementaryLexicon(completion: { (lex) in
            self.systemLexicon = lex
            for entry in lex.entries {
                if entry.documentText == entry.userInput {
                    self.textChecker.ignoreWord(entry.documentText)
                }
            }
        })
        let _ = databaseURL()
    }
    
    func loadKeyboardNib(_ keyboard: String = Keyboard.Uppercase){
        
        var keyboardToLoad = keyboard
        
        if IS_IPAD_PRO_LARGE{
            if keyboard == Keyboard.Uppercase{
                keyboardToLoad = Keyboard.Uppercase_numbers
            }else if keyboard == Keyboard.Lowercase{
                keyboardToLoad = Keyboard.Lowercase_numbers
            }else if keyboard == Keyboard.Symbols{
                keyboardToLoad = Keyboard.SymbolsLarge
            }
        }
        
        if currentKeyboard != keyboardToLoad{ // || isCapsLockOn == true{
            currentKeyboard = keyboardToLoad
            
            let nib = UINib(nibName: currentKeyboard, bundle: nil)
            let objects = nib.instantiate(withOwner: self, options: nil)
            view = objects[0] as! UIView
        }
        
        if isCapsLockOn == true && currentKeyboard == Keyboard.Uppercase_numbers{
            capsLockButton.backgroundColor = UIColor.white
        }
    }
    
    fileprivate func saveCharacter(_ text: String) {
        if lastInput.characters.count > 1{
            lastInput = lastInput[lastInput.characters.index(before: lastInput.endIndex) ..< lastInput.endIndex]
        }
        lastInput += text;
        lastCharacter = text
        word += text
    }
    
    @IBAction func didTapButton(_ sender: UIButton) {
        if cancelTap == true{
            cancelTap = false
            return
        }
        
        let button = sender
        if let buttonTitle = button.title(for: UIControlState()) as String!{
            var title = buttonTitle
            
            lastCharacter = isCharacterButton(title) ? title : ""
            let proxy = textDocumentProxy as UITextDocumentProxy
            var isEndOfWord = false
            
            switch title {
            case Keys.delete :
                endDelete()
            case Keys.enter :
                proxy.insertText("\n")
                saveCharacter(" ")
                isEndOfWord = true
                
            case Keys.space :
                //check content before to see if not space
                var text = " "
                title = " "
                if proxy.documentContextBeforeInput != nil, let checkLast = proxy.documentContextBeforeInput{
                    
                    if checkLast.characters.count > 1{
                        //get last 2 letters
                        
                        let charOne = checkLast[checkLast.index(before: checkLast.characters.index(before: checkLast.endIndex))]
                        let charTwo = checkLast[checkLast.characters.index(before: checkLast.endIndex)]
                        if charOne != " " && charOne != "." && charTwo == " "{
                            proxy.deleteBackward()
                            text = ". "
                            loadKeyboardNib(Keyboard.Uppercase)
                        }
                        if charTwo == "." || charTwo == "!" || charTwo == "?"{
                            loadKeyboardNib(Keyboard.Uppercase)
                        }
                        lastInput = checkLast[checkLast.index(before: checkLast.characters.index(before: checkLast.endIndex)) ..< checkLast.endIndex]
                    }else{
                        lastInput = checkLast[checkLast.characters.index(before: checkLast.endIndex) ..< checkLast.endIndex]
                    }
                    isEndOfWord = true
                }
                proxy.insertText(text)
                saveCharacter(" ")
                
            case Keys.nextKeyboard :
                self.advanceToNextInputMode()
            case Keys.hideKeyboard:
                self.dismissKeyboard()
                
            case Keys.caps: //Uppercase keyboard changes letters to lowercase
                isCapOn = false
                loadKeyboardNib(Keyboard.Lowercase)
            case Keys.capsOff: //Lowercase keyboard changes letters to uppercase
                isCapOn = true
                loadKeyboardNib(Keyboard.Uppercase)
                
            case Keys.capsLock: //iPad only
                isCapsLockOn = !isCapsLockOn
                isCapOn = isCapsLockOn
                let keyboardToLoad = (isCapsLockOn == false ? Keyboard.Lowercase_numbers : Keyboard.Uppercase_numbers)
                loadKeyboardNib(keyboardToLoad)
                
                if isCapsLockOn == false && keyboardToLoad == Keyboard.Uppercase_numbers{
                    capsLockButton.backgroundColor = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
                }
            case Keys.capsLockSymbol:
                isCapsLockOn = false
                isCapOn = false
                loadKeyboardNib(Keyboard.Lowercase)
            case "ABC" :
                loadKeyboardNib(Keyboard.Uppercase)
                
            case "abc" :
                loadKeyboardNib(Keyboard.Lowercase)
                
            case "123" :
                loadKeyboardNib(Keyboard.Numbers)
                
            case "#+=" :
                loadKeyboardNib(Keyboard.Symbols)
                
            default :
                isEndOfWord = isWordDemarcationCharacter(title)
                
                //Capitalize start of sentence
                if lastInput == ". " || lastInput == "? " || lastInput == "! " || allText.isEmpty
                {
                    title = title.uppercased();
                    isNewSentence = true
                    if (currentKeyboard == Keyboard.Uppercase || currentKeyboard == Keyboard.Uppercase_numbers) && !isCapOn{
                        loadKeyboardNib(Keyboard.Lowercase)
                    }
                }else{
                    if title == title.uppercased() && isCapsLockOn == false && isAlphabetKeyboard() == true{
                        loadKeyboardNib(Keyboard.Lowercase)
                        isCapOn = false
                    }
                }
                //check if punctuation and space before
                if isPunctuationCharacter(title), let last = proxy.documentContextBeforeInput{
                    
                    let priorCharacter = last[last.characters.index(before: last.endIndex) ..< last.endIndex]
                    if priorCharacter == " " {
                        deleteCharacter()
                        
                        proxy.insertText(title + " ")
                        saveCharacter(" ")
                        loadKeyboardNib(Keyboard.Uppercase)
                    }else{
                        proxy.insertText(title)
                        lastCharacter = title
                    }
                }else{
                    proxy.insertText(title)
                    lastCharacter = title
                }
            }
            
            if isEndOfWord{
                clearSuggestions()
                if proxy.documentContextBeforeInput != nil, let before = proxy.documentContextBeforeInput{
                    var lastWord = getLastWord(before)
                    //spellcheck
                    var (isMisspelled, newWord) = spellCheck(lastWord, lexicon: lexicon!)
                    if isMisspelled {
                        newWord = isCapOn ? newWord.uppercased() : newWord.lowercased()
                        if isNewSentence || lastWord == lastWord.capitalized{
                            newWord = newWord.capitalized
                        }
                        
                        newWord = isCapsLockOn ? newWord.uppercased() : newWord
                        //put word demarcation character back in
                        newWord += title
                        lastWord += title
                        replaceWordInDocument(newWord, oldWord:lastWord)
                        
                    }else{
                        //System spell check
                        word = lastWord
                        
                        let misspelledRange = textChecker.rangeOfMisspelledWord(
                            in: word.lowercased(), range: NSRange(0..<word.utf16.count),
                            startingAt: 0, wrap: false, language: "en_US")
                        
                        if misspelledRange.location != NSNotFound,
                            let guesses:[String] = textChecker.guesses(
                                forWordRange: misspelledRange, in: word.lowercased(), language: "en_US")
                        {
                            //replaceWordInDocument(guesses.first!, oldWord:lastWord + title)
                            if let guess = guesses.first{
                                setButtonTitle(text3, text: guess)
                            }
                        }
                    }
                }
            }else {
                //completion
                if isAlphabetKeyboard() == true{
                    populateSuggestions(title)
                }
            }
            
            var after = String()
            var beforeText = ""
            if proxy.documentContextBeforeInput != nil, let before = proxy.documentContextBeforeInput{
                if before.characters.count > 0{
                    
                    beforeText = before
                    
                    lastInput = before[before.characters.index(before: before.endIndex) ..< before.endIndex]
                    if before.characters.count > 1{
                        lastInput = before[before.index(before: before.characters.index(before: before.endIndex)) ..< before.endIndex]
                    }
                }
            }
            if (proxy.documentContextAfterInput != nil){
                after = proxy.documentContextAfterInput!
            }
            
            allText = beforeText + after
            isNewSentence = false
        }
    }
    
    //Did drag inside
    @IBAction func startCapsLock(_ sender: RoundedButton) {
        isCapsLockOn = true
        isCapOn = true
        sender.setTitle(Keys.capsLockSymbol, for: UIControlState())
        cancelTap = true
    }
    
    
    fileprivate func isAlphabetKeyboard()->Bool{
        if currentKeyboard == Keyboard.Lowercase || currentKeyboard == Keyboard.Uppercase{
            return true
        }
        if currentKeyboard == Keyboard.Uppercase_numbers || currentKeyboard == Keyboard.Lowercase_numbers{
            return true
        }
        return false
    }
    
    
    @IBAction func selectSuggestion(_ sender: UIButton) {
        let oldWord = word
        
        if var newWord = sender.title(for: UIControlState()){
            if !newWord.isEmpty && !oldWord.isEmpty{
                newWord = newWord.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                replaceWordInDocument(newWord, oldWord: oldWord)
            }
        }
    }
    
    fileprivate func populateSuggestions(_ ch:String){
        if isCharacterButton(ch) == false{
            return
        }
        word = getLastWord(textDocumentProxy.documentContextBeforeInput!) + ch
        
        //custom completion
        clearSuggestions()
        if let results = query(word){
            if results.count > 2{
                setButtonTitle(text1, text: results[0])
                setButtonTitle(text2, text: results[1])
                setButtonTitle(text3, text: results[2])
            }else{
                let completions:[String]? = textChecker.completions(forPartialWordRange: NSRange(0..<word.utf16.count), in: word, language: "en_US")
                if results.count > 1{
                    setButtonTitle(text1, text: results[0])
                    setButtonTitle(text2, text: results[1])
                    
                    setButtonTitle(text3, text: (completions?.first) ?? "")
                }else if results.count > 0{
                    setButtonTitle(text1, text: results[0])
                    setButtonTitle(text2, text: (completions?.first) ?? "")
                    if let c = completions, c.count > 1{
                        setButtonTitle(text3, text: completions![1])
                    }
                }
            }
            
        }else{
            let title = "\"\(word)\""
            text1.setTitle(title, for: UIControlState())
        }
    }
    
    fileprivate func setButtonTitle(_ button:UIButton?, text:String){
        
        if let button = button{
            var buttonTitle = text
            if word == word.capitalized{
                buttonTitle = text.capitalized
            }
            if isCapsLockOn{
                buttonTitle = text.uppercased()
            }
            button.setTitle(buttonTitle, for: UIControlState())
        }
    }
    
    fileprivate func clearSuggestions(){
        if isAlphabetKeyboard() == true{
            text1.setTitle("", for: UIControlState())
            text2.setTitle("", for: UIControlState())
            text3.setTitle("", for: UIControlState())
        }
    }
    
    func replaceWordInDocument(_ newWord:String, oldWord:String){
        
        var prior = oldWord
        
        if isWordDemarcationCharacter(lastCharacter){
            if isPunctuationCharacter(lastCharacter){
                prior += lastInput
            }else{
                prior += lastCharacter
            }
        }
        
        let length = prior.characters.count
        let proxy = textDocumentProxy as UITextDocumentProxy
        for _ in 0..<length{
            proxy.deleteBackward()
        }
        proxy.insertText(newWord)
        
        if let first = lastInput.characters.first{
            
            if isPunctuationCharacter(String(first)) == true{
                proxy.insertText(lastInput)
            }else{
                proxy.insertText(" ")
                saveCharacter(" ")
            }
        }else{
            proxy.insertText(" ")
            saveCharacter(" ")
        }
        clearSuggestions()
    }
    
    let duration = 0.05
    @IBAction func buttonSelected(_ sender: UIButton){
        
        let button = sender
        let title = button.title(for: UIControlState()) as String!
        
        if title ==  Keys.delete{
            startDelete()
        }else if isCharacterButton(title!) == true{
            
            UIView.animate(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                button.backgroundColor = UIColor.lightGray
                button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: {
                (finished: Bool) -> Void in
                
                // Fade in
                UIView.animate(withDuration: self.duration, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    button.backgroundColor = UIColor.white
                    button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }, completion: nil)
            })
        }
    }
    
    //**
    //Delete functions
    @IBAction func endButtonSelected(_ sender:UIButton){
        let button = sender
        let title = button.title(for: UIControlState()) as String!
        //delete
        if (title == Keys.delete){
            endDelete()
        }
    }
    
    fileprivate func startDelete(){
        deleteCharacter()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(KeyboardViewController.deleteCharacter), userInfo: nil, repeats: true)
    }
    
    fileprivate func endDelete(){
        timer.invalidate()
    }
    
    func deleteCharacter(){
        let proxy = textDocumentProxy as UITextDocumentProxy
        if let before = textDocumentProxy.documentContextBeforeInput{
            word = getLastWord(before)
        }
        
        proxy.deleteBackward()
        if !lastInput.isEmpty{
            lastInput = lastInput.substring(to: lastInput.characters.index(before: lastInput.endIndex))
            lastCharacter = lastInput.substring(to: lastInput.endIndex)
        }
    }
    
    //Delegate
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
    }
}
