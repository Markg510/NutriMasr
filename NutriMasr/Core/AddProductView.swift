//
//  AddProduct.swift
//  NutriMasr
//
//  Created by Mark George on 23/06/2025.
//

import SwiftUI
import PhotosUI

struct AddProductView: View {
    @Environment(\.dismiss) var dismiss
    private var vm = AddProductVM()
    
    @FocusState private var focusField: ProductFields?
    
    @Namespace private var topID
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        @Bindable var dVM = vm
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    productAddedSuccessfully()
                        .onChange(of: vm.isFinished) { oldValue, newValue in
                            if newValue {
                                withAnimation {
                                    proxy.scrollTo(topID)
                                }
                            }
                        }
                    
                    productImage()
                    
                    header()
                    
                    nameField()
                    
                    caloriesCategoryFields()
                    
                    Group {
                        weightFatFields()
                        
                        carbsSodiumFields()
                        
                        proteinSugarsFiberFields()
                        
                        ingredientFields()
                        
                        addProductButton()
                    }.zIndex(-1000)
                }.padding()
            }
        }.background(.colorBackground)
            .foregroundStyle(.colorTextPrimary)
            .sheet(isPresented: $dVM.showScanningSheet) {
                ScannerView(scannedCodeOption: .passed, passed_barcode_value: $dVM.barcode)
            }.alert(vm.alertTitle, isPresented: $dVM.showErrorAlert) {
                if vm.alertTitle == "Barcode Can't Be Empty" {
                    Button("Scan Now") {
                        vm.showScanningSheet = true
                    }
                } else {
                    if vm.showTryAgain {
                        Button("Try Again", role: .cancel) {
                            vm.handleAddingProduct()
                        }
                    }
                    
                    Button("Ok", role: vm.showTryAgain ? .destructive : .cancel) {}
                }
                
            } message: {
                Text(vm.alertMessage)
            }.scrollDismissesKeyboard(.immediately)      
    }
    
    // MARK: -- COMPONENTS
    
    func title(_ title: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.headline)
            
            Text(vm.getHint(from: title))
                .font(.caption)
                .foregroundStyle(.colorTextTertiary)
            
            Spacer()
        }.padding(.bottom, 8)
    }
    
    // MARK: -- VIEWS
    @ViewBuilder
    func productImage() -> some View {
        @Bindable var dVM = vm
        
        Group {
            if let img = vm.productImg {
                img
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 70, weight: .thin))
                    .foregroundStyle(.colorTextTertiary)
                    .padding(24)
            }
        }.frame(width: 150, height: 150)
            .background(.colorPrimary)
            .clipShape(.circle)
            .shadow(radius: 1, x: 1, y: 1)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom)
            .photosPicker(isPresented: $dVM.showPickerItem, selection: $dVM.pickerItem, photoLibrary: .shared())
            .onChange(of: vm.pickerItem) {
                Task {
                    await vm.getImageData()
                }
            }.onTapGesture {
                vm.showPickerItem = true
            }
    }
    
    @ViewBuilder
    func productAddedSuccessfully() -> some View {
        if vm.isFinished {
            VStack(alignment: .center) {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .padding(.bottom)
                    .id(topID)
                
                Text("Product Added Successfuly")
                
                Button("Clear All Fields") {
                    vm.clearAllFields()
                }.foregroundStyle(.accent)
            }.padding(.bottom)
                .foregroundStyle(.green)
        }
    }
    
    @ViewBuilder
    func header() -> some View {
        HStack {
            Label("Barcode", systemImage: "barcode")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                .onTapGesture {
                    vm.clearAllFields()
                    if let proxy = scrollProxy {
                        proxy.scrollTo(topID)
                    }
                }.onLongPressGesture {
                    vm.fillWithPepsiDietData()
                }
            
            Spacer()
            
            if vm.barcode == nil {
                Button {
                    vm.showScanningSheet = true
                } label: {
                    Text("Scan Now")
                        .foregroundStyle(.accent)
                }
            } else {
                Text(vm.barcode!)
                    .foregroundStyle(.colorTextTertiary)
                    .font(.footnote)
                
                Image(systemName: "pencil.circle")
                    .foregroundStyle(.accent)
                    .onTapGesture {
                        vm.barcode = nil
                        vm.showScanningSheet = true
                    }
            }
        }.padding(.bottom)
    }
    
    @ViewBuilder
    func nameField() -> some View {
        @Bindable var dVM = vm
        Label("Enter the Nutritional Information per 100g", systemImage: "i.circle")
            .frame(maxWidth: .infinity, alignment: .leading)
        .font(.caption)
        .foregroundStyle(.colorTextTertiary)
        .padding(.bottom)
        
        title("Product Name")
        
        AppTextField(
            placeholder: "Molto Magnum",
            fieldType: .name,
            causingErrorFields: vm.causingErrorFields,
            ingredientsCount: vm.ingredientsCount,
            text: $dVM.name
        ).focused($focusField, equals: .name)
            .onSubmit { focusField = .calories }
    }
    
    @ViewBuilder
    func caloriesCategoryFields() -> some View {
        @Bindable var dVM = vm
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                title("Calories")
                
                AppTextField(
                    placeholder: "150",
                    fieldType: .calories,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.calories
                ).focused($focusField, equals: .calories)
                    .onSubmit {
                        withAnimation(.snappy) {
                            vm.showOptions = true
                        }
                    }
            }
            
            VStack(spacing: 0) {
                title("Category")
                
                if vm.causingErrorFields.contains(.category) {
                    Text("Empty Field!")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                }
                
                CustomMenu(showOptions: $dVM.showOptions, selected: $dVM.category)
                    .zIndex(1000)
                    .onChange(of: vm.category) { oldValue, newValue in
                        if newValue != nil {
                            focusField = .weight
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    func weightFatFields() -> some View {
        @Bindable var dVM = vm
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                title(vm.category == .drinks ? "Liters" : "Weight")
                
                AppTextField(
                    placeholder: "300",
                    fieldType: .weight,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.weight
                ).focused($focusField, equals: .weight)
                    .onSubmit { focusField = .fat }
            }
            
            VStack(spacing: 0) {
                title("Fat")
                
                AppTextField(
                    placeholder: "6.5",
                    fieldType: .fat,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.fat
                ).focused($focusField, equals: .fat)
                    .onSubmit { focusField = .carbohydrates }
            }
        }
    }
    
    @ViewBuilder
    func carbsSodiumFields() -> some View {
        @Bindable var dVM = vm
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                title("Carbohydrates")
                
                AppTextField(
                    placeholder: "24.0",
                    fieldType: .carbohydrates,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.carbohydrates
                ).focused($focusField, equals: .carbohydrates)
                    .onSubmit { focusField = .sodium }
            }
            
            VStack(spacing: 0) {
                title("Sodium")
                
                AppTextField(
                    placeholder: "6.5",
                    fieldType: .sodium,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.sodium
                ).focused($focusField, equals: .sodium)
                    .onSubmit { focusField = .protein }
            }
        }
    }
    
    @ViewBuilder
    func proteinSugarsFiberFields() -> some View {
        @Bindable var dVM = vm
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                title("Protein")
                
                AppTextField(
                    placeholder: "3.73",
                    fieldType: .protein,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.protein
                ).focused($focusField, equals: .protein)
                    .onSubmit { focusField = .sugars }
            }
            
            VStack(spacing: 0) {
                title("Sugars")
                
                AppTextField(
                    placeholder: "102",
                    fieldType: .sugars,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.sugars
                ).focused($focusField, equals: .sugars)
                    .onSubmit { focusField = .fiber }
            }
            
            VStack(spacing: 0) {
                title("Fiber")
                
                AppTextField(
                    placeholder: "11.5",
                    fieldType: .fiber,
                    causingErrorFields: vm.causingErrorFields,
                    ingredientsCount: vm.ingredientsCount,
                    text: $dVM.fiber
                ).focused($focusField, equals: .fiber)
                    .onSubmit { focusField = .ingredient(index: 0) }
            }
        }
    }
    
    @ViewBuilder
    func ingredientFields() -> some View {
        @Bindable var dVM = vm
        Divider()
            .padding(.vertical)
        
        HStack {
            title("Ingredients")
            
            Spacer()
            
            Button("Add") {
                vm.ingredients.append("")
                vm.ingredientsCount += 1
            }.foregroundStyle(.accent)
                .padding(.trailing, 8)
        }.padding(.bottom, 8)
        
        if vm.causingErrorFields.contains(where: {
            guard case .ingredient = $0 else { return false }
            return true
        }) {
            // ✅ Cleanest you can get without custom helper
            Text("Empty Field!")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
        }
        
        ForEach(1...vm.ingredientsCount, id:\.self) { i in
            AppTextField(
                placeholder: "Ingredient \(i)",
                fieldType: .ingredient(index: i - 1),
                causingErrorFields: vm.causingErrorFields,
                ingredientsCount: vm.ingredientsCount,
                text: $dVM.ingredients[i - 1]
            ).focused($focusField, equals: .ingredient(index: i - 1))
                .onSubmit {
                    if i < vm.ingredientsCount {
                        focusField = .ingredient(index: i)
                    }
                }
        }
    }
    
    @ViewBuilder
    func addProductButton() -> some View {
        @Bindable var dVM = vm
        Button {
            vm.handleAddingProduct()
        } label: {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text("Add Product")
                }
            }.frame(maxWidth: .infinity)
                .padding()
                .background(.accent)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .clipShape(.rect(cornerRadius: 16))
                .overlay {
                    Color.white.opacity(vm.isLoading ? 0.25 : 0)
                }
                .shadow(radius: 1, x: 1, y: 1)
        }.padding(.top)
            .disabled(vm.isLoading)
    }
}

#Preview {
    AddProductView()
}

// MARK: -- EXTENSIONS

extension Array where Element == ProductFields {
    var containsIngredientField: Bool {
        contains {
            if case .ingredient = $0 {
                return true
            }
            return false
        }
    }
}
