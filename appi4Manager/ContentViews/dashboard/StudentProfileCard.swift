//
//  StudentProfileCard.swift
//  appi4Manager
//
//  Enhanced student card that shows app profile information
//

import SwiftUI

/// Card component that displays student info along with their app profile for a given timeslot
struct StudentProfileCard: View {
    let student: Student
    let timeslot: TimeOfDay
    let dayString: String
    
    @State private var showingDetail = false
    
    // MARK: - Computed Properties
    
    private var session: Session {
        MockStudentAppProfileProvider.getSession(for: student.id, day: dayString, timeslot: timeslot)
    }
    
    private var apps: [MockStudentAppProfileProvider.MockApp] {
        MockStudentAppProfileProvider.getApps(byIds: session.apps)
    }
    
    private var sessionLengthMinutes: Int {
        Int(session.sessionLength)
    }
    
    /// Calculate fill percentage (5-60 minute range)
    private var sessionFillPercentage: CGFloat {
        let minValue: CGFloat = 5
        let maxValue: CGFloat = 60
        let value = CGFloat(session.sessionLength)
        return max(0, min(1, (value - minValue) / (maxValue - minValue)))
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 10) {
                // Student Photo
                studentPhotoView
                
                // Student Name
                VStack(spacing: 2) {
                    Text(student.firstName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(student.lastName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                // App Icons Row
                appIconsRow
                
                // Session Length Bar
                sessionLengthBar
            }
            .frame(width: 140, height: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $showingDetail) {
            StudentProfileEditView(student: student, timeslot: timeslot, dayString: dayString)
        }
    }
    
    // MARK: - Subviews
    
    private var studentPhotoView: some View {
        AsyncImage(url: student.photo) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 60, height: 60)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            case .failure:
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            @unknown default:
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
        }
        .overlay(
            Circle()
                .stroke(Color.accentColor, lineWidth: 2)
        )
    }
    
    private var appIconsRow: some View {
        HStack(spacing: 6) {
            if apps.isEmpty {
                // No apps configured
                Image(systemName: "app.dashed")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("No apps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if apps.count == 1 {
                // Single app - show larger icon and name
                Image(systemName: apps[0].iconSystemName)
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(apps[0].name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                // Multiple apps - show first app icon with "+" indicator
                Image(systemName: apps[0].iconSystemName)
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("+")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 40)
    }
    
    private var sessionLengthBar: some View {
        VStack(spacing: 2) {
            // Session length label
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(sessionLengthMinutes) min")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            // Visual bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray4))
                        .frame(height: 6)
                    
                    // Filled portion
                    RoundedRectangle(cornerRadius: 3)
                        .fill(sessionBarColor)
                        .frame(width: geometry.size.width * sessionFillPercentage, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 8)
        }
    }
    
    /// Color for session bar based on fill percentage
    private var sessionBarColor: Color {
        if sessionFillPercentage < 0.33 {
            return .green
        } else if sessionFillPercentage < 0.66 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Student Profile Edit View (Placeholder)

struct StudentProfileEditView: View {
    let student: Student
    let timeslot: TimeOfDay
    let dayString: String
    
    private var session: Session {
        MockStudentAppProfileProvider.getSession(for: student.id, day: dayString, timeslot: timeslot)
    }
    
    private var apps: [MockStudentAppProfileProvider.MockApp] {
        MockStudentAppProfileProvider.getApps(byIds: session.apps)
    }
    
    private var timeslotLabel: String {
        switch timeslot {
        case .am: return "AM (9:00-11:59)"
        case .pm: return "PM (12:00-4:59)"
        case .home: return "Home (5:00+)"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Student Photo
                AsyncImage(url: student.photo) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 4)
                            )
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                
                // Student Info
                VStack(spacing: 4) {
                    Text(student.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(dayString) • \(timeslotLabel)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Current Apps Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assigned Apps")
                        .font(.headline)
                    
                    if apps.isEmpty {
                        Text("No apps configured for this timeslot")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        ForEach(apps) { app in
                            HStack {
                                Image(systemName: app.iconSystemName)
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 44, height: 44)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                Text(app.name)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Session Length Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Length")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("\(Int(session.sessionLength)) minutes")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Edit Button Placeholder
                Button {
                    // Future: Open edit sheet
                } label: {
                    Text("Edit Profile")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle("Student Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

struct StudentProfileCard_Previews: PreviewProvider {
    static let placeholderPhoto = URL(string: "https://via.placeholder.com/100")!
    
    static var mockStudent: Student {
        Student(
            id: 123,
            name: "John Doe",
            email: "john.doe@school.edu",
            username: "johndoe",
            firstName: "John",
            lastName: "Doe",
            photo: placeholderPhoto
        )
    }
    
    static var previews: some View {
        Group {
            // Single card preview
            StudentProfileCard(
                student: mockStudent,
                timeslot: .am,
                dayString: "Mon"
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("AM Timeslot")
            
            // Multiple cards in grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 140), spacing: 16)
                ], spacing: 16) {
                    StudentProfileCard(student: mockStudent, timeslot: .am, dayString: "Mon")
                    StudentProfileCard(student: Student(
                        id: 456,
                        name: "Jane Smith",
                        email: "jane.smith@school.edu",
                        username: "janesmith",
                        firstName: "Jane",
                        lastName: "Smith",
                        photo: placeholderPhoto
                    ), timeslot: .am, dayString: "Mon")
                    StudentProfileCard(student: Student(
                        id: 789,
                        name: "Bob Johnson",
                        email: "bob.j@school.edu",
                        username: "bobj",
                        firstName: "Bob",
                        lastName: "Johnson",
                        photo: placeholderPhoto
                    ), timeslot: .am, dayString: "Mon")
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .previewDisplayName("Grid View")
        }
    }
}

struct StudentProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StudentProfileEditView(
                student: StudentProfileCard_Previews.mockStudent,
                timeslot: .am,
                dayString: "Mon"
            )
        }
    }
}

