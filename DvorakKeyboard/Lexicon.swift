//
//  Lexicon.swift
//  Dvorak
//
//  Created by Anouk Stein on 10/7/14.
//  Copyright (c) 2014 Anouk Stein, M.D. All rights reserved.
//

import UIKit

class Entry: NSObject {
    var documentText: String?
    var userInput: String?
}

struct WordEntry{
    let documentText: String
    let userInput: String
}

func databaseURL() -> URL? {
    
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    
    // If array of path is empty the document folder not found
    guard urls.count == 0 else {
        let finalDatabaseURL = urls.first!.appendingPathComponent("Words")
        // Check if file reachable, and if reacheble just return path
        guard (finalDatabaseURL as NSURL).checkResourceIsReachableAndReturnError(nil) else {
            // Check if file is exists in bundle folder
            if let bundleURL = Bundle.main.url(forResource: "Words", withExtension: "db") {
                // if exist we will copy it
                do {
                    try fileManager.copyItem(at: bundleURL, to: finalDatabaseURL)
                } catch _ {
                    print("File copy failed!")
                }
            } else {
                print("DB file doesn't exist in bundle folder")
                return nil
            }
            return finalDatabaseURL
        }
        return finalDatabaseURL
    }
    return nil
}



//Debug function
func getLexicon() -> Array<WordEntry>{
    let w = Entry()
    w.userInput = "teh"
    w.documentText = "the"
    var d:[Entry] = Array()
    d.append(w)
    
    let data = [
        WordEntry(documentText: "the", userInput: "teh"),
        WordEntry(documentText: "then", userInput: "teh")
    ]
    return data
}

func getEntries() -> [Entry]? {
    
    if let filePath = Bundle.main.path(forResource: "lexicon", ofType: "json"), let data = try? Data(contentsOf: URL(fileURLWithPath: filePath), options: .alwaysMapped){
        
        var finalEntryArray: [Entry] = Array()
        var JSONDict:NSMutableDictionary
        JSONDict = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSMutableDictionary
        
        if let EntrysArray = JSONDict["entries"] as? [NSDictionary] {
            for EntryDict in EntrysArray {
                let newEntry = Entry()
                
                if let entryText = EntryDict["documentText"] as? String {
                    newEntry.documentText = entryText
                }
                
                if let entryInput = EntryDict["userInput"] as? String {
                    newEntry.userInput = entryInput
                }
                
                finalEntryArray.append(newEntry)
            }
        }
        return finalEntryArray
    }
    return nil
}

func spellCheck(_ inputWord:String, lexicon:[Entry]) -> (Bool, String){
    //if work in lexicon userEntry
    //return docText
    
    let inList = lexicon.filter{$0.userInput == inputWord.lowercased()}
    if inList.count > 0{
        return (true, inList[0].documentText ?? inputWord)
    }
    return (false, inputWord)
}

func query(_ fragment:String)->[String]? {
    if let queryStatementString = createQueryStringFromWordFragment(fragment){
        return queryFromString(queryStatementString)
    }
    return nil
}

//query
private func createQueryStringFromWordFragment(_ fragment:String)->String? {
    
    //Create queryStatementString
    let lowerWord = fragment.lowercased()
    let queryStatementString = "SELECT * FROM words where item LIKE \"" + lowerWord + "%%\" ORDER BY rank + 0 LIMIT 3"
    
    return queryStatementString
}

private func createQueryStringFromList(_ wordlist:[String])->String? {
    
    if wordlist.count == 0{
        return nil
    }
    //Create queryStatementString
    var queryStatementString = "SELECT * FROM words where "
    for word in wordlist{
        let lowerWord = word.lowercased()
        queryStatementString += " item = \"" + lowerWord + "\""
        if word != wordlist.last{
            queryStatementString += " OR "
        }
    }
    
    return queryStatementString
}

private func queryFromString(_ queryStatementString:String)->[String]? {
    
    var results = [String: Int32]()
    let db = openDatabase()
    var queryStatement: OpaquePointer? = nil
    
    if sqlite3_prepare_v2(db!, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            let item = String(cString: sqlite3_column_text(queryStatement, 0))
            let rank = sqlite3_column_int(queryStatement, 1)
            results[item] = rank
        }
    } else {
        print("SELECT statement could not be prepared \(queryStatementString)")
    }
    
    sqlite3_finalize(queryStatement)
    close(db)
    if results.count > 0{
        return Array(results.keys)
    }
    return nil
    
}

//Open and close db

private func openDatabase() -> OpaquePointer? {
    var db: OpaquePointer? = nil
    
    if let dbpath = Bundle.main.path(forResource: "Words", ofType: "db"){
        
        if sqlite3_open(dbpath, &db) == SQLITE_OK {
            return db
        } else {
            print("Unable to open database.")
            return nil
        }
    }
    return nil
}


private func close(_ db:OpaquePointer?){
    if let database = db{
        sqlite3_close(database)
    }
}




