//
//  TeacherStudentsView.swift
//  appi4Manager
//
//  Student display views for the teacher dashboard.
//  Includes TeacherStudentsView, SelectableStudentCard, and StudentDetailView.
//

import SwiftUI

// MARK: - Teacher Students View

struct TeacherStudentsView: View {
    let teacherClasses: [TeacherClassInfo]
    
    /// Data provider for real Firebase student profiles
    @State private var dataProvider = StudentAppProfileDataProvider()
    
    /// Selected timeslot for viewing app profiles
    /// Defaults to .am during blocked hours since there's no overnight view
    @State private var selectedTimeslot: TimeOfDay = {
        let current = StudentAppProfileDataProvider.currentTimeslot()
        return current == .blocked ? .am : current
    }()
    
    /// Current day string for profile lookup
    private var currentDayString: String {
        StudentAppProfileDataProvider.currentDayString()
    }
    
    /// All students flattened from all classes
    private var allStudents: [Student] {
        teacherClasses.flatMap { $0.students }
    }
    
    /// All devices flattened from all classes (for accessing installed apps)
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timeslot Picker
            timeslotPicker
            
            // Header subtitle
            Text("Student App Profiles for \(currentDayString)")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Content based on loading state
            if dataProvider.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading student profiles...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if let error = dataProvider.errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error Loading Profiles")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task {
                            await dataProvider.loadProfiles(for: allStudents.map { $0.id })
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
                // Students Grid with Profile Cards
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(teacherClasses) { classInfo in
                            ForEach(classInfo.students, id: \.id) { student in
                                StudentProfileCard(
                                    student: student,
                                    timeslot: selectedTimeslot,
                                    dayString: currentDayString,
                                    dataProvider: dataProvider,
                                    classDevices: allDevices,
                                    dashboardMode: .now,
                                    locationId: classInfo.locationId,
                                    activeSession: nil  // This view doesn't use real-time sessions
                                )
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
            }
        }
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Load profiles when view appears
            await dataProvider.loadProfiles(for: allStudents.map { $0.id })
        }
    }
    
    // MARK: - Timeslot Picker
    
    private var timeslotPicker: some View {
        VStack(spacing: 4) {
            Picker("Timeslot", selection: $selectedTimeslot) {
                Text("AM").tag(TimeOfDay.am)
                Text("PM").tag(TimeOfDay.pm)
                Text("Home").tag(TimeOfDay.home)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Timeslot time range label
            Text(timeslotTimeRange)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .background(Color(.systemBackground))
    }
    
    private var timeslotTimeRange: String {
        TimeslotSettings.timeRangeString(for: selectedTimeslot)
    }
}


// MARK: - Selectable Student Card

struct SelectableStudentCard: View {
    let student: Student
    
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 8) {
                // Student Photo
                AsyncImage(url: student.photo) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 70, height: 70)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 3)
                )
                
                // Student Name
                Text(student.firstName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Last Name
                Text(student.lastName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120, height: 130)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $showingDetail) {
            StudentDetailView(student: student)
        }
    }
}

// MARK: - Student Detail View (Placeholder)

struct StudentDetailView: View {
    let student: Student
    
    var body: some View {
        VStack(spacing: 24) {
            // Student Photo
            AsyncImage(url: student.photo) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 120, height: 120)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 4)
                        )
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
            }
            
            // Student Info
            VStack(spacing: 8) {
                Text(student.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(student.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Username: \(student.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Placeholder for future actions
            VStack(spacing: 16) {
                Text("Student Actions")
                    .font(.headline)
                
                Text("Future actions like viewing app schedules or device assignments will go here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Student Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
