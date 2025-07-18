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
            .preferredColorScheme(.light)
            .sheet(isPresented: $dVM.showScanningSheet) {
                ScannerView(scannedCodeOption: .passed, passed_barcode_value: $dVM.barcode)
            }.alert(vm.alertTitle, isPresented: $dVM.showErrorAlert) {
                if vm.alertTitle == "Barcode Can't Be Empty" {
                    Button("Scan Now") {
                        vm.showScanningSheet = true
                    }
                } else {
                    Button("Ok", role: .cancel) { }
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
    
    @ViewBuilder
    func textField(_ placeholder: String, text: Binding<String>, fieldType: ProductFields?) -> some View {
        if let fieldType, vm.causingErrorFields.contains(fieldType) {
            Text("Empty Field!")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
        }
        
        TextField(placeholder, text: text)
            .padding(12)
            .background(.white)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(radius: 1, x: 1, y: 1)
            .padding(.bottom)
            .keyboardType({
                return switch fieldType {
                case .name, .ingredient:
                    .default
                default:
                    .numbersAndPunctuation
                }
            }())
            .submitLabel(fieldType == .ingredient(index: vm.ingredientsCount - 1) ? .done : .next)
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
            .background(.white)
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
        
        textField("Molto Magnum", text: $dVM.name, fieldType: .name)
            .focused($focusField, equals: .name)
            .onSubmit { focusField = .calories }
    }
    
    @ViewBuilder
    func caloriesCategoryFields() -> some View {
        @Bindable var dVM = vm
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                title("Calories")
                
                textField("850", text: $dVM.calories, fieldType: .calories)
                    .focused($focusField, equals: .calories)
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
                
                textField("300", text: $dVM.weight, fieldType: .weight)
                    .focused($focusField, equals: .weight)
                    .onSubmit { focusField = .fat }
            }
            
            VStack(spacing: 0) {
                title("Fat")
                
                textField("6.5", text: $dVM.fat, fieldType: .fat)
                    .focused($focusField, equals: .fat)
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
                
                textField("24.0", text: $dVM.carbohydrates, fieldType: .carbohydrates)
                    .focused($focusField, equals: .carbohydrates)
                    .onSubmit { focusField = .sodium }
            }
            
            VStack(spacing: 0) {
                title("Sodium")
                
                textField("6.5", text: $dVM.sodium, fieldType: .sodium)
                    .focused($focusField, equals: .sodium)
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
                
                textField("3.73", text: $dVM.protein, fieldType: .protein)
                    .focused($focusField, equals: .protein)
                    .onSubmit { focusField = .sugars }
            }
            
            VStack(spacing: 0) {
                title("Sugars")
                
                textField("102", text: $dVM.sugars, fieldType: .sugars)
                    .focused($focusField, equals: .sugars)
                    .onSubmit { focusField = .fiber }
            }
            
            VStack(spacing: 0) {
                title("Fiber")
                
                textField("11.5", text: $dVM.fiber, fieldType: .fiber)
                    .focused($focusField, equals: .fiber)
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
            textField("Ingredient \(i)", text: $dVM.ingredients[i - 1], fieldType: .ingredient(index: i - 1))
                .focused($focusField, equals: .ingredient(index: i - 1))
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
