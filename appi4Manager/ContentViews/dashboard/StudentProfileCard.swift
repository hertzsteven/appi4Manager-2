//
//  StudentProfileCard.swift
//  appi4Manager
//
//  Enhanced student card that shows app profile information from Firebase
//

import SwiftUI

/// Card component that displays student info along with their app profile for a given timeslot
struct StudentProfileCard: View {
    let student: Student
    let timeslot: TimeOfDay
    let dayString: String
    let dataProvider: StudentAppProfileDataProvider
    
    @State private var apps: [Appx] = []
    @State private var isLoadingApps = true
    
    // MARK: - Computed Properties
    
    private var session: Session? {
        dataProvider.getSession(for: student.id, day: dayString, timeslot: timeslot)
    }
    
    private var hasProfile: Bool {
        dataProvider.hasProfile(for: student.id)
    }
    
    private var sessionLengthMinutes: Int {
        Int(session?.sessionLength ?? 0)
    }
    
    /// Calculate fill percentage (5-60 minute range)
    private var sessionFillPercentage: CGFloat {
        let minValue: CGFloat = 5
        let maxValue: CGFloat = 60
        let value = CGFloat(session?.sessionLength ?? 0)
        return max(0, min(1, (value - minValue) / (maxValue - minValue)))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationLink {
            StudentProfileEditView(
                student: student,
                timeslot: timeslot,
                dayString: dayString,
                dataProvider: dataProvider
            )
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
                
                // App Icons Row or No Profile Placeholder
                if hasProfile {
                    appIconsRow
                    sessionLengthBar
                } else {
                    noProfileView
                }
            }
            .frame(width: 140, height: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .task(id: "\(student.id)-\(dayString)-\(timeslot)") {
            await loadApps()
        }
    }
    
    // MARK: - Load Apps
    
    private func loadApps() async {
        isLoadingApps = true
        if let session = session {
            apps = await dataProvider.getApps(byIds: session.apps)
        } else {
            apps = []
        }
        isLoadingApps = false
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
                .stroke(hasProfile ? Color.accentColor : Color.gray, lineWidth: 2)
        )
    }
    
    private var noProfileView: some View {
        VStack(spacing: 4) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            Text("No profile")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 60)
    }
    
    private var appIconsRow: some View {
        HStack(spacing: 6) {
            if isLoadingApps {
                ProgressView()
                    .frame(width: 36, height: 36)
            } else if apps.isEmpty {
                // No apps configured
                Image(systemName: "app.dashed")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("No apps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if apps.count == 1 {
                // Single app - show icon and name
                AsyncImage(url: URL(string: apps[0].icon)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        Image(systemName: "app.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                            .frame(width: 36, height: 36)
                    }
                }
                Text(apps[0].name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                // Multiple apps - show first icon with "+" indicator
                AsyncImage(url: URL(string: apps[0].icon)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        Image(systemName: "app.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                            .frame(width: 36, height: 36)
                    }
                }
                Text("+\(apps.count - 1)")
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

// MARK: - Student Profile Edit View

struct StudentProfileEditView: View {
    let student: Student
    let timeslot: TimeOfDay
    let dayString: String
    let dataProvider: StudentAppProfileDataProvider
    
    @State private var apps: [Appx] = []
    @State private var isLoadingApps = true
    
    private var session: Session? {
        dataProvider.getSession(for: student.id, day: dayString, timeslot: timeslot)
    }
    
    private var hasProfile: Bool {
        dataProvider.hasProfile(for: student.id)
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
                                    .stroke(hasProfile ? Color.accentColor : Color.gray, lineWidth: 4)
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
                
                if !hasProfile {
                    // No Profile Section
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Profile Found")
                            .font(.headline)
                        Text("This student doesn't have an app profile configured in the system yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    // Current Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assigned Apps")
                            .font(.headline)
                        
                        if isLoadingApps {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if apps.isEmpty {
                            Text("No apps configured for this timeslot")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            ForEach(apps, id: \.id) { app in
                                HStack {
                                    AsyncImage(url: URL(string: app.icon)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        default:
                                            Image(systemName: "app.fill")
                                                .font(.title2)
                                                .foregroundColor(.accentColor)
                                                .frame(width: 44, height: 44)
                                                .background(Color.accentColor.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(app.name)
                                            .font(.body)
                                        if let description = app.description, !description.isEmpty {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    
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
                    if let session = session {
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
                    }
                }
                
                // Edit Button Placeholder
                Button {
                    // Future: Open edit sheet
                } label: {
                    Text("Edit Profile")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasProfile ? Color.accentColor : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!hasProfile)
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle("Student Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadApps()
        }
    }
    
    private func loadApps() async {
        isLoadingApps = true
        if let session = session {
            apps = await dataProvider.getApps(byIds: session.apps)
        } else {
            apps = []
        }
        isLoadingApps = false
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
                dayString: "Mon",
                dataProvider: StudentAppProfileDataProvider()
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("AM Timeslot")
        }
    }
}

struct StudentProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StudentProfileEditView(
                student: StudentProfileCard_Previews.mockStudent,
                timeslot: .am,
                dayString: "Mon",
                dataProvider: StudentAppProfileDataProvider()
            )
        }
    }
}
