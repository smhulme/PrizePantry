//
//  LoginView.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/31/25.
//


//
//  LoginView.swift
//  prizepantry
//
//  Created for PrizePantry Secure Auth.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var currentNonce: String?
    @State private var errorMessage: String = ""

    var body: some View {
        VStack {
            Image(systemName: "trophy.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundStyle(.yellow)
                .padding(.bottom, 40)
            
            Text("Prize Pantry")
                .font(.largeTitle)
                .bold()
            
            Text("Manage tokens and prizes for your family.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 60)

            SignInWithAppleButton(
                onRequest: { request in
                    let nonce = CryptoUtils.randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = CryptoUtils.sha256(nonce)
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            guard let nonce = currentNonce else {
                                fatalError("Invalid state: A login callback was received, but no login request was sent.")
                            }
                            
                            guard let appleIDToken = appleIDCredential.identityToken else {
                                print("Unable to fetch identity token")
                                return
                            }
                            
                            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                                return
                            }

                            // ✅ NEW CODE
                            // 1. We also grab the authorization code (recommended for new SDKs)
                            guard let authCodeData = appleIDCredential.authorizationCode,
                                  let authCodeString = String(data: authCodeData, encoding: .utf8) else {
                                print("Unable to fetch authorization code")
                                return
                            }

                            // 2. Use 'providerID: .apple' instead of 'withProviderID: "apple.com"'
                            //    and pass the 'accessToken' (which is the authCodeString)
                            let credential = OAuthProvider.credential(providerID: .apple,
                                                                      idToken: idTokenString,
                                                                      rawNonce: nonce,
                                                                      accessToken: authCodeString)
                            
                            Auth.auth().signIn(with: credential) { (authResult, error) in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    print("Error signing in: \(error.localizedDescription)")
                                    return
                                }
                                // Success!
                                self.isLoggedIn = true
                            }
                        }
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding()
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .padding()
    }
}
