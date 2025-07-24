//
//  ContentView.swift
//  NutriMasr
//
//  Created by Mark George on 19/06/2025.
//

import SwiftUI
import Network

enum Categories: String, CaseIterable, Codable, Equatable, Hashable {
    case chips, drinks, dairy, biscuits, sweets, cereals, sauces, noodles
    
    var img: ImageResource {
        return switch self {
        case .chips: .chipsNew
        case .drinks: .drinksNew
        case .dairy: .dairyNew
        case .biscuits: .biscuitsNew
        case .sweets: .sweetsNew
        case .cereals: .cerealsNew
        case .sauces: .saucesNew
        case .noodles: .noodlesNew
        }
    }
    
    init(from decoder: Decoder) throws {
         let container = try decoder.singleValueContainer()
         let rawValue = try container.decode(String.self).lowercased()

         switch rawValue {
         case "chips": self = .chips
         case "drinks": self = .drinks
         case "dairy": self = .dairy
         case "biscuits": self = .biscuits
         case "sweets": self = .sweets
         case "cereals": self = .cereals
         case "sauces": self = .sauces
         case "noodles": self = .noodles
         default:
             throw DecodingError.dataCorruptedError(
                 in: container,
                 debugDescription: "Invalid category: \(rawValue)"
             )
         }
     }
}

struct HomeView: View {
    @State private var currentProduct: Product? = nil
    @State private var showScannerView = false
    @State private var gvm = GeneralVM()
    
    // Scanned Items Count
    @AppStorage("todayScannedCount") private var todayScannedCount: Int = 0
    @AppStorage("lastScannedDate") private var lastScannedDate: Date = .now
    @AppStorage("username") private var username: String = ""
    
    @State private var vm = HomeVM()
    
    var body: some View {
        NavigationStack(path: $gvm.path) {
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            header()
                            
                            scanNow()
                            
                            leaderboard()
                                                
                            categories()
                            
                            Button("Add New Product") {
                                gvm.path.append("AddProduct")
                            }.foregroundStyle(.accent)
                                .padding(.top)
                            
                            Spacer()
                            
                        }.padding()
                            .foregroundStyle(.colorTextPrimary)
                            .blur(radius: vm.showUserNameOverlay ? 3 : 0)
                            .disabled(vm.showUserNameOverlay)
                    }
                    
                    if vm.showUserNameOverlay {
                        userNameOverlay()
                            .zIndex(100)
                    }
                }.background(.colorBackground)
                .sheet(item: $currentProduct) { product in
                    ProductDetailsView(product: product)
                        .environment(gvm)
                }.sheet(isPresented: $showScannerView) {
                    ScannerView(scannedCodeOption: .scanned, passed_barcode_value: .constant(""))
                        .environment(gvm)
                }.navigationDestination(for: String.self) { str in
                    if str == "AddProduct" {
                        AddProductView()
                            .environment(gvm)
                    } else {
                        ProductDetailsView(barcode: str)
                    }
                }.navigationDestination(for: Categories.self) { category in
                    CategoryView(category: category)
                        .environment(gvm)
                }.onAppear {
                    vm.showUserNameOverlay = username.isEmpty
                    
                    vm.handleFetchingMostScannedProducts()
                    if !Calendar.current.isDateInToday(lastScannedDate) {
                        todayScannedCount = 0
                        lastScannedDate = .now
                    }
                }.navigationDestination(for: Product.self) { product in
                    ProductDetailsView(product: product)
                        .environment(gvm)
                }
        }
    }
    
    // MARK: -- VIEWS
    @ViewBuilder
    func header() -> some View {
        HStack {
            Text("Welcome")
                .appTitle()
            
            Spacer()
            
            Text(username)
        }.contentShape(.rect)
            .onTapGesture {
            withAnimation {
                vm.showUserNameOverlay = true
            }
        }.padding(.bottom)
    }
    
    @ViewBuilder
    func scanNow() -> some View {
        VStack {
            Text(todayScannedCount == 0 ? "You haven't scanned any items today" : "You've Scanned \(todayScannedCount) items today!")
                .font(.title3)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("Track your nutrition goals easily")
                .font(.footnote)
                .foregroundStyle(.colorTextTertiary)
            
            Button {
                showScannerView = true
            } label: {
                Label("Scan Now", systemImage: "barcode.viewfinder")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.accent)
                    .foregroundStyle(.colorBackground)
                    .fontWeight(.bold)
                    .clipShape(.rect(cornerRadius: 16))
            }
            
        }.padding()
            .background(.colorPrimary)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(radius: 2, x: 1, y: 1)
            .padding(.bottom)
    }
    
    @ViewBuilder
    func leaderboard() -> some View {
        if !vm.mostScannedProducts.isEmpty {
            Text("Most Scanned")
                .appTitle()
            
            GroupBox {
                VStack {
                    let maxScanCount = vm.mostScannedProducts.max(by: {
                        ($0.scans ?? 0) < ($1.scans ?? 0)
                    })?.scans ?? 0
                    
                    ForEach(vm.mostScannedProducts) { product in
                        Button { gvm.path.append(product) } label: {
                            HStack {
                                CustomImage(url: product.getImgURL())
                                    .frame(width: 45, height: 65)
                                    .padding(10)
                                    .background(.colorBackground)
                                    .clipShape(.circle)
                                    .shadow(radius: 1, x: 1, y: 1)
                                    
                                ProgressView(value: Double(product.scans ?? 0), total: Double(maxScanCount))
                                    .scaleEffect(x: 1, y: 3, anchor: .center)
                                
                                Text("\(product.scans ?? 0) \(product.scans == 1 ? "scan" : "scans")")
                                    .font(.caption)
                                    .foregroundStyle(.colorTextTertiary)
                            }
                        }
                        
                    }
                }
            }.groupBoxStyle(.customStyle)
                .padding(.bottom)
        }
    }
    
    @ViewBuilder
    func categories() -> some View {
        Text("Categories")
            .appTitle()
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
            ForEach(Categories.allCases, id: \.self) { category in
                Button {
                    gvm.path.append(category)
                } label: {
                    categoryItem(img: category.img, title: String(describing: category).capitalized)
                }
            }
        }
    }
    
    @ViewBuilder
    func categoryItem(img: ImageResource, title: String) -> some View {
        VStack(spacing: 6) {
            Image(img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .padding(4)
                .background(.colorPrimary)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(radius: 2, x: 1, y: 1)
            
            Text(title)
        }
    }
    
    @ViewBuilder
    func userNameOverlay() ->  some View {
        GroupBox {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.colorTextPrimary)
                .padding()
            
            Text("Enter Your Name")
                .appTitle(withSpacing: true)
            
            TextField("John Doe", text: $username)
                .padding(12)
                .background(.colorBackground)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(radius: 1, x: 1, y: 1)
                .padding(.bottom)
            
            Button {
                withAnimation {
                    vm.showUserNameOverlay = false
                }
            } label: {
                Text("Save")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.accent)
                    .foregroundStyle(.colorBackground)
                    .fontWeight(.bold)
                    .clipShape(.rect(cornerRadius: 16))
            }
        }.padding(.horizontal)
            .groupBoxStyle(.customStyle)
            .transition(.move(edge: .bottom))
    }
}

#Preview {
    HomeView()
}

// MARK: -- EXTENSIONS

extension Text {
    /// Styles the text as an app title.
    ///
    /// - Parameter withSpacing: aligns title to leading if set to true
    /// - Returns:an app themed text title
    @ViewBuilder
    public func appTitle(withSpacing: Bool = false) -> some View {
        if withSpacing {
            self
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.colorTextPrimary)
        } else {
            self
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.colorTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle {
        TrailingIconLabelStyle()
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.title
            
            configuration.icon
        }
    }
}
