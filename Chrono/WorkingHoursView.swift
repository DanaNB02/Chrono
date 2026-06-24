//
//  WorkingHoursView.swift
//  Chrono
//
//  Created by Dana on 09/01/1448 AH.
//


//
//  WorkingHoursView.swift
//  Chrono
//

import SwiftUI

struct WorkingHoursView: View {
    // Storing components to AppStorage to easily use them in your AI Model later
    @AppStorage("workStartHour") private var workStartHour: Int = 9
    @AppStorage("workStartMinute") private var workStartMinute: Int = 0
    @AppStorage("workEndHour") private var workEndHour: Int = 17
    @AppStorage("workEndMinute") private var workEndMinute: Int = 0
    @AppStorage("hasSetWorkingHours") private var hasSetWorkingHours: Bool = false
    
    // Local state for the DatePickers
    @State private var startTime: Date
    @State private var endTime: Date
    
    init() {
        // Initialize default dates (9:00 AM and 5:00 PM)
        let calendar = Calendar.current
        let today = Date()
        
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        let end = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today) ?? today
        
        _startTime = State(initialValue: start)
        _endTime = State(initialValue: end)
    }
    
    var body: some View {
        ZStack {
            // Match the Quiz background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.16, blue: 0.22),
                    Color(red: 0.22, green: 0.32, blue: 0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                
                Spacer().frame(height: 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Final Step")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Set your working hours")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Chrono uses this to tailor your productivity and recovery suggestions dynamically.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                }
                .padding(.bottom, 20)
                
                // Form Area
                VStack(spacing: 24) {
                    
                    // Start Time Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Start Time")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DatePicker(
                            "Start Time",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark) // Forces the picker text to be white
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.30, green: 0.34, blue: 0.40))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    
                    // End Time Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("End Time")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DatePicker(
                            "End Time",
                            selection: $endTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.30, green: 0.34, blue: 0.40))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
                
                // Complete Button (Matches the result view button style)
                Button(action: saveWorkingHours) {
                    Text("Start Using Chrono")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func saveWorkingHours() {
        let calendar = Calendar.current
        
        // Extract hour and minute to easily use in your engine later
        workStartHour = calendar.component(.hour, from: startTime)
        workStartMinute = calendar.component(.minute, from: startTime)
        
        workEndHour = calendar.component(.hour, from: endTime)
        workEndMinute = calendar.component(.minute, from: endTime)
        
        // Trigger the view switch in SplashScreenView
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasSetWorkingHours = true
        }
    }
}
