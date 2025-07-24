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
    
    @Environment(GeneralVM.self) private var gvm
    @Environment(\.dismiss) private var dismiss
    
    @State var barcode_value: String? = nil
    @State var showEnterCodeManuallyAlert = false
    @State var path = NavigationPath()
    
    @State var alertMessage = "You can manually enter the product’s barcode if scanning isn’t working."
    
    @Binding var passed_barcode_value: String?
        
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    Group {
                        if gvm.shouldHideCamera || showEnterCodeManuallyAlert {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                        } else {
                            BarcodeScanner(barcode_value: scannedCodeOption == .scanned ? $barcode_value : $passed_barcode_value)
                        }
                    }.clipShape(.rect(cornerRadius: 16))
                 
                    Label("Click on the barcode as soon as it's highlighted to view the product's details",
                          systemImage: "i.circle")
                    .font(.caption)
                    .foregroundStyle(.colorTextTertiary)
                    .padding(.bottom)
                    
                    Button("Enter Code Manually") {
                        showEnterCodeManuallyAlert = true
                    }
                    
                    Spacer()
                } else {
                    ContentUnavailableView {
                        Label("Can't Accesss Camera", systemImage: "camera.macro.slash")
                    } description: {
                        Text("Looks like we can't access your camera right now!")
                    } actions: {
                        Button("Enter Code Manually") {
                            alertMessage = "Looks Like We Can't Access Your Camera, Please Enter the Code Manually"
                            showEnterCodeManuallyAlert = true
                        }.buttonStyle(.borderedProminent)
                    }
                }
            }.padding()
                .background(.colorBackground)
                .onChange(of: barcode_value) { old, new in
                    if let code = barcode_value, !showEnterCodeManuallyAlert { // Alert isn't showing
                        path.append(code)
                    }
                }.onChange(of: passed_barcode_value) {
                    if !showEnterCodeManuallyAlert {
                        dismiss()
                    }
                }
                .alert("Enter Value", isPresented: $showEnterCodeManuallyAlert) {
                    let barcodeBinding: Binding<String> = {
                        if scannedCodeOption == .scanned {
                            return Binding(
                                get: { barcode_value ?? "" },
                                set: { barcode_value = $0 }
                            )
                        } else {
                            return Binding(
                                get: { passed_barcode_value ?? "" },
                                set: { passed_barcode_value = $0 }
                            )
                        }
                    }()

                    TextField("Barcode", text: barcodeBinding)
                        .keyboardType(.numberPad)

                    Button("Done") {
                        if scannedCodeOption == .scanned {
                            path.append(barcode_value ?? "")
                        } else {
                            dismiss()
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
                .navigationDestination(for: String.self) { str in
                    ProductDetailsView(barcode: str, increaseScans: true)
                }
        }
        
    }
}

#Preview {
    ScannerView(scannedCodeOption: .scanned, passed_barcode_value: .constant(""))
        .environment(GeneralVM())
}
