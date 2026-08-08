# Daily AI Usage Limit System - Implementation Summary

## Overview
A secure daily AI usage limit system has been implemented for Quiz Builder Pro that prevents abuse and cannot be bypassed through UI modifications.

## Security Architecture

### Service Layer Enforcement
The quota system is enforced at the **service layer**, not the UI layer. This ensures that:
- Users cannot bypass limits by editing UI widgets
- Users cannot bypass limits by hiding buttons
- Users cannot bypass limits by changing local state variables
- Users cannot bypass limits by navigating directly to generation screens

All AI generation requests **must** pass through the central quota validator in `QuotaService`.

## Implementation Components

### 1. Quota Constants (`lib/core/constants/app_constants.dart`)
```dart
static const int teacherDailyQuota = 10;
static const int studentDailyQuota = 0;
static const String prefsLastQuotaResetDate = 'lastQuotaResetDate';
```

### 2. Quota Service (`lib/services/quota_service.dart`)
The core service that manages and enforces quotas:
- **`checkQuotaAndThrowIfExceeded(User user)`** - Primary enforcement point that throws exceptions when limits are exceeded
- **`recordGeneration()`** - Records successful AI generations for tracking
- **`getRemainingQuota(User user)`** - Returns remaining quota for a user
- **`getQuotaInfo(User user)`** - Returns comprehensive quota information
- **`_checkAndResetQuotaIfNeeded()`** - Automatic daily reset at midnight
- **`_resetAllQuotas()`** - Clears all daily quotas

### 3. Enhanced Groq AI Service (`lib/services/groq_ai_service.dart`)
All generation methods now require a `User` parameter and enforce quota checks:
- **`generateQuestions()`** - Added `required User user` parameter
- **`generateFromCustomTopic()`** - Added `required User user` parameter
- **`generateFromFileContent()`** - Added `required User user` parameter

Each method:
1. Calls `quota.checkQuotaAndThrowIfExceeded(user)` before any API calls
2. Records successful generations with `quota.recordGeneration()`

### 4. Quota Indicator Widget (`lib/widgets/quota_indicator.dart`)
A reusable widget that displays quota status:
- Shows remaining generations out of daily limit
- Visual progress bar with color coding
- Compact and full display modes
- Automatic refresh when user changes
- Disabled state for users with 0 quota (students)

### 5. UI Integration
The quota indicator has been integrated into:
- **AI Generation Screen** - Shows quota before generation
- **Teacher Dashboard** - Shows quota status at top
- **Settings Screen** - Shows quota in API configuration section

## Database Schema

The existing `ai_generations` table is used for quota tracking:
```sql
CREATE TABLE ai_generations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_by INTEGER NOT NULL,
  topic_id INTEGER NOT NULL,
  difficulty TEXT NOT NULL,
  count INTEGER NOT NULL,
  generated_at TEXT NOT NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
)
```

## Security Features

### 1. Role-Based Limits
- **Teachers**: 10 AI generations per day
- **Students**: 0 AI generations per day (completely blocked)

### 2. Automatic Daily Reset
- Quotas automatically reset at midnight
- Uses SharedPreferences to track last reset date
- Date-based comparison ensures reset happens exactly once per day

### 3. Immutable Constants
- Quota limits are stored as application constants
- Not editable through settings or UI
- Requires code changes to modify

### 4. Service Layer Validation
- All generation paths require user authentication
- Quota checks happen before any API calls
- Cannot be bypassed through UI manipulation

### 5. Comprehensive Error Handling
- `QuotaExceededException` thrown when limits exceeded
- Clear error messages displayed to users
- UI updates automatically after quota changes

## Testing Checklist

### Security Testing
- [ ] Verify students cannot generate AI questions (quota = 0)
- [ ] Verify teachers are limited to 10 generations per day
- [ ] Verify quota resets automatically at midnight
- [ ] Verify quota enforcement cannot be bypassed through UI
- [ ] Verify quota persists across app restarts

### Functional Testing
- [ ] Test quota indicator displays correctly
- [ ] Test quota decreases after successful generation
- [ ] Test error message when quota exceeded
- [ ] Test quota refreshes after generation
- [ ] Test different users have separate quotas

### Integration Testing
- [ ] Test AI generation screen with quota enforcement
- [ ] Test teacher dashboard shows quota status
- [ ] Test settings screen shows quota status
- [ ] Test custom topic generation respects quota
- [ ] Test file upload generation respects quota

## Usage Example

### For Developers
```dart
// Get quota service
final quota = await ServiceLocator.quota;

// Check if user can generate
try {
  await quota.checkQuotaAndThrowIfExceeded(currentUser);
  // Proceed with generation
} catch (e) {
  // Handle quota exceeded
}

// Get quota info for display
final info = await quota.getQuotaInfo(currentUser);
print('Remaining: ${info['remaining']} of ${info['limit']}');
```

### For Users
1. Teachers see their remaining quota in the AI generation screen
2. When quota is low (≤2), warning is displayed
3. When quota is exhausted, generation is blocked with clear message
4. Quota automatically resets at midnight

## Future Enhancements
- Add admin controls to adjust individual user quotas
- Add quota usage analytics for teachers
- Implement quota carryover or bonus systems
- Add notifications when quota is running low

## Files Modified/Created

### Created
- `lib/services/quota_service.dart` - Core quota management service
- `lib/widgets/quota_indicator.dart` - Quota display widget

### Modified
- `lib/core/constants/app_constants.dart` - Added quota constants
- `lib/services/groq_ai_service.dart` - Added quota enforcement
- `lib/services/service_locator.dart` - Added quota service registration
- `lib/features/question/ai_generate_screen.dart` - Added quota UI and user parameter
- `lib/features/teacher/teacher_dashboard_screen.dart` - Added quota indicator
- `lib/features/settings/settings_screen.dart` - Added quota indicator

## Conclusion
The implemented quota system provides robust, secure enforcement of daily AI generation limits that cannot be bypassed through UI modifications. The service layer architecture ensures that all generation requests are validated before execution, and the automatic daily reset ensures fair usage across all users.
