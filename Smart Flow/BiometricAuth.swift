//
//  BiometricAuth.swift
//  Smart Flow
//
// BiometricAuth wraps Apple's LocalAuthentication API (Face ID / Touch ID).
// The face or fingerprint check happens entirely inside iOS; the app only learns "yes, it's the owner" or "no".
// Used by the login screen and by Settings > Profile & Settings (to turn it on).
// In the Simulator: Features > Face ID > Enrolled, then Features > Face ID > Matching Face when it asks.

import Foundation
import LocalAuthentication

enum BiometricAuth {
    // True when this iPhone has Face ID (or Touch ID) set up and the app is allowed to use it.
    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    // "Face ID" or "Touch ID", for labels.
    static var name: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .touchID ? "Touch ID" : "Face ID"
    }

    // Shows the Face ID prompt. Returns true only if it was the phone's owner.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
}
