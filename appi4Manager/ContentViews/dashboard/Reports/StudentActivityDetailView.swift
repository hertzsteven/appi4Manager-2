//
//  StudentActivityDetailView.swift
//  appi4Manager
//
//  Displays detailed activity history for a single student.
//  Shows all app sessions grouped by date with filtering options.
//

import SwiftUI

/// Detailed view of a single student's activity history
struct StudentActivityDetailView: View {
    let student: Student
    let deviceApps: [DeviceApp]
    
    /// The filter to apply when the view first loads.
    /// Defaults to `.today` but can be overridden by the presenting view
    /// to preserve the user's previous selection.
    var initialFilter: ActivityDateFilter = .today
    var initialCustomStartDate: Date?
    var initialCustomEndDate: Date?
    
    @State private var viewModel = StudentActivityReportViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with student info
            studentHeader
                .padding()
                .background(Color(.systemBackground))
            
            // Date filter
            ActivityDateFilterView(
                selectedFilter: $viewModel.selectedFilter,
                customStartDate: $viewModel.customStartDate,
                customEndDate: $viewModel.customEndDate,
                onFilterChanged: {
                    Task {
                        await viewModel.reloadWithFilter(studentId: student.id)
                    }
                }
            )
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
            
            // Activity list
            activityContent
        }
        .background(Color(.systemGray6))
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.selectedFilter = initialFilter
            if let start = initialCustomStartDate {
                viewModel.customStartDate = start
            }
            if let end = initialCustomEndDate {
                viewModel.customEndDate = end
            }
            await viewModel.loadActivityForStudent(studentId: student.id)
        }
    }
    
    // MARK: - Student Header
    
    private var studentHeader: some View {
        HStack(spacing: 16) {
            // Student photo
            AsyncImage(url: student.photo) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(.circle)
                default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.gray)
                }
            }
            
            // Student info
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("\(viewModel.totalSessionCount) sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Activity Content
    
    @ViewBuilder
    private var activityContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.allSessions.isEmpty {
            emptyStateView
        } else {
            sessionsList
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading activity...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Activity", systemImage: "clock.badge.questionmark")
        } description: {
            Text("No activity records found for the selected time period.")
        } actions: {
            Button("Try All Time") {
                viewModel.selectedFilter = .all
                Task {
                    await viewModel.reloadWithFilter(studentId: student.id)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                let grouped = viewModel.sessionsByDate(viewModel.allSessions)
                let sortedKeys = viewModel.sortedDateKeys(grouped)
                
                ForEach(sortedKeys, id: \.self) { dateKey in
                    Section {
                        VStack(spacing: 8) {
                            ForEach(grouped[dateKey] ?? [], id: \.id) { session in
                                ActivityRowView(session: session, deviceApps: deviceApps)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    } header: {
                        dateSectionHeader(dateKey)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func dateSectionHeader(_ dateKey: String) -> some View {
        HStack {
            Text(viewModel.formatDateHeader(dateKey))
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            let sessionsForDate = viewModel.sessionsByDate(viewModel.allSessions)[dateKey]?.count ?? 0
            Text("\(sessionsForDate) sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
}

// MARK: - Preview

#Preview("Student Activity Detail") {
    let placeholderPhoto = URL(string: "https://via.placeholder.com/100")!
    let mockStudent = Student(
        id: 123,
        name: "Hillary Cruz",
        email: "hillary@school.edu",
        username: "hcruz",
        firstName: "Hillary",
        lastName: "Cruz",
        photo: placeholderPhoto
    )
    
    return NavigationStack {
        StudentActivityDetailView(
            student: mockStudent,
            deviceApps: []
        )
    }
}
