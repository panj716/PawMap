import SwiftUI

// MARK: - Modern Design System for Young Users
struct AppTheme {
    // MARK: - Colors (Instagram Style with Light Yellow)
    struct Colors {
        // Instagram-style gradient (sunset vibes)
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.8, blue: 0.4),    // Warm Yellow
                Color(red: 1.0, green: 0.6, blue: 0.5),   // Coral
                Color(red: 0.9, green: 0.4, blue: 0.6)     // Pink
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondaryGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.95, green: 0.9, blue: 0.7),   // Light Yellow
                Color(red: 1.0, green: 0.85, blue: 0.6)   // Peach
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Main background - Light Yellow (Instagram style)
        static let background = Color(red: 0.98, green: 0.96, blue: 0.88)  // Very light yellow/cream
        static let cardBackground = Color.white
        static let surface = Color(red: 0.99, green: 0.97, blue: 0.92)     // Light cream
        
        // Accent colors (Instagram palette)
        static let primary = Color(red: 1.0, green: 0.7, blue: 0.4)        // Warm Orange
        static let secondary = Color(red: 0.9, green: 0.4, blue: 0.6)      // Pink
        static let accent = Color(red: 0.4, green: 0.7, blue: 0.9)        // Sky Blue
        static let warmYellow = Color(red: 1.0, green: 0.9, blue: 0.6)    // Light Yellow
        
        // Text colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textOnPrimary = Color.white
        
        // Place type colors (vibrant, modern)
        static func placeColor(for type: Place.PlaceType) -> Color {
            switch type {
            case .coffee:
                return Color(red: 1.0, green: 0.6, blue: 0.2)  // Vibrant Orange
            case .trail:
                return Color(red: 0.2, green: 0.8, blue: 0.4)  // Fresh Green
            case .park:
                return Color(red: 0.2, green: 0.7, blue: 1.0)  // Bright Blue
            case .beach:
                return Color(red: 0.3, green: 0.9, blue: 1.0)  // Cyan
            case .shop:
                return Color(red: 0.8, green: 0.4, blue: 1.0)  // Purple
            case .camp:
                return Color(red: 0.7, green: 0.5, blue: 0.3)  // Brown
            case .restaurant:
                return Color(red: 1.0, green: 0.3, blue: 0.3)  // Red
            case .other:
                return Color.gray
            }
        }
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        static let pill: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
}

// MARK: - View Modifiers for Consistent Styling
extension View {
    // Modern card style
    func modernCard(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
            .shadow(
                color: AppTheme.Shadows.medium.color,
                radius: AppTheme.Shadows.medium.radius,
                x: AppTheme.Shadows.medium.x,
                y: AppTheme.Shadows.medium.y
            )
    }
    
    // Primary button style
    func primaryButton() -> some View {
        self
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.Colors.textOnPrimary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.primaryGradient)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(
                color: AppTheme.Shadows.medium.color,
                radius: AppTheme.Shadows.medium.radius,
                x: AppTheme.Shadows.medium.x,
                y: AppTheme.Shadows.medium.y
            )
    }
    
    // Secondary button style
    func secondaryButton() -> some View {
        self
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 2)
                    )
            )
    }
    
    // Pill button style (for filters)
    func pillButton(isSelected: Bool) -> some View {
        self
            .font(AppTheme.Typography.subheadline)
            .foregroundColor(isSelected ? AppTheme.Colors.textOnPrimary : AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Group {
                    if isSelected {
                        AppTheme.Colors.primaryGradient
                    } else {
                        AppTheme.Colors.cardBackground
                    }
                }
            )
            .cornerRadius(AppTheme.CornerRadius.pill)
            .shadow(
                color: isSelected ? AppTheme.Shadows.small.color : Color.clear,
                radius: isSelected ? AppTheme.Shadows.small.radius : 0,
                x: 0,
                y: isSelected ? AppTheme.Shadows.small.y : 0
            )
    }
}

