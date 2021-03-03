import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 5) {
                    GIFImage(image: upAnimation)
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    Text(appName)
                        .font(.custom("CircularStd-Bold", size: 34))
                    Text("Provenance is a lightweight application that interacts with the Up Banking Developer API to display information about your bank accounts, transactions, categories, tags, and more.")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)
                HStack(alignment: .center, spacing: 0) {
                    Text("Version")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(appVersion)
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.trailing)
                }
                .contextMenu {
                    if appVersion != "Unknown" {
                        Button(action: {
                            UIPasteboard.general.string = appVersion
                        }) {
                            Label("Copy", systemImage: "doc.on.clipboard")
                        }
                    }
                }
                HStack(alignment: .center, spacing: 0) {
                    Text("Build")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(appBuild)
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.trailing)
                }
                .contextMenu {
                    if appBuild != "Unknown" {
                        Button(action: {
                            UIPasteboard.general.string = appBuild
                        }) {
                            Label("Copy", systemImage: "doc.on.clipboard")
                        }
                    }
                }
            }
            Section(footer: Text(appCopyright)) {
                Link(destination: URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!) {
                    HStack(alignment: .center, spacing: 5) {
                        Image(systemName: "square.and.pencil")
                            .resizable()
                            .frame(width: 25, height: 25)
                        Text("Contact Developer")
                            .font(.custom("CircularStd-Book", size: 17))
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}
