//
//  ProgressView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with Level Badge
                    HeaderSectionView()
                        .environmentObject(userProfile)
                    
                    // Overall Stats Cards
                    OverallStatsView()
                        .environmentObject(userProfile)
                        .environmentObject(quizManager)
                    
                    // Weekly Progress Chart
                    WeeklyProgressView()
                        .environmentObject(userProfile)
                    
                    // Achievement Badges
                    AchievementBadgesView()
                        .environmentObject(userProfile)
                    
                    // Learning Streaks
                    LearningStreakView()
                        .environmentObject(userProfile)
                    
                    // Recent Activity
                    RecentActivityView()
                        .environmentObject(quizManager)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - New Header Section
struct HeaderSectionView: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("Overall Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Level Badge - Full Width
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(userProfile.proficiencyLevel.description)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(userProfile.totalPoints)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(userProfile.proficiencyLevel.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(userProfile.proficiencyLevel.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Improved Stats View
struct OverallStatsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Responsive Stats Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ImprovedStatCard(
                    icon: "brain.head.profile",
                    value: "\(userProfile.totalPoints)",
                    title: "Total Points",
                    color: .blue
                )
                
                ImprovedStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(userProfile.totalQuizzesCompleted)",
                    title: "Quizzes",
                    color: .green
                )
                
                ImprovedStatCard(
                    icon: "target",
                    value: String(format: "%.0f%%", userProfile.accuracyPercentage),
                    title: "Accuracy",
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - New Improved StatCard
struct ImprovedStatCard: View {
    let icon: String
    let value: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(height: 24)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Improved Weekly Progress
struct WeeklyProgressView: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // Streak Info
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(userProfile.currentStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Day Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Badges Info
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(userProfile.badges.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Badges")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Keep learning daily to maintain your streak!")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Improved Achievement Badges
struct AchievementBadgesView: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(userProfile.badges.count) of \(Badge.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if userProfile.badges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Complete quizzes to earn badges!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            } else {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(userProfile.badges), id: \.self) { badge in
                        ImprovedBadgeView(badge: badge)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Improved Badge View
struct ImprovedBadgeView: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: badge.icon)
                .font(.title3)
                .foregroundColor(badge.color)
                .frame(height: 20)
            
            Text(badge.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(badge.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(badge.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Improved Learning Streak
struct LearningStreakView: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Streak")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(userProfile.currentStreak)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("days")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.top, 6)
                    }
                    
                    Text("Come back tomorrow to continue!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Improved Recent Activity
struct RecentActivityView: View {
    @EnvironmentObject var quizManager: QuizManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if quizManager.quizHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    
                    Text("No recent activity")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(quizManager.getRecentPerformance().prefix(5)) { result in
                        ImprovedActivityRow(result: result)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Improved Activity Row
struct ImprovedActivityRow: View {
    let result: QuizResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(result.percentage >= 80 ? .green : result.percentage >= 60 ? .orange : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Quiz Completed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(result.completedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.score)/\(result.totalQuestions)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(result.percentage >= 80 ? .green : result.percentage >= 60 ? .orange : .red)
                
                Text("+\(result.score * 10) pts")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Legacy StatCard (keeping for compatibility)
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        ImprovedStatCard(icon: icon, value: value, title: title, color: color)
    }
}

struct BadgeView: View {
    let badge: Badge
    
    var body: some View {
        ImprovedBadgeView(badge: badge)
    }
}

struct ActivityRow: View {
    let result: QuizResult
    
    var body: some View {
        ImprovedActivityRow(result: result)
    }
}

#Preview {
    ProgressView()
        .environmentObject(UserProfile())
        .environmentObject(QuizManager())
} 