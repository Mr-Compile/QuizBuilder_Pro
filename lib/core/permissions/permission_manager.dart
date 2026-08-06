/// Permission definitions for granular access control
class AppPermissions {
  AppPermissions._();

  // User Management
  static const String viewUsers = 'view_users';
  static const String createUsers = 'create_users';
  static const String editUsers = 'edit_users';
  static const String deleteUsers = 'delete_users';
  static const String activateUsers = 'activate_users';

  // Topic Management
  static const String viewTopics = 'view_topics';
  static const String createTopics = 'create_topics';
  static const String editTopics = 'edit_topics';
  static const String deleteTopics = 'delete_topics';

  // Question Management
  static const String viewQuestions = 'view_questions';
  static const String createQuestions = 'create_questions';
  static const String editQuestions = 'edit_questions';
  static const String deleteQuestions = 'delete_questions';
  static const String generateAIQuestions = 'generate_ai_questions';

  // Quiz Management
  static const String takeQuizzes = 'take_quizzes';
  static const String viewOwnResults = 'view_own_results';
  static const String viewAllResults = 'view_all_results';
  static const String viewStatistics = 'view_statistics';

  // System
  static const String accessSettings = 'access_settings';
  static const String viewAbout = 'view_about';
}

/// Role-based permission definitions
class RolePermissions {
  RolePermissions._();

  static const Map<String, Set<String>> permissions = {
    'teacher': {
      // User Management
      AppPermissions.viewUsers,
      AppPermissions.createUsers,
      AppPermissions.editUsers,
      AppPermissions.deleteUsers,
      AppPermissions.activateUsers,

      // Topic Management
      AppPermissions.viewTopics,
      AppPermissions.createTopics,
      AppPermissions.editTopics,
      AppPermissions.deleteTopics,

      // Question Management
      AppPermissions.viewQuestions,
      AppPermissions.createQuestions,
      AppPermissions.editQuestions,
      AppPermissions.deleteQuestions,
      AppPermissions.generateAIQuestions,

      // Quiz Management
      AppPermissions.viewAllResults,
      AppPermissions.viewStatistics,

      // System
      AppPermissions.accessSettings,
      AppPermissions.viewAbout,
    },
    'student': {
      // Topic Management
      AppPermissions.viewTopics,

      // Question Management
      AppPermissions.viewQuestions,

      // Quiz Management
      AppPermissions.takeQuizzes,
      AppPermissions.viewOwnResults,
      AppPermissions.viewStatistics,

      // System
      AppPermissions.accessSettings,
      AppPermissions.viewAbout,
    },
  };

  static Set<String> getPermissionsForRole(String role) {
    return permissions[role] ?? {};
  }

  static bool hasPermission(String role, String permission) {
    return getPermissionsForRole(role).contains(permission);
  }
}