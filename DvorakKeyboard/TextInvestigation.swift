//
//  TextInvestigation.swift
//  Dvorak
//
//  Created by Anouk Stein on 9/14/17.
//  Copyright © 2017 Anouk Stein, M.D. All rights reserved.
//

import UIKit


func isWordDemarcationCharacter(_ charAsString:String) ->Bool{
    let ch:unichar = CFStringGetCharacterAtIndex(charAsString as NSString, 0)
    
    let puncSet = CharacterSet.punctuationCharacters
    let spaceSet = CharacterSet.whitespacesAndNewlines
    if puncSet.contains(UnicodeScalar(ch)!) || spaceSet.contains(UnicodeScalar(ch)!){
        return true
    }
    return false
}

func isPunctuationCharacter(_ charAsString:String) ->Bool{
    let ch:unichar = CFStringGetCharacterAtIndex(charAsString as NSString, 0)
    
    let puncSet = CharacterSet.punctuationCharacters
    if puncSet.contains(UnicodeScalar(ch)!){
        return true
    }
    return false
}

func isPunctuationCharacter(_ ch:unichar) ->Bool{
    
    let puncSet = CharacterSet.punctuationCharacters
    if puncSet.contains(UnicodeScalar(ch)!){
        return true
    }
    return false
}

func getLastWord(_ sentence:String)->String{
    let length = sentence.characters.count
    
    var backwardWord:String = ""
    var lastWord:String = ""
    var a:[Character] = Array()
    
    var i = length - 2
    while i >= 0{
        let charAtIndex = sentence[sentence.characters.index(sentence.startIndex, offsetBy: i)]
        if charAtIndex == " "{
            break
        }
        else{
            backwardWord += "\(charAtIndex)"
            a.append(charAtIndex)
        }
        i -= 1
    }
    
    let rev = Array(a.reversed())
    for ch in rev{
        lastWord += "\(ch)"
    }
    return lastWord
}

