//
//  ClassCard.swift
//  appi4Manager
//
//  Created by Assistant on 2024-05-22.
//

import SwiftUI

struct ClassCard: View {
    let schoolClass: SchoolClass
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Class Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gradient(for: schoolClass.name))
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Text(initials(for: schoolClass.name))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            // Class Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(schoolClass.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if !schoolClass.description.isEmpty {
                    Text(schoolClass.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No description")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
                
                // Badges Row
                HStack(spacing: 8) {
                    // Active/Inactive Badge
                    StatusBadge(isActive: isActive)
                    
                    // Group Badge
                    HStack(spacing: 4) {
                        Text("Grp \(schoolClass.userGroupId)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
                    

                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.gray.opacity(0.5))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // Helper to extract up to 2 initials
    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if components.isEmpty { return "?" }
        
        if let first = components.first?.first {
            if components.count > 1, let second = components.last?.first {
                return "\(first)\(second)".uppercased()
            }
            // If only one word, try to task first 2 chars
            let name = components[0]
            if name.count >= 2 {
                let index = name.index(name.startIndex, offsetBy: 2)
                return String(name[..<index]).uppercased()
            }
            return String(first).uppercased()
        }
        return "?"
    }
}

// Separate component for the status badge
private struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "Active" : "Inactive")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .foregroundStyle(isActive ? .green : .gray)
            .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack {
            ClassCard(schoolClass: SchoolClass(uuid: "1", name: "DemoMath", description: "Advanced Algebra", locationId: 1, userGroupId: 12, teacherCount: 2), isActive: true)
            
            ClassCard(schoolClass: SchoolClass(uuid: "2", name: "History 101", description: "", locationId: 1, userGroupId: 5, teacherCount: 0), isActive: false)
        }
        .padding()
    }
}
