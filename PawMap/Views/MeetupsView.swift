import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct MeetupsView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingCreateMeetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text("Dog meetups")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Coming soon!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Organize meetups with nearby dog parents so your pup can make friends")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    showingCreateMeetup = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create meetup")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Meetups")
        }
        .sheet(isPresented: $showingCreateMeetup) {
            CreateMeetupView()
        }
    }
}

struct CreateMeetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @State private var title = ""
    @State private var location = ""
    @State private var selectedDate = Date()
    @State private var time = ""
    @State private var dogBreed = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meetup details") {
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    TextField("Time (e.g. 2:00 PM)", text: $time)
                }
                
                Section("Dog info") {
                    TextField("Dog breed", text: $dogBreed)
                }
                
                Section("Notes") {
                    TextField("Other details…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New meetup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createMeetup()
                    }
                    .disabled(title.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func createMeetup() {
        dismiss()
    }
}

#Preview {
    MeetupsView()
        .environmentObject(UserManager())
}
