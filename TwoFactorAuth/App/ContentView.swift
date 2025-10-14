//
//  ContentView.swift
//  TwoFactorAuth
//
//  Main content view for the app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedAccountId: UUID?
    @State private var showingAddAccount = false
    @State private var showingScanner = false
    @State private var showingImportExport = false
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar with account list
            AccountListView(selectedAccountId: $selectedAccountId)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // Detail view
            if let account = dataManager.accounts.first(where: { $0.id == selectedAccountId }) {
                AccountDetailView(account: account)
            } else {
                EmptyStateView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingScanner = true }) {
                    Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                }
                .help("Scan QR code to add account")

                Button(action: { showingAddAccount = true }) {
                    Label("Add Account", systemImage: "plus")
                }
                .help("Manually add account")

                Menu {
                    Button(action: { showingImportExport = true }) {
                        Label("Import/Export", systemImage: "square.and.arrow.down")
                    }

                    Divider()

                    Button(action: { dataManager.loadDemoAccounts() }) {
                        Label("Load Demo Accounts", systemImage: "wand.and.stars")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .searchable(text: $dataManager.searchText, placement: .sidebar)
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView()
        }
        .sheet(isPresented: $showingScanner) {
            QRScannerView()
        }
        .sheet(isPresented: $showingImportExport) {
            ImportExportView()
        }
        .onAppear {
            setupNotifications()
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .addNewAccount,
            object: nil,
            queue: .main
        ) { _ in
            showingAddAccount = true
        }
    }
}

// Empty state view when no account is selected
struct EmptyStateView: View {
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("Two-Factor Authenticator")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select an account from the sidebar to view its code")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if dataManager.accounts.isEmpty {
                VStack(spacing: 15) {
                    Text("No accounts yet")
                        .font(.headline)
                        .padding(.top)

                    HStack(spacing: 20) {
                        Button(action: { dataManager.isScanning = true }) {
                            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: { dataManager.isAddingAccount = true }) {
                            Label("Add Manually", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}