//
//  AccountListView.swift
//  TwoFactorAuth
//
//  Sidebar list view showing all accounts
//

import SwiftUI

struct AccountListView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedAccountId: UUID?
    @State private var selectedAccountIds: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    @State private var accountToEdit: Account?
    @State private var showingEditSheet = false
    @State private var isSelecting = false  // Track selection mode

    var body: some View {
        VStack(spacing: 0) {
            // Selection mode toolbar
            if isSelecting {
                HStack {
                    Button("Cancel") {
                        isSelecting = false
                        selectedAccountIds.removeAll()
                    }
                    .buttonStyle(.bordered)

                    Button(selectedAccountIds.count == dataManager.filteredAccounts.count ? "Deselect All" : "Select All") {
                        if selectedAccountIds.count == dataManager.filteredAccounts.count {
                            selectedAccountIds.removeAll()
                        } else {
                            selectedAccountIds = Set(dataManager.filteredAccounts.map { $0.id })
                        }
                    }
                    .buttonStyle(.bordered)

                    if !selectedAccountIds.isEmpty {
                        Text("\(selectedAccountIds.count) of \(dataManager.filteredAccounts.count) selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }

                    Spacer()

                    if !selectedAccountIds.isEmpty {
                        Button("Delete \(selectedAccountIds.count) Account\(selectedAccountIds.count == 1 ? "" : "s")") {
                            showingDeleteConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()
            }

            List(selection: $selectedAccountId) {
                ForEach(dataManager.filteredAccounts) { account in
                    AccountRowView(
                        account: account,
                        isSelected: selectedAccountIds.contains(account.id),
                        isSelecting: isSelecting,
                        onToggleSelection: {
                            if selectedAccountIds.contains(account.id) {
                                selectedAccountIds.remove(account.id)
                            } else {
                                selectedAccountIds.insert(account.id)
                            }
                        }
                    )
                    .tag(account.id)
                    .contextMenu {
                        Button(action: { dataManager.copyCode(for: account) }) {
                            Label("Copy Code", systemImage: "doc.on.clipboard")
                        }

                        Button(action: { editAccount(account) }) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive, action: { deleteAccount(account) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: dataManager.deleteAccounts)
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Accounts")
        .navigationSubtitle("\(dataManager.accounts.count) accounts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !dataManager.filteredAccounts.isEmpty {
                    Button(isSelecting ? "Done" : "Select") {
                        isSelecting.toggle()
                        if !isSelecting {
                            selectedAccountIds.removeAll()
                        }
                    }
                }
            }
        }
        .overlay {
            if dataManager.filteredAccounts.isEmpty && !dataManager.searchText.isEmpty {
                // Custom search empty view for macOS compatibility
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Results")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dataManager.accounts.isEmpty {
                // Custom empty state view for macOS compatibility
                VStack(spacing: 10) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Accounts")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Add your first account to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Delete Accounts", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedAccounts()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedAccountIds.count) account\(selectedAccountIds.count == 1 ? "" : "s")? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            if let account = accountToEdit {
                EditAccountView(account: account)
            }
        }
    }

    private func deleteSelectedAccounts() {
        for accountId in selectedAccountIds {
            if let account = dataManager.accounts.first(where: { $0.id == accountId }) {
                dataManager.deleteAccount(account)
            }
        }
        selectedAccountIds.removeAll()
    }

    private func editAccount(_ account: Account) {
        accountToEdit = account
        showingEditSheet = true
    }

    private func deleteAccount(_ account: Account) {
        withAnimation {
            dataManager.deleteAccount(account)
            if selectedAccountId == account.id {
                selectedAccountId = nil
            }
        }
    }
}

// Individual row view for each account
struct AccountRowView: View {
    let account: Account
    let isSelected: Bool
    let isSelecting: Bool
    let onToggleSelection: () -> Void
    @EnvironmentObject var dataManager: DataManager
    @State private var currentCode = ""
    @State private var timeRemaining: TimeInterval = 0

    var body: some View {
        HStack(spacing: 12) {
            // Only show checkbox when in selection mode
            if isSelecting {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            // Account icon
            ZStack {
                Circle()
                    .fill(account.iconColor.gradient)
                    .frame(width: 40, height: 40)

                Text(account.issuer.prefix(1).uppercased())
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            // Account info and code
            VStack(alignment: .leading, spacing: 2) {
                // Service/Issuer on first line
                Text(account.issuer)
                    .font(.headline)
                    .lineLimit(1)

                // Account name on second line (if exists)
                if !account.accountName.isEmpty {
                    Text(account.accountName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(currentCode)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if timeRemaining > 0 {
                        // Time remaining indicator
                        ProgressView(value: account.progress)
                            .progressViewStyle(CircularProgressViewStyle(size: 16))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            // Copy button
            Button(action: { copyCode() }) {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Copy code to clipboard")
        }
        .padding(.vertical, 4)
        .onAppear { startTimer() }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            updateCode()
        }
    }

    private func startTimer() {
        updateCode()
    }

    private func updateCode() {
        currentCode = account.generateCode()
        timeRemaining = account.timeRemaining
    }

    private func copyCode() {
        dataManager.copyCode(for: account)
    }
}

// Custom circular progress view
struct CircularProgressViewStyle: ProgressViewStyle {
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)

            Circle()
                .trim(from: 0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: configuration.fractionCompleted)
        }
        .frame(width: size, height: size)
    }
}