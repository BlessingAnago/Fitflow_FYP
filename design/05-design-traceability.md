# FitFlow Design Traceability

| Requirement | Design Decision | Implementation Evidence |
| --- | --- | --- |
| Secure login | Keychain-backed credentials + optional biometrics | `KeychainService`, `AuthViewModel`, `LockScreenView` |
| Offline access | On-device Core Data persistence | `PersistenceController`, Core Data entities |
| Usability | Tab-based navigation and task-focused screens | `MainTabView`, Dashboard actions |
| Workout tracking | Structured workout + exercise model | `CDWorkout` + `CDExercise`, `WorkoutViewModel.createWorkout` |
| Nutrition tracking | Meal and food item split with macro math | `CDMeal` + `CDFoodItem`, `MealViewModel` |
| Progress insights | Weight trends and period filters | `ProgressViewModel`, `StatsView` |
| Privacy-first data handling | Local storage, no cloud sync in model | Core Data model `usedWithCloudKit="false"` |
| Onboarding personalization | Multi-step onboarding persisted to profile | `OnboardingCoordinatorView.saveOnboardingData` |

## Known Open Gaps

- HealthKit integration and consent flow are not implemented yet.
- Notification scheduling/permissions are not implemented yet.

