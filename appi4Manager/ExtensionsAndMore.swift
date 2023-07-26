//
//  ExtensionsAndMore.swift
//  list the users
//
//  Created by Steven Hertz on 3/19/23.
//

import Foundation
import SwiftUI

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        let uniqueElements = Set(self)
        return Array(uniqueElements)
    }
}

extension Binding: Equatable where Value: Equatable {
    public static func == (lhs: Binding<Value>, rhs: Binding<Value>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Binding: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.wrappedValue.hash(into: &hasher)
    }
}

protocol ItemsToSelectRepresentable: Identifiable {
    var locationId: Int { get }
    var nameToDisplay: String { get }
    var id: Int { get }
}



protocol ItemsToSelectRepresentablewithPic: Identifiable {
    var locationId: Int { get }
    var nameToDisplay: String { get }
    var id: Int { get }
    var icon: String { get}
}



struct OnScroll: ViewModifier {
    let onScroll: (CGFloat) -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(GeometryReader { proxy in
                Color.clear.preference(key: ViewOffsetKey.self, value: proxy.frame(in: .global).minY)
            })
            .onPreferenceChange(ViewOffsetKey.self, perform: onScroll)
    }
    
    struct ViewOffsetKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value += nextValue()
        }
    }
}

extension View {
    func onScroll(perform action: @escaping (CGFloat) -> Void) -> some View {
        self.modifier(OnScroll(onScroll: action))
    }
}
