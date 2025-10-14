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
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List(selection: $selectedAccountId) {
            ForEach(dataManager.filteredAccounts) { account in
                AccountRowView(account: account)
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
            .onMove(perform: editMode == .active ? dataManager.moveAccounts : nil)
        }
        .listStyle(.sidebar)
        .navigationTitle("Accounts")
        .navigationSubtitle("\(dataManager.accounts.count) accounts")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleEditMode) {
                    Text(editMode == .active ? "Done" : "Edit")
                }
                .disabled(dataManager.accounts.isEmpty)
            }
        }
        .environment(\.editMode, $editMode)
        .overlay {
            if dataManager.filteredAccounts.isEmpty && !dataManager.searchText.isEmpty {
                ContentUnavailableView.search
            } else if dataManager.accounts.isEmpty {
                ContentUnavailableView(
                    "No Accounts",
                    systemImage: "lock.shield",
                    description: Text("Add your first account to get started")
                )
            }
        }
    }

    private func toggleEditMode() {
        withAnimation {
            editMode = editMode == .active ? .inactive : .active
        }
    }

    private func editAccount(_ account: Account) {
        // TODO: Implement edit functionality
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
    @EnvironmentObject var dataManager: DataManager
    @State private var currentCode = ""
    @State private var timeRemaining: TimeInterval = 0

    var body: some View {
        HStack(spacing: 12) {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(account.issuer)
                    .font(.headline)
                    .lineLimit(1)

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