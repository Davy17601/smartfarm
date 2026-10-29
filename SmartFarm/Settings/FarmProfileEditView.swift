import SwiftUI

struct FarmProfileEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("farmName") private var farmName = "SmartFarm"
    @AppStorage("farmVillage") private var farmVillage = "ភូមិ"
    @AppStorage("farmProvince") private var farmProvince = "ខេត្ត"

    @State private var editedFarmName: String = ""
    @State private var editedVillage: String = ""
    @State private var editedProvince: String = ""

    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let secondaryText = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let brandGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let darkGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                customHeader

                VStack(spacing: 24) {
                    // Farm name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("settings.farmName"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(secondaryText)
                            .padding(.horizontal, 4)

                        TextField(L("settings.farmName"), text: $editedFarmName)
                            .font(.system(size: 16))
                            .foregroundColor(primaryText)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }

                    // Village field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("settings.village"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(secondaryText)
                            .padding(.horizontal, 4)

                        TextField(L("settings.village"), text: $editedVillage)
                            .font(.system(size: 16))
                            .foregroundColor(primaryText)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }

                    // Province field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("settings.province"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(secondaryText)
                            .padding(.horizontal, 4)

                        TextField(L("settings.province"), text: $editedProvince)
                            .font(.system(size: 16))
                            .foregroundColor(primaryText)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }

                    // Save button
                    Button(action: saveProfile) {
                        Text(L("common.save"))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(darkGreen)
                            .cornerRadius(12)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            editedFarmName = farmName
            editedVillage = farmVillage
            editedProvince = farmProvince
        }
    }

    private var customHeader: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(brandGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            // Title
            Text(L("settings.editProfile"))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(primaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private func saveProfile() {
        farmName = editedFarmName
        farmVillage = editedVillage
        farmProvince = editedProvince
        presentationMode.wrappedValue.dismiss()
    }
}
