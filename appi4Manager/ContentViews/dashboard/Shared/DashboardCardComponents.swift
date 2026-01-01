//
//  DashboardCardComponents.swift
//  appi4Manager
//
//  Reusable card components for the dashboard views.
//  Includes DayPillButtonDashboard, StudentCard, DeviceCard, and TeacherCategoryCard.
//

import SwiftUI

// MARK: - Day Pill Button for Dashboard

/// Compact day selector button for the dashboard Planning mode
struct DayPillButtonDashboard: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void
    
    private var shortName: String {
        switch day {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(shortName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Student Card

struct StudentCard: View {
    let student: Student
    
    var body: some View {
        VStack(spacing: 8) {
            // Student Photo
            AsyncImage(url: student.photo) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.accentColor, lineWidth: 3)
            )
            
            // Student Name
            Text(student.firstName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(width: 100)
        .padding(.vertical, 8)
    }
}

// MARK: - Device Card

struct DeviceCard: View {
    let device: TheDevice
    
    /// Determines the ring color based on the device name
    private var ringColor: Color {
        let lowercasedName = device.name.lowercased()
        if lowercasedName.contains("blue") {
            return .blue
        } else if lowercasedName.contains("silver") || lowercasedName.contains("gray") || lowercasedName.contains("grey") {
            return Color(white: 0.6)
        } else if lowercasedName.contains("gold") {
            return Color.yellow
        } else if lowercasedName.contains("pink") || lowercasedName.contains("rose") {
            return .pink
        } else if lowercasedName.contains("purple") {
            return .purple
        } else if lowercasedName.contains("green") {
            return .green
        } else if lowercasedName.contains("red") {
            return .red
        } else if lowercasedName.contains("orange") {
            return .orange
        } else {
            return .gray
        }
    }
    
    /// Extract model info from the device
    private var modelInfo: String {
        // Using assetTag or any other available model info
        "iPad"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Device Icon with colored ring
            ZStack {
                Circle()
                    .stroke(ringColor, lineWidth: 4)
                    .frame(width: 70, height: 70)
                
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
            }
            
            // Device Name
            Text(device.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            // Model Info
            Text(modelInfo)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Teacher Category Card

struct TeacherCategoryCard: View {
    let name: String
    let color: Color
    let iconName: String
    let count: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .shadow(radius: 5)
                .overlay(
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.white)
                            }
                            .padding([.bottom], 8)
                            
                            Text(name)
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(.secondary)
                        }
                        .padding([.leading], 4)
                        
                        Spacer()
                        
                        VStack {
                            Text("\(count)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding([.top], 4)
                                .padding([.trailing], 18)
                            Spacer()
                        }
                    }
                    .padding(.leading, 10)
                )
        }
    }
}
