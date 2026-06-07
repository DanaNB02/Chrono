//
//  QuizViewModel.swift
//  Chrono
//
//  Created by Reema on 18/12/1447 AH.
//


import Foundation
import Observation
import SwiftUI


// Add this to the top of QuizViewModel.swift
struct QuizOption: Identifiable {
    let id = UUID()
    let text: String
    let type: Chronotype
}

struct QuizQuestion {
    let text: String
    let isTrueFalse: Bool
    let options: [QuizOption]
}

@Observable
class QuizViewModel {
    
    // This array now accurately stores the INDEX of the option they tapped (0 = A, 1 = B, 2 = C)
    var userAnswers: [Int] = []
    var selectedOptionId: UUID? = nil
    var finalResult: Chronotype? = nil
    
    let questions: [QuizQuestion] = [
        // 5 Dolphin Screening Questions (True/False)
        QuizQuestion(text: "I'm a light sleeper.", isTrueFalse: true, options: [
            QuizOption(text: "True", type: .dolphin), QuizOption(text: "False", type: .bear)
        ]),
        QuizQuestion(text: "I usually wake up before my alarm rings.", isTrueFalse: true, options: [
            QuizOption(text: "True", type: .dolphin), QuizOption(text: "False", type: .bear)
        ]),
        QuizQuestion(text: "I'm often irritable due to fatigue.", isTrueFalse: true, options: [
            QuizOption(text: "True", type: .dolphin), QuizOption(text: "False", type: .bear)
        ]),
        QuizQuestion(text: "I worry about small details.", isTrueFalse: true, options: [
            QuizOption(text: "True", type: .dolphin), QuizOption(text: "False", type: .bear)
        ]),
        QuizQuestion(text: "My thoughts keep me up at night.", isTrueFalse: true, options: [
            QuizOption(text: "True", type: .dolphin), QuizOption(text: "False", type: .bear)
        ]),
        
        // 8 Multiple Choice Questions
        QuizQuestion(
            text: "What would be your ideal wake-up time if you didn’t have any obligations?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "Before 6:30 a.m.", type: .lion),
                QuizOption(text: "Between 6:30-9 a.m.", type: .bear),
                QuizOption(text: "After 9 a.m.", type: .wolf)
            ]
        ),
        QuizQuestion(
            text: "Do you use an alarm clock to wake up?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "No, I wake up on my own at just the right time", type: .lion),
                QuizOption(text: "Yes, with zero or one snoozes", type: .bear),
                QuizOption(text: "Yes, with a back-up alarm and multiple snoozes", type: .wolf)
            ]
        ),
        QuizQuestion(
            text: "When do you wake up on the weekends?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "The same time as during the week", type: .lion),
                QuizOption(text: "Within 45-90 minutes of your weekday schedule", type: .bear),
                QuizOption(text: "Ninety minutes or more past your weekday schedule", type: .wolf)
            ]
        ),
        QuizQuestion(
            text: "What’s your favorite time of day for a meal?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "Breakfast (before 11 a.m.)", type: .lion),
                QuizOption(text: "Lunch (between 11 a.m. and 2 p.m.)", type: .bear),
                QuizOption(text: "Dinner (between 5-10 p.m.)", type: .wolf)
            ]
        ),
        QuizQuestion(
            text: "If you were to flash back to high school and take a big test again, when would you prefer the test start for maximum focus and concentration?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "Early morning", type: .lion),
                QuizOption(text: "Early afternoon", type: .bear),
                QuizOption(text: "Mid-afternoon", type: .wolf)
            ]
        ),
        QuizQuestion(
            text: "When are you most alert?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "The hour or two just after waking up", type: .lion),
                QuizOption(text: "Two to four hours after waking up", type: .bear),
                QuizOption(text: "Four to six hours after waking up", type: .wolf)
            ]
        ),
        QuizQuestion(
            text: "If you could choose your own five-hour workday, which block of consecutive hours would you choose?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "4-9 a.m.", type: .lion),
                QuizOption(text: "9 a.m. to 2 p.m.", type: .bear),
                QuizOption(text: "4-9 p.m.", type: .wolf)
            ]
        ),
        QuizQuestion(
            text: "Regarding your overall health, which statement sounds most like you?",
            isTrueFalse: false,
            options: [
                QuizOption(text: "I make healthy choices almost all of the time", type: .lion),
                QuizOption(text: "I make healthy choices some of the time", type: .bear),
                QuizOption(text: "I struggle to make healthy choices", type: .wolf)
            ]
        )
    ]
    
    var currentIndex: Int {
        return userAnswers.count
    }
    
    init() {
        let savedAnswers = UserDefaults.standard.array(forKey: "quizUserAnswers") as? [Int] ?? []
        if savedAnswers.count <= questions.count {
            self.userAnswers = savedAnswers
        } else {
            self.userAnswers = []
        }
        
        if let savedResult = UserDefaults.standard.string(forKey: "userChronotype"),
           let type = Chronotype(rawValue: savedResult) {
            self.finalResult = type
        }
    }
    
    func selectOption(option: QuizOption) {
        // Prevent crashes if they tap after the quiz ends
        guard currentIndex < questions.count else { return }
        
        let currentQ = questions[currentIndex]
        
        // Find out if they tapped the 1st (0), 2nd (1), or 3rd (2) button
        guard let tappedOptionIndex = currentQ.options.firstIndex(where: { $0.id == option.id }) else { return }
        
        selectedOptionId = option.id
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                
                // Store the actual answer index!
                self.userAnswers.append(tappedOptionIndex)
                UserDefaults.standard.set(self.userAnswers, forKey: "quizUserAnswers")
                self.selectedOptionId = nil
                
                // THE DOLPHIN GATE: Run the check exactly after question 5
                if self.userAnswers.count == 5 {
                    // Count how many times they tapped option 0 ("True")
                    let trueCount = self.userAnswers.filter { $0 == 0 }.count
                    
                    if trueCount >= 4 { // If 4 or 5 are True, end the quiz.
                        self.saveAndFinish(result: .dolphin)
                        return
                    }
                }
                
                // If they finish all 13 questions
                if self.userAnswers.count == self.questions.count {
                    self.calculateFinalResult()
                }
            }
        }
    }
    
    func goBack() {
        if !userAnswers.isEmpty {
            withAnimation(.easeInOut) {
                userAnswers.removeLast()
                UserDefaults.standard.set(self.userAnswers, forKey: "quizUserAnswers")
                selectedOptionId = nil
                self.finalResult = nil
            }
        }
    }
    
    func calculateFinalResult() {
        var totalPoints = 0
        
        // Loop through ONLY the 8 multiple choice answers (indices 5 through 12)
        for i in 5..<questions.count {
            if i < userAnswers.count {
                let chosenOptionIndex = userAnswers[i]
                
                // Option A = 1pt, Option B = 2pts, Option C = 3pts
                if chosenOptionIndex == 0 { totalPoints += 1 }
                else if chosenOptionIndex == 1 { totalPoints += 2 }
                else if chosenOptionIndex == 2 { totalPoints += 3 }
            }
        }
        
        let winner: Chronotype
        switch totalPoints {
        case 8...13:  winner = .lion
        case 14...18: winner = .bear
        case 19...24: winner = .wolf
        default:      winner = .bear // Fallback
        }
        
        saveAndFinish(result: winner)
    }
    
    // Update this function so it ONLY sets finalResult, but doesn't save to UserDefaults yet
        private func saveAndFinish(result: Chronotype) {
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.finalResult = result
                    // ❌ REMOVED: UserDefaults.standard.set(result.rawValue, forKey: "userChronotype")
                }
            }
        }
        
        // Add this brand new function right below it!
        func confirmAndGoToDashboard() {
            if let result = finalResult {
                // ✅ NOW we save it, which triggers @AppStorage to swap the screen!
                UserDefaults.standard.set(result.rawValue, forKey: "userChronotype")
            }
        }
    
    func resetQuizProgress() {
        self.userAnswers.removeAll()
        self.finalResult = nil
        UserDefaults.standard.removeObject(forKey: "quizUserAnswers")
        UserDefaults.standard.removeObject(forKey: "userChronotype")
    }
}
