//
//  ARFurniturePlacementView.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import SwiftUI
import ARKit
import RealityKit
import QuickLook

// MARK: - Furniture Item Model
struct FurnitureItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let category: FurnitureCategory
    let modelName: String? // For 3D models
    let defaultSize: SIMD3<Float>

    enum FurnitureCategory: String, CaseIterable {
        case seating = "Seating"
        case tables = "Tables"
        case storage = "Storage"
        case decor = "Decor"
        case appliances = "Appliances"

        var icon: String {
            switch self {
            case .seating: return "chair"
            case .tables: return "table.furniture"
            case .storage: return "archivebox"
            case .decor: return "photo.artframe"
            case .appliances: return "tv"
            }
        }
    }
}

// MARK: - AR Furniture Placement View
struct ARFurniturePlacementView: View {
    @Environment(\.dismiss) private var dismiss

    let roomModelURL: URL?

    @State private var selectedCategory: FurnitureItem.FurnitureCategory = .seating
    @State private var selectedFurniture: FurnitureItem?
    @State private var placedItems: [PlacedFurniture] = []
    @State private var showingFurniturePicker = true
    @State private var alertItem: AlertItem?

    // Sample furniture items
    let furnitureItems: [FurnitureItem] = [
        // Seating
        FurnitureItem(name: "Chair", icon: "chair", category: .seating, modelName: nil, defaultSize: SIMD3(0.5, 0.9, 0.5)),
        FurnitureItem(name: "Sofa", icon: "sofa", category: .seating, modelName: nil, defaultSize: SIMD3(2.0, 0.8, 0.9)),
        FurnitureItem(name: "Armchair", icon: "chair.lounge", category: .seating, modelName: nil, defaultSize: SIMD3(0.8, 0.9, 0.8)),

        // Tables
        FurnitureItem(name: "Dining Table", icon: "table.furniture", category: .tables, modelName: nil, defaultSize: SIMD3(1.5, 0.75, 0.9)),
        FurnitureItem(name: "Coffee Table", icon: "rectangle", category: .tables, modelName: nil, defaultSize: SIMD3(1.0, 0.4, 0.6)),
        FurnitureItem(name: "Desk", icon: "menubar.dock.rectangle", category: .tables, modelName: nil, defaultSize: SIMD3(1.2, 0.75, 0.6)),

        // Storage
        FurnitureItem(name: "Bookshelf", icon: "books.vertical", category: .storage, modelName: nil, defaultSize: SIMD3(0.8, 1.8, 0.3)),
        FurnitureItem(name: "Cabinet", icon: "archivebox", category: .storage, modelName: nil, defaultSize: SIMD3(1.0, 1.2, 0.5)),
        FurnitureItem(name: "Wardrobe", icon: "door.sliding.left.hand.closed", category: .storage, modelName: nil, defaultSize: SIMD3(1.5, 2.0, 0.6)),

        // Decor
        FurnitureItem(name: "Plant", icon: "leaf", category: .decor, modelName: nil, defaultSize: SIMD3(0.3, 0.8, 0.3)),
        FurnitureItem(name: "Lamp", icon: "lamp.desk", category: .decor, modelName: nil, defaultSize: SIMD3(0.3, 0.5, 0.3)),
        FurnitureItem(name: "Rug", icon: "rectangle.portrait", category: .decor, modelName: nil, defaultSize: SIMD3(2.0, 0.01, 1.5)),

        // Appliances
        FurnitureItem(name: "TV", icon: "tv", category: .appliances, modelName: nil, defaultSize: SIMD3(1.2, 0.7, 0.1)),
        FurnitureItem(name: "Refrigerator", icon: "refrigerator", category: .appliances, modelName: nil, defaultSize: SIMD3(0.7, 1.8, 0.7)),
    ]

    var filteredItems: [FurnitureItem] {
        furnitureItems.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // AR View placeholder
                if let url = roomModelURL {
                    ARQuickLookView(url: url)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    placeholderView
                }

                // Furniture picker overlay
                VStack {
                    Spacer()

                    if showingFurniturePicker {
                        furniturePickerView
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationTitle("Place Furniture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showingFurniturePicker.toggle()
                        }
                    } label: {
                        Image(systemName: showingFurniturePicker ? "chevron.down" : "chevron.up")
                    }
                }
            }
            .errorAlert(alertItem: $alertItem)
        }
    }

    // MARK: - Placeholder View
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arkit")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("AR Furniture Placement")
                .font(.title2.bold())

            Text("Load a room scan to place furniture in AR")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if roomModelURL == nil {
                Text("No room model available")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    // MARK: - Furniture Picker
    private var furniturePickerView: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FurnitureItem.FurnitureCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGray6))

            Divider()

            // Furniture items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filteredItems) { item in
                        FurnitureItemCard(
                            item: item,
                            isSelected: selectedFurniture?.id == item.id
                        ) {
                            selectedFurniture = item
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).opacity(0.95))
        }
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: FurnitureItem.FurnitureCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Furniture Item Card
struct FurnitureItemCard: View {
    let item: FurnitureItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .frame(width: 70, height: 70)

                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .primary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )

                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placed Furniture Model
struct PlacedFurniture: Identifiable {
    let id = UUID()
    let item: FurnitureItem
    var position: SIMD3<Float>
    var rotation: Float
    var scale: Float
}

// MARK: - AR Quick Look View
struct ARQuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

// MARK: - Instructions View
struct ARInstructionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("How to Place Furniture")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(number: 1, text: "Select a furniture item from the picker")
                InstructionRow(number: 2, text: "Tap on the floor to place the item")
                InstructionRow(number: 3, text: "Drag to move, pinch to resize")
                InstructionRow(number: 4, text: "Rotate with two-finger twist")
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ARFurniturePlacementView(roomModelURL: nil)
}
