//
//  ChildDashboardView.swift
//  prizepantry
//
//  Created by Shawn Hulme on 1/6/26.
//


import SwiftUI

struct ChildDashboardView: View {
    @ObservedObject var viewModel: ChildViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            if let child = viewModel.linkedChildProfile {
                Image(systemName: "star.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.yellow)
                
                Text("Welcome, \(child.name)!")
                    .font(.largeTitle)
                    .bold()
                
                VStack {
                    Text("Your Balance")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(child.tokenBalance)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(.blue)
                    
                    Text("Tokens")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.1)))
                .padding()
                
            } else {
                ProgressView("Loading your profile...")
            }
            
            Button("Sign Out") {
                viewModel.signOut()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }
}
