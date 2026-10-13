import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
}

class PasswordStrengthResult {
  final double score; // 0.0 to 1.0
  final PasswordStrength strength;
  final String label;
  final Color color;
  final List<String> feedback;

  const PasswordStrengthResult({
    required this.score,
    required this.strength,
    required this.label,
    required this.color,
    required this.feedback,
  });
}

class PasswordValidator {
  static PasswordStrengthResult evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0.0,
        strength: PasswordStrength.weak,
        label: 'Empty',
        color: Colors.grey,
        feedback: ['Enter at least 8 characters'],
      );
    }

    double score = 0.0;
    final feedback = <String>[];

    // 1. Length check
    if (password.length >= 8) {
      score += 0.25;
    } else {
      feedback.add('At least 8 characters');
    }
    if (password.length >= 12) {
      score += 0.15;
    }

    // 2. Uppercase & Lowercase check
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    if (hasUpper && hasLower) {
      score += 0.25;
    } else {
      feedback.add('Mix of UPPER and lowercase');
    }

    // 3. Digits check
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    if (hasDigits) {
      score += 0.15;
    } else {
      feedback.add('At least 1 number');
    }

    // 4. Special characters
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (hasSpecial) {
      score += 0.20;
    } else {
      feedback.add('At least 1 special symbol');
    }

    // Normalize
    score = score.clamp(0.0, 1.0);

    if (score < 0.4) {
      return PasswordStrengthResult(
        score: score,
        strength: PasswordStrength.weak,
        label: 'Weak',
        color: const Color(0xFFFF3366),
        feedback: feedback,
      );
    } else if (score < 0.7) {
      return PasswordStrengthResult(
        score: score,
        strength: PasswordStrength.fair,
        label: 'Fair',
        color: const Color(0xFFFFB300),
        feedback: feedback,
      );
    } else if (score < 0.9) {
      return PasswordStrengthResult(
        score: score,
        strength: PasswordStrength.good,
        label: 'Strong',
        color: const Color(0xFF00F2FE),
        feedback: feedback,
      );
    } else {
      return PasswordStrengthResult(
        score: score,
        strength: PasswordStrength.strong,
        label: 'Unbreakable',
        color: const Color(0xFF00E676),
        feedback: ['Excellent security!'],
      );
    }
  }
}
