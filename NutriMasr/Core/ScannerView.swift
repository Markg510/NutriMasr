//
//  ScannerView.swift
//  NutriMasr
//
//  Created by Mark George on 22/06/2025.
//

import SwiftUI
import VisionKit

struct ScannerView: View {
    enum ScannerCodeOptions {
        case passed, scanned
    }
    
    let scannedCodeOption: ScannerCodeOptions
    
    @Environment(\.dismiss) var dismiss
    @Environment(GeneralVM.self) private var gvm
    
    @AppStorage("todayScannedCount") private var todayScannedCount: Int = 0
    @AppStorage("lastScannedDate") private var lastScannedDate: Date = .now
    
    @State var barcode_value: String? = nil
    @State var shouldNavigate = false
    @State var showEnterCodeManuallyAlert = false
    @State var manualCode = ""
    @State var path = NavigationPath()
    
    @Binding var passed_barcode_value: String?
    
    var updateScannedCount = false
    
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                VStack {
                    if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                        let width = proxy.size.width
                        Group {
                            if gvm.shouldHideCamera {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray5))
                            } else {
                                BarcodeScanner(barcode_value: scannedCodeOption == .scanned ? $barcode_value : $passed_barcode_value)
                            }
                        }.frame(width: width, height: width)
                            .clipShape(.rect(cornerRadius: 16))
                        
                        Label("Click on the barcode as soon as it's highlighted to view the product's details",
                              systemImage: "i.circle")
                        .font(.caption)
                        .foregroundStyle(.colorTextTertiary)
                        .padding(.bottom)
                         
                        Button("Enter Code Manually") {
                            showEnterCodeManuallyAlert = true
                        }.alert("Enter Value", isPresented: $showEnterCodeManuallyAlert) {
                            TextField("Value", value: scannedCodeOption == .scanned ? $barcode_value : $passed_barcode_value, formatter: NumberFormatter())
                            
                            Button("Done") {
                                if scannedCodeOption == .scanned {
                                    dismiss()
                                }
                            }
                        } message: {
                            Text("You can manually enter the product’s barcode if scanning isn’t working.")
                        }
                        
                        Spacer()
                    }
                }
            }.padding()
                .background(.colorBackground)
                .onChange(of: barcode_value) {
                    if barcode_value != nil {
                        if Calendar.current.isDateInToday(lastScannedDate) {
                            todayScannedCount += 1
                        }
                        shouldNavigate = true
                    }
                }.onChange(of: passed_barcode_value) {
                    gvm.path.append(barcode_value)
                }
                .navigationDestination(isPresented: $shouldNavigate) {
                    ProductDetailsView(barcode: barcode_value)
                }
        }
        
    }
}

#Preview {
    ScannerView(scannedCodeOption: .scanned, passed_barcode_value: .constant(""))
        .environment(GeneralVM())
}
