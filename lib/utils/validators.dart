/// Form validation utilities
/// Reusable validation functions for consistent behavior across the app
class Validators {
  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    // Email regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null; // null means validation passed
  }
  
  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }
  
  /// Required field validation
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// URL validation (lenient)
  static String? url(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Please enter a URL' : null;
    }

    // Very lenient URL validation - just check if it contains a dot
    // and starts with http/https or www, or contains common social domains
    final trimmedValue = value.trim().toLowerCase();
    
    // Allow common social media patterns
    final socialDomains = [
      'instagram.com', 'facebook.com', 'twitter.com', 'linkedin.com',
      'youtube.com', 'tiktok.com', 'pinterest.com', 'snapchat.com',
      'github.com', 'behance.net', 'dribbble.com'
    ];
    
    // Check if it's a social media URL
    if (socialDomains.any((domain) => trimmedValue.contains(domain))) {
      return null;
    }
    
    // Check if it looks like a URL
    if (trimmedValue.startsWith('http://') || 
        trimmedValue.startsWith('https://') ||
        trimmedValue.startsWith('www.') ||
        (trimmedValue.contains('.') && trimmedValue.length > 3)) {
      return null;
    }
    
    return 'Please enter a valid URL';
  }

  /// Social media URL validation (very lenient)
  static String? socialUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Social URLs are optional
    }

    final trimmedValue = value.trim();
    
    // Very basic check - just ensure it's not empty and has some characters
    if (trimmedValue.length < 3) {
      return 'URL too short';
    }
    
    // Allow pretty much anything that looks like it could be a URL
    return null;
  }
}