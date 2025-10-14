//
//  AddAccountView.swift
//  TwoFactorAuth
//
//  View for manually adding a new account
//

import SwiftUI

struct AddAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var issuer = ""
    @State private var accountName = ""
    @State private var secret = ""
    @State private var algorithm = Account.AlgorithmType.sha1
    @State private var digits = 6
    @State private var period = 30
    @State private var showingError = false
    @State private var errorMessage = ""

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case issuer
        case accountName
        case secret
        case period
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Account")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Form
            Form {
                Section("Account Information") {
                    TextField("Service/Issuer", text: $issuer)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .issuer)
                        .help("The service provider (e.g., GitHub, Google)")

                    TextField("Account/Email", text: $accountName)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .accountName)
                        .help("Your account name or email address")
                }

                Section("Authentication") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Secret Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $secret)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 60)
                            .focused($focusedField, equals: .secret)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .help("The secret key provided by the service (base32 encoded)")

                        Text("Enter the secret key provided by the service. It usually looks like: JBSWY3DPEHPK3PXP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Advanced Options") {
                    Picker("Algorithm", selection: $algorithm) {
                        ForEach(Account.AlgorithmType.allCases, id: \.self) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Picker("Digits", selection: $digits) {
                            Text("6").tag(6)
                            Text("8").tag(8)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)

                        Spacer()

                        Text("Period:")
                            .foregroundColor(.secondary)

                        TextField("30", value: $period, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .focused($focusedField, equals: .period)

                        Text("seconds")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            // Footer buttons
            HStack {
                Button("Paste from Clipboard") {
                    pasteFromClipboard()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Add Account") {
                    addAccount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
        .frame(width: 500, height: 500)
        .onAppear {
            // Set initial focus to the issuer field
            focusedField = .issuer
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isValid: Bool {
        !issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func pasteFromClipboard() {
        guard let pasteboardString = NSPasteboard.general.string(forType: .string) else {
            return
        }

        // Check if it's an otpauth URI
        if pasteboardString.hasPrefix("otpauth://") {
            if let account = Account.from(uri: pasteboardString) {
                issuer = account.issuer
                accountName = account.accountName
                secret = account.secret
                algorithm = account.algorithm
                digits = account.digits
                period = account.period
            } else {
                showError("Invalid OTP URI format")
            }
        } else {
            // Assume it's just a secret key
            secret = pasteboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func addAccount() {
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAccountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        // Validate the secret key
        guard TOTPGenerator.generate(secret: trimmedSecret) != nil else {
            showError("Invalid secret key. Please check and try again.")
            return
        }

        let account = Account(
            issuer: trimmedIssuer,
            accountName: trimmedAccountName,
            secret: trimmedSecret,
            algorithm: algorithm,
            digits: digits,
            period: period
        )

        dataManager.addAccount(account)
        dismiss()
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// Edit Account View (reuses AddAccountView logic)
struct EditAccountView: View {
    let account: Account
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var issuer: String
    @State private var accountName: String
    @State private var secret: String
    @State private var algorithm: Account.AlgorithmType
    @State private var digits: Int
    @State private var period: Int
    @State private var showingError = false
    @State private var errorMessage = ""

    @FocusState private var focusedField: AddAccountView.Field?

    init(account: Account) {
        self.account = account
        _issuer = State(initialValue: account.issuer)
        _accountName = State(initialValue: account.accountName)
        _secret = State(initialValue: account.secret)
        _algorithm = State(initialValue: account.algorithm)
        _digits = State(initialValue: account.digits)
        _period = State(initialValue: account.period)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Account")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Form
            Form {
                Section("Account Information") {
                    TextField("Service/Issuer", text: $issuer)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .issuer)

                    TextField("Account/Email", text: $accountName)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .accountName)
                }

                Section("Authentication") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Secret Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $secret)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 60)
                            .focused($focusedField, equals: .secret)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }

                Section("Advanced Options") {
                    Picker("Algorithm", selection: $algorithm) {
                        ForEach(Account.AlgorithmType.allCases, id: \.self) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Picker("Digits", selection: $digits) {
                            Text("6").tag(6)
                            Text("8").tag(8)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)

                        Spacer()

                        Text("Period:")
                            .foregroundColor(.secondary)

                        TextField("30", value: $period, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .focused($focusedField, equals: .period)

                        Text("seconds")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            // Footer buttons
            HStack {
                Spacer()

                Button("Save Changes") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func saveChanges() {
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        // Validate the secret key
        guard TOTPGenerator.generate(secret: trimmedSecret) != nil else {
            errorMessage = "Invalid secret key"
            showingError = true
            return
        }

        var updatedAccount = account
        updatedAccount.issuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedAccount.accountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedAccount.secret = trimmedSecret
        updatedAccount.algorithm = algorithm
        updatedAccount.digits = digits
        updatedAccount.period = period

        dataManager.updateAccount(updatedAccount)
        dismiss()
    }
}