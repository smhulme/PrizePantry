import SwiftUI

struct JoinFamilyView: View {
    @ObservedObject var viewModel: ChildViewModel
    @State private var codeInput = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.badge.gearshape.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Join Your Family")
                .font(.title)
                .bold()
            
            Text("Ask your parent for the 6-digit access code found in their app.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)
            
            TextField("Enter 6-digit Code", text: $codeInput)
                .font(.title)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            
            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red).font(.caption)
            }
            
            Button(action: {
                viewModel.redeemInviteCode(code: codeInput)
            }) {
                Text("Join Family")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(codeInput.count != 6)
            
            Spacer()
            
            // NEW SYNTAX: Direct function reference
            // This is cleaner and less prone to syntax errors
            Button("Sign Out", action: viewModel.signOut)
                .tint(.red)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
