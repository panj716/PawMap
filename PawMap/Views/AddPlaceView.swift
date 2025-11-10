import SwiftUI
import MapKit

struct AddPlaceView: View {
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var address = ""
    @State private var selectedType: Place.PlaceType = .other
    @State private var notes = ""
    @State private var rating = 5
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                        
                        Text("Add New Place")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Help other dog owners discover great places")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Place Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Place Name *")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter place name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Place Type
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Place Type *")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Place Type", selection: $selectedType) {
                                ForEach(Place.PlaceType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address *")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter address", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Rating
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Rating")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        rating = star
                                    }) {
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundColor(star <= rating ? .yellow : .gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(rating) star\(rating == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Tell us about this place...", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Add Place Button
                    Button(action: addPlace) {
                        HStack {
                            if placeViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            
                            Text("Add Place")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(placeViewModel.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 20)
                    
                    // Error Message
                    if let errorMessage = placeViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Add Place", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addPlace() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }
        
        guard let userId = authViewModel.currentUser?.id else {
            alertMessage = "Please sign in to add places"
            showingAlert = true
            return
        }
        
        // For now, use default coordinates (Ann Arbor)
        // In a real app, you'd get these from a map picker or geocoding
        let newPlace = Place(
            name: name,
            type: selectedType,
            address: address,
            latitude: 42.2464,
            longitude: -83.7417,
            rating: Double(rating),
            tags: [],
            notes: notes,
            createdBy: userId
        )
        
        placeViewModel.addPlace(newPlace)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                },
                receiveValue: { _ in
                    dismiss()
                }
            )
    }
}

#Preview {
    AddPlaceView()
        .environmentObject(PlaceViewModel())
        .environmentObject(AuthViewModel())
}
