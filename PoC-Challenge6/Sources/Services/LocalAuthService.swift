import LocalAuthentication

/// Face ID (biometria). Devolve false se o aparelho não puder usar biometria
/// (no STEMP original, esse caso deixava o fluxo travado em silêncio).
enum LocalAuthService {
    static func authorize(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                    localizedReason: reason)
        } catch {
            return false
        }
    }
}
