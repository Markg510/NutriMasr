//
//  CategoryView.swift
//  NutriMasr
//
//  Created by Mark George on 20/06/2025.
//

import SwiftUI

struct CategoryView: View {
    // Passed Variables
    @Environment(GeneralVM.self) var gvm
    var category: Categories = .drinks
    
    // View Properties
    @State var currentProduct: Product? = nil
    @State var absoluteNot = false
    
    var vm = CategoryVM() // View Model
    
    var body: some View {
        @Bindable var dVM = vm
        ScrollView {
            VStack {
                if vm.isLoading && vm.products.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                        ForEach(0...5, id:\.self) { item in
                            loadingItem()
                        }
                    }
                } else if vm.products.isEmpty && !vm.isLoading {
                    ContentUnavailableView {
                        Label("No Products Yet", systemImage: "cart.badge.questionmark")
                    } description: {
                        Text("Looks like there are no items in the \(category) category right now.")
                    } actions: {
                        Button("Add Product") {
                            gvm.path.append("AddProduct")
                        }.buttonStyle(.borderedProminent)
                    }.padding()
                } else {
                    Text("\(vm.products.count) items found")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.colorTextTertiary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                        ForEach(vm.products) { product in
                            Button {
                                currentProduct = product
                            } label: {
                                categoryItem(product: product)
                            }.buttonStyle(.plain)
                        }
                    }
                }

            }.padding()
        }.background(.colorBackground)
            .navigationTitle(String(describing: category).capitalized)
            .sheet(item: $currentProduct) { product in
                ProductDetailsView(product: product)
            }.onAppear {
                vm.handleFetchingCategories(category)
            }.alert(vm.alertTitle, isPresented: $dVM.showErrorAlert) {
                Button("Ok", role: .cancel) { }
            }
    }
    
    @ViewBuilder
    func categoryItem(product: Product) -> some View {
        VStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.colorPrimary)
                .frame(width: 167, height: 167)
                .shadow(radius: 1, x: 1, y: 1)
                .overlay {
                    CustomImage(url: product.getImgURL())
                        .padding(6)
                }.padding(.bottom, 5)
            
            Text(product.name ?? "")
        }
    }
    
    @ViewBuilder
    func loadingItem() -> some View {
        VStack(alignment: .center) {
            LoadingView(.rect(cornerRadius: 16))
                .frame(width: 167, height: 167)
                .shadow(radius: 1, x: 1, y: 1)
                .padding(.bottom, 5)
            
            LoadingView(.rect(cornerRadius: 16))
                .frame(width: 140, height: 12)
                .padding(.horizontal)
                .shadow(radius: 1, x: 1, y: 1)
                .padding(.bottom, 7)
        }
    }
}

#Preview {
    CategoryView()
        .environment(GeneralVM())
}
