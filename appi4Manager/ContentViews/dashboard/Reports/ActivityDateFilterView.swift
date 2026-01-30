//
//  ActivityDateFilterView.swift
//  appi4Manager
//
//  Date filter component for the Student Activity Report.
//  Provides preset filters (Today, Week, Month, All) and custom date range picker.
//

import SwiftUI

/// Horizontal filter bar with preset buttons and custom date picker
struct ActivityDateFilterView: View {
    @Binding var selectedFilter: ActivityDateFilter
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date
    
    /// Called when filter changes
    var onFilterChanged: () -> Void
    
    @State private var showCustomPicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Preset filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ActivityDateFilter.allCases) { filter in
                        FilterPillButton(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                            if filter == .custom {
                                showCustomPicker = true
                            } else {
                                onFilterChanged()
                            }
                        }
                    }
                }
            }
            
            // Custom date range display (when custom is selected)
            if selectedFilter == .custom {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "",
                            selection: $customStartDate,
                            in: ...customEndDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("To")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "",
                            selection: $customEndDate,
                            in: customStartDate...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    
                    Spacer()
                    
                    Button("Apply") {
                        onFilterChanged()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 10))
            }
        }
    }
}

/// Individual filter pill button
struct FilterPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Date Filter") {
    struct PreviewWrapper: View {
        @State private var filter: ActivityDateFilter = .today
        @State private var startDate = Date()
        @State private var endDate = Date()
        
        var body: some View {
            VStack {
                ActivityDateFilterView(
                    selectedFilter: $filter,
                    customStartDate: $startDate,
                    customEndDate: $endDate,
                    onFilterChanged: { print("Filter changed to \(filter)") }
                )
                .padding()
                
                Spacer()
            }
        }
    }
    
    return PreviewWrapper()
}
