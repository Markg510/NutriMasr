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
    
    @State private var showFactsPer: CustomSegmentedPickerOptions = .serving
    
    @State private var vm = ProductDetailsVM()
    
    var passed_product: Product = Constants.emptyProduct
    var barcode: String? = nil
        
    init(product: Product, barcode: String? = nil) {
        UISegmentedControl.appearance().selectedSegmentTintColor = .accent
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        
        self.passed_product = product
        self.barcode = barcode
    }
    
    init(barcode: String? = nil) {
        UISegmentedControl.appearance().selectedSegmentTintColor = .accent
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        
        self.passed_product = Constants.emptyProduct
        self.barcode = barcode
    }
    
    var body: some View {
        @Bindable var dVM = vm
        ScrollView(showsIndicators: false) {
            VStack {
                Picker("Serving Of", selection: $showFactsPer) {
                    Text("Serving").tag(CustomSegmentedPickerOptions.serving)
                    Text("100g").tag(passed_product.category == .drinks ? CustomSegmentedPickerOptions.hundredMills : CustomSegmentedPickerOptions.hundredGrams)
                }.pickerStyle(.segmented)
                    .padding(.bottom)
                
                header()
                
                Divider()
                
                proteinAndNutrients()
                
                ingredients()
                
                Label("All data shown is taken from the vm.product label. We rely on what’s printed by the manufacturer.", systemImage: "i.circle")
                    .font(.caption)
                    .foregroundStyle(.colorTextTertiary)
                
                Text(vm.alertTitle)
            }
        }.padding()
            .background(.colorBackground)
            .navigationTitle(passed_product.name ?? "")
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
            }.animation(.easeInOut, value: showFactsPer)
            .animation(.easeInOut, value: vm.product)
            .contentTransition(.numericText())
            .onAppear {
                vm.product = passed_product
                
                guard let barcode = barcode else { return }
                vm.handleFetchingProduct(from: barcode, overriding: $dVM.product)
            }
    }
    
    @ViewBuilder
    func header() -> some View {
        @Bindable var dVM = vm
        HStack {
            Text("Calories")
                .font(.title3)
                .fontWeight(.medium)
            
            Spacer()
            
            let sodium = vm.calculateCalories(vm.product.caloriesPer100g, servingWeight: vm.product.weight, isPerServing: showFactsPer)
            Text(String(format: "%.1f kcal", sodium))
        }
        
        HStack {
            Text("Net \(vm.product.category == .drinks ? "Liters" : "Weight")")
                .font(.callout)
                .foregroundStyle(.colorTextTertiary)
            
            Spacer()
            
            Text(String(format: "%.1fg", vm.product.weight ?? 0))
                .foregroundStyle(.colorTextTertiary)
        }
    }
    
    @ViewBuilder
    func proteinAndNutrients() -> some View {
        Label("Proteins & Nutrients", systemImage: "i.circle")
            .font(.title2)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        GroupBox {
            let protein = vm.calculateCalories(vm.product.protein, servingWeight: vm.product.weight, isPerServing: showFactsPer)
            HStack {
                Text("• Protein")
                Spacer()
                Text(String(format: "%.1fg", protein))
            }

            let sodium = vm.calculateCalories(vm.product.sodium, servingWeight: vm.product.weight, isPerServing: showFactsPer)
            HStack {
                Text("• Sodium")
                Spacer()
                Text(String(format: "%.1fg", sodium))
            }

            let sugars = vm.calculateCalories(vm.product.sugars, servingWeight: vm.product.weight, isPerServing: showFactsPer)
            HStack {
                Text("• Sugars")
                Spacer()
                Text(String(format: "%.1fg", sugars))
            }

            let fiber = vm.calculateCalories(vm.product.fiber, servingWeight: vm.product.weight, isPerServing: showFactsPer)
            HStack {
                Text("• Fiber")
                Spacer()
                Text(String(format: "%.1fg", fiber))
            }

            let fat = vm.calculateCalories(vm.product.fat, servingWeight: vm.product.weight, isPerServing: showFactsPer)
            HStack {
                Text("• Fat")
                Spacer()
                Text(String(format: "%.1fg", fat))
            }

            let carbohydrates = vm.calculateCalories(vm.product.carbohydrates, servingWeight: vm.product.weight, isPerServing: showFactsPer)
            HStack {
                Text("• Carbohydrates")
                Spacer()
                Text(String(format: "%.1fg", carbohydrates))
            }
        }
    }
    
    @ViewBuilder
    func ingredients() -> some View {
        Label("Ingredients", systemImage: "list.bullet.clipboard")
            .font(.title2)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        GroupBox {
            VStack(alignment: .leading) {
                if let ingredients = vm.product.ingredients {
                    ForEach(ingredients, id:\.self) { ingredient in
                        Text("• \(ingredient)")
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ProductDetailsView(product: Constants.sampleProduct)
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
