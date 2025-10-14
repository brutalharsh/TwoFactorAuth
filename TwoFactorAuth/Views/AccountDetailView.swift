//
//  AccountDetailView.swift
//  TwoFactorAuth
//
//  Detailed view for a selected account
//

import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @EnvironmentObject var dataManager: DataManager
    @State private var currentCode = ""
    @State private var timeRemaining: TimeInterval = 0
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var copiedToClipboard = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 20) {
                // Account icon
                ZStack {
                    Circle()
                        .fill(account.iconColor.gradient)
                        .frame(width: 80, height: 80)

                    Text(account.issuer.prefix(2).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                // Account name
                VStack(spacing: 8) {
                    Text(account.issuer)
                        .font(.title)
                        .fontWeight(.semibold)

                    if !account.accountName.isEmpty {
                        Text(account.accountName)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 40)

            // Code display
            VStack(spacing: 20) {
                // Large code display
                HStack(spacing: 4) {
                    ForEach(Array(currentCode.enumerated()), id: \.offset) { index, char in
                        Text(String(char))
                            .font(.system(size: 48, weight: .medium, design: .monospaced))
                            .frame(width: 50, height: 70)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)

                        if index == 2 && currentCode.count == 6 {
                            Text("•")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)

                // Progress and time remaining
                VStack(spacing: 12) {
                    ProgressView(value: account.progress)
                        .tint(progressColor)
                        .frame(width: 300)

                    Text("\(Int(timeRemaining)) seconds remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Action buttons
                HStack(spacing: 20) {
                    Button(action: copyCode) {
                        Label(copiedToClipboard ? "Copied!" : "Copy Code",
                              systemImage: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.clipboard")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(40)

            Spacer()

            // Account details
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Algorithm", value: account.algorithm.rawValue)
                    DetailRow(label: "Digits", value: "\(account.digits)")
                    DetailRow(label: "Period", value: "\(account.period) seconds")
                    DetailRow(label: "Created", value: account.createdAt.formatted(date: .abbreviated, time: .shortened))
                    if let lastUsed = account.lastUsed {
                        DetailRow(label: "Last Used", value: lastUsed.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .padding(8)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { startTimer() }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            updateCode()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditAccountView(account: account)
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete \"\(account.displayName)\"? This action cannot be undone.")
        }
    }

    private var progressColor: Color {
        if timeRemaining < 5 {
            return .red
        } else if timeRemaining < 10 {
            return .orange
        } else {
            return .accentColor
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
        withAnimation(.easeInOut(duration: 0.3)) {
            copiedToClipboard = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }

    private func deleteAccount() {
        dataManager.deleteAccount(account)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()
        }
    }
}