//
//  productDetailsView.swift
//  NutriMasr
//
//  Created by Mark George on 20/06/2025.
//

import SwiftUI

struct ProductDetailsView: View {
    @Environment(GeneralVM.self) var gvm
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("todayScannedCount") private var todayScannedCount: Int = 0
    @AppStorage("lastScannedDate") private var lastScannedDate: Date = .now
    
    @State private var showFactsPer: CustomSegmentedPickerOptions = .serving
    @State private var vm = ProductDetailsVM()
    
    var passed_product: Product? = nil
    var barcode: String? = nil
    let increaseScans: Bool
        
    init(product: Product, increaseScans: Bool = false) {
        UISegmentedControl.appearance().selectedSegmentTintColor = .accent
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        
        self.passed_product = product
        self.barcode = nil
        self.increaseScans = increaseScans
    }
    
    init(barcode: String? = nil, increaseScans: Bool = false) {
        UISegmentedControl.appearance().selectedSegmentTintColor = .accent
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        
        self.passed_product = nil
        self.barcode = barcode
        self.increaseScans = increaseScans
    }
    
    var body: some View {
        @Bindable var dVM = vm
        ScrollView(showsIndicators: false) {
            VStack {
                header()
                
                nutritionalFacts()
                
                Label("All data shown is taken from the vm.product label. We rely on what’s printed by the manufacturer.", systemImage: "i.circle")
                    .font(.caption)
                    .foregroundStyle(.colorTextTertiary)
                    .padding(.top)
            }
        }.background(.colorBackground)
            .navigationTitle(vm.product.name ?? "")
            .navigationBarTitleDisplayMode(.large)
            .foregroundStyle(.colorTextPrimary)
            .groupBoxStyle(.customStyle)
            .ignoresSafeArea(edges: [.bottom])
            .toolbar {
                if vm.isLoading {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                }
            }.alert(vm.alertTitle, isPresented: $dVM.showErrorAlert) {
                if vm.alertTitle == "Product not found in database." {
                    Button("Ok", role: .cancel) {
                        if !gvm.path.isEmpty {
                            gvm.path.removeLast()
                        } else {
                            dismiss()
                        }
                    }
                } else {
                    Button("Ok", role: .cancel) { }
                }
                
            }.onChange(of: vm.showErrorAlert) {
                gvm.shouldHideCamera = vm.showErrorAlert
            }
            .animation(.easeInOut, value: barcode != nil ? vm.product : Constants.sampleProduct)
            .contentTransition(.numericText())
            .onAppear {
                if increaseScans && Calendar.current.isDateInToday(lastScannedDate) {
                          todayScannedCount += 1
                }
                
                guard let barcode = barcode else {
                    vm.product = passed_product!
                    return
                }

                vm.handleFetchingProduct(from: barcode)
            }
    }
    
    @ViewBuilder
    func header() -> some View {        
        Group {
            HStack {
                Label("Calories:", systemImage: "flame.fill")
                    .foregroundStyle(.colorTextTertiary)
                    .fontWeight(.medium)
                
                Text("\(vm.product.caloriesPer100g == nil ? "-" : String(vm.product.caloriesPer100g!)) kcal")
                    .foregroundStyle(.colorTextTertiary)
            }.padding(.leading)
                .padding(.leading)
            
            HStack {
                Label("Serving:", systemImage: "scalemass.fill")
                    .foregroundStyle(.colorTextTertiary)
                    .fontWeight(.medium)
                
                Text("\(vm.product.weight == nil ? "-" : String(vm.product.weight!)) kcal")
                    .foregroundStyle(.colorTextTertiary)
            }.padding(.leading)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if let ingredients = vm.product.ingredients {
                        ForEach(Array(ingredients.enumerated()), id: \.offset) { pos, ingredient in
                            Text(ingredient)
                                .padding(4)
                                .background(.white)
                                .clipShape(.rect(cornerRadius: 4))
                                .shadow(radius: 0.5, x: 0.5, y: 0.5)
                                .foregroundStyle(.colorTextTertiary)
                                .padding(.bottom, 1)
                                .padding(.leading, pos == 0 ? 32 : 0)
                        }
                    }
                }
            }
            
            Label("Nutritional Facts are shown per serving", systemImage: "i.circle")
                .font(.caption)
                .foregroundStyle(.colorTextTertiary)
                .padding(.leading)
                .padding(.top, 8)
                .padding(.bottom, 25)
                .padding(.leading)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func nutritionalFacts() -> some View {
        HStack {
            Text("Nutritional Facts")
                .foregroundStyle(.accent)
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            if vm.isLoading {
                ProgressView()
            }
        }.padding(.bottom, -2)
            .padding(.horizontal)
        
        Rectangle()
            .fill(.accent)
            .frame(height: 2.5)
        
        nutritionalFactItem("Protein", value: vm.product.protein)
        nutritionalFactItem("Sodium", value: vm.product.sodium)
        nutritionalFactItem("Sugars", value: vm.product.sugars)
        nutritionalFactItem("Fiber", value: vm.product.fiber)
        nutritionalFactItem("Fat", value: vm.product.fat)
        nutritionalFactItem("Carbohydrates", value: vm.product.carbohydrates)
    }
    
    @ViewBuilder
    func nutritionalFactItem(_ title: String, value: Double?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.colorTextTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                        
            Text(value == nil ? "-" : String(format: "%.1fg", value!))
                .frame(maxWidth: .infinity, alignment: .leading)

        }.padding(.horizontal)
    }
}

#Preview {
    ProductDetailsView(barcode: "90424014")
        .environment(GeneralVM())
}

extension GroupBoxStyle where Self == CustomGroupBoxStyle {
    static var customStyle: CustomGroupBoxStyle { .init() }
}

struct CustomGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.content
                .foregroundStyle(.colorTextTertiary)
        }.padding(12)
            .background(.white)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(radius: 2, x: 1, y: 1)
            .padding(.horizontal, 2)
    }
}
