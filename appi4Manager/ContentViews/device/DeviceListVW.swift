//
//  DeviceListVW.swift
//  appi4Manager
//
//  Created by Steven Hertz on 1/4/24.
//

import SwiftUI

struct DeviceListVW: View {
    @StateObject var devicesViewModel = DevicesViewModel()
    @State private var hasError = false
    @State private var error: ApiError?
    
    @State private var selectedDevice: TheDevice?
    @Binding var isPresented: Bool  // Binding to control the presentation

      // Closure to pass the selected device back
      var onDeviceSelect: ((TheDevice) -> Void)?

    
    
    var body: some View {
        List(devicesViewModel.devices) { device in
            VStack(alignment: .leading) {
                Text(device.title)
                    .font(.headline)
                Text("Serial Number: \(device.serialNumber)")
                Text("Battery Level: \(device.batteryLevel, specifier: "%.2f")%")
                    // Add more details as needed
            }
            .onTapGesture {
                if let onSelect = onDeviceSelect {
//                    self.selectedDevice = device
                    onSelect(device)
                    self.isPresented = false
                }
             }

            
        }
        
            //      MARK: - Task Modifier    * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
            .task {
                if devicesViewModel.ignoreLoading {
                    devicesViewModel.ignoreLoading = false
                        // Don't load the classes if ignoreLoading is true
                } else {
                        // Load the classes if ignoreLoading is false
                    await loadTheClasses()
                    devicesViewModel.ignoreLoading = false
                }
                
            }
    }
}

private extension DeviceListVW {
    func loadTheClasses() async {
        do {
            try await devicesViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
}

//
//#Preview {
//    DeviceListVW(, isPresented: Binding<)
//}
