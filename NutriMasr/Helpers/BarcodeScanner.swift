//
//  BarcodeScaner.swift
//  NutriMasr
//
//  Created by Mark George on 22/06/2025.
//

import SwiftUI
import VisionKit

@MainActor
struct BarcodeScanner: UIViewControllerRepresentable {
    typealias UIViewControllerType = DataScannerViewController
    
//    @Binding var barcode_value: String?
    let tapped: (String) -> ()
    
    var scannerViewController: DataScannerViewController = DataScannerViewController(
        recognizedDataTypes: [.barcode()],
        qualityLevel: .accurate,
        recognizesMultipleItems: false,
        isHighFrameRateTrackingEnabled: false,
        isHighlightingEnabled: true
    )
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        scannerViewController.delegate = context.coordinator
        
        try? scannerViewController.startScanning()
        return scannerViewController
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // Class that manages interactions between DataScannerViewController and SwiftUI.
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: BarcodeScanner
        
        init(_ parent: BarcodeScanner) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
//                    parent.barcode_value = payload
                    parent.tapped(payload)
                } else {
                    print("⚠️ Barcode has no payload string value")
                }
            default:
                print("❌ Not a barcode")
            }
        }
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }
}
