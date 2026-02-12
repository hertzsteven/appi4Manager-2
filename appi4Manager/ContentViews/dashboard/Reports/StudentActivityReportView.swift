//
//  StudentActivityReportView.swift
//  appi4Manager
//
//  Main report view showing summary of all students' activity.
//  Displays a list of students with session counts, allowing drill-down to details.
//

import SwiftUI

/// Main view for the Student Activity Report feature
struct StudentActivityReportView: View {
    let students: [Student]
    let deviceApps: [DeviceApp]
    let activeClass: TeacherClassInfo?
    let classesWithDevices: [TeacherClassInfo]
    
    @State private var viewModel = StudentActivityReportViewModel()
    @State private var searchText = ""
    
    /// Filtered summaries based on search text
    private var filteredSummaries: [StudentActivitySummary] {
        if searchText.isEmpty {
            return viewModel.studentSummaries
        }
        return viewModel.studentSummaries.filter { summary in
            summary.student.name.localizedStandardContains(searchText) ||
            summary.student.firstName.localizedStandardContains(searchText) ||
            summary.student.lastName.localizedStandardContains(searchText)
        }
    }
    
    /// Students with activity
    private var studentsWithActivity: [StudentActivitySummary] {
        filteredSummaries.filter { $0.totalSessions > 0 }
    }
    
    /// Students without any activity
    private var studentsWithoutActivity: [StudentActivitySummary] {
        filteredSummaries.filter { $0.totalSessions == 0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Date filter bar
            ActivityDateFilterView(
                selectedFilter: $viewModel.selectedFilter,
                customStartDate: $viewModel.customStartDate,
                customEndDate: $viewModel.customEndDate,
                onFilterChanged: {
                    Task {
                        await viewModel.reloadWithFilter(students)
                    }
                }
            )
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // Summary stats bar
            summaryStatsBar
                .padding(.horizontal)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
            
            Divider()
            
            // Main content
            reportContent
        }
        .background(Color(.systemGray5))
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .teacherDashboardToolbar(
            activeClass: activeClass,
            classesWithDevices: classesWithDevices
        )
        .searchable(text: $searchText, prompt: "Search students")
        .task {
            await viewModel.loadActivityForStudents(students)
        }
    }
    
    // MARK: - Summary Stats Bar
    
    private var summaryStatsBar: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Total Sessions",
                value: "\(viewModel.totalSessionCount)",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            StatCard(
                title: "Active Students",
                value: "\(studentsWithActivity.count)",
                icon: "person.fill.checkmark",
                color: .green
            )
            
            StatCard(
                title: "No Activity",
                value: "\(studentsWithoutActivity.count)",
                icon: "person.fill.questionmark",
                color: .orange
            )
        }
    }
    
    // MARK: - Report Content
    
    @ViewBuilder
    private var reportContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.studentSummaries.isEmpty {
            emptyStateView
        } else {
            studentsList
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading student activity...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Students", systemImage: "person.3.fill")
        } description: {
            Text("No students found to report on.")
        }
    }
    
    private var studentsList: some View {
        List {
            // Students with activity
            if !studentsWithActivity.isEmpty {
                Section {
                    ForEach(studentsWithActivity) { summary in
                        NavigationLink {
                            StudentActivityDetailView(
                                student: summary.student,
                                deviceApps: deviceApps
                            )
                        } label: {
                            StudentActivitySummaryRow(
                                summary: summary,
                                deviceApps: deviceApps
                            )
                        }
                    }
                } header: {
                    Text("Active Students (\(studentsWithActivity.count))")
                }
            }
            
            // Students without activity
            if !studentsWithoutActivity.isEmpty {
                Section {
                    ForEach(studentsWithoutActivity) { summary in
                        NavigationLink {
                            StudentActivityDetailView(
                                student: summary.student,
                                deviceApps: deviceApps
                            )
                        } label: {
                            StudentActivitySummaryRow(
                                summary: summary,
                                deviceApps: deviceApps
                            )
                        }
                    }
                } header: {
                    Text("No Activity (\(studentsWithoutActivity.count))")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Student Activity Summary Row

/// Row component for the summary list showing student and their session count
struct StudentActivitySummaryRow: View {
    let summary: StudentActivitySummary
    let deviceApps: [DeviceApp]
    
    var body: some View {
        HStack(spacing: 14) {
            // Student photo
            AsyncImage(url: summary.student.photo) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(.circle)
                default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.gray)
                }
            }
            
            // Student info and recent apps
            VStack(alignment: .leading, spacing: 6) {
                Text(summary.student.name)
                    .font(.headline)
                
                if summary.totalSessions > 0 {
                    // Recent apps preview
                    recentAppsPreview
                } else {
                    Text("No activity in this period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Session count badge
            sessionCountBadge
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var recentAppsPreview: some View {
        HStack(spacing: -6) {
            ForEach(summary.recentApps.prefix(3), id: \.self) { bundleId in
                if let app = deviceApps.first(where: { $0.identifier == bundleId }) {
                    AsyncImage(url: app.iconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .clipShape(.rect(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color(.systemBackground), lineWidth: 2)
                                )
                        default:
                            smallAppPlaceholder
                        }
                    }
                } else {
                    smallAppPlaceholder
                }
            }
            
            if summary.recentApps.count > 3 {
                Text("+\(summary.recentApps.count - 3)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            }
        }
    }
    
    private var smallAppPlaceholder: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: "app.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(.systemBackground), lineWidth: 2)
            )
    }
    
    private var sessionCountBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(summary.totalSessions)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(summary.totalSessions > 0 ? .primary : .secondary)
            
            Text(summary.totalSessions == 1 ? "session" : "sessions")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Stat Card

/// Small stat card component for the summary bar
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(.rect(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview("Activity Report") {
    let placeholderPhoto = URL(string: "https://via.placeholder.com/100")!
    let mockStudents = [
        Student(id: 1, name: "Hillary Cruz", email: "hillary@school.edu",
               username: "hcruz", firstName: "Hillary", lastName: "Cruz",
               photo: placeholderPhoto),
        Student(id: 2, name: "Dante Chenell", email: "dante@school.edu",
               username: "dchenell", firstName: "Dante", lastName: "Chenell",
               photo: placeholderPhoto),
        Student(id: 3, name: "John Smith", email: "john@school.edu",
               username: "jsmith", firstName: "John", lastName: "Smith",
               photo: placeholderPhoto)
    ]
    
    return NavigationStack {
        StudentActivityReportView(
            students: mockStudents,
            deviceApps: [],
            activeClass: nil,
            classesWithDevices: []
        )
    }
}
