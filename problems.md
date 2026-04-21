
# FitFlow Issues – Organized Fix Sequence

## 1. Core System Architecture (Fix First – Most Critical)

These affect **data integrity, authentication, and account safety**.

1. Implement **duplicate account prevention**
2. Ensure **session/authentication consistency**
3. Implement a **safer unlock flow**
4. Fix **login and profile synchronization**
5. Add **save success/failure handling instead of silent failures**
6. Replace onboarding call

   * Replace
     `progressVM.logProgress(...)`
   * With
     `progressVM.updateOrCreateTodayEntry(...)`
7. Prevent **duplicate initial weight logs**

---

# 2. Onboarding Flow Fixes

These affect **user setup accuracy and validation**.

### Step 1 Validation

8. Add validation for:

   * height
   * weight
   * age
9. Clamp entered **height and weight values** to valid ranges.

### Step 3 Weekly Workout Setup

10. Ensure
    `selectedWeekdayIndices.count == daysPerWeek`

This forces the user to pick the correct number of workout days.

### Completion Logic

11. Make onboarding save return **success/failure instead of silently failing**
12. Add **save success/failure handling in onboarding completion**
13. Prevent **duplicate initial weight logs**

---

# 3. Biometrics / Security Improvements

These improve **device security and authentication safety**.

14. Fix **biometric setup** so it:

* checks device availability
* verifies authentication capability

15. Only allow **biometrics enabling after successful capability check**
16. Protect **biometric enabling in ProfileView**
17. Fix **unsupported biometric icon display**
18. Ensure **consistent navigation from the secure step**

---

# 4. Meal System Fixes

These affect **food logging and data correctness**.

19. In `MealViewModel`, after saving:

* refresh **loadedDate**
* do **not always reload today's date**

20. Dashboard must **refresh meal data after dismissing `LogMealView`**

21. In `AddFoodView`:

* clamp food **quantity values**
* prevent **0g entries**

22. Clarify system logic:

Does **Create New Food**:

* create a **reusable food item**, OR
* directly **log a meal entry**

23. Decide meal logging model:

Either:

* **one meal per type per day**

OR

* **multiple entries per meal type**

UI and database must match the decision.

---

# 5. Workout System Fixes

24. Decide whether **workout session results overwrite saved workout defaults**

25. Separate:

* **Workout creation date**
* **Workout completion date**

26. Decide what **Stats "Workouts"** means:

Either:

* **Saved workouts**

OR

* **Completed workouts**

(Currently it counts saved workouts.)

27. Separate:

* **Workout notes**
* **Workout session history**

28. Improve **validation in `AddWorkoutView`**

---

# 6. UI / Data Consistency Improvements

These improve **clarity and reliability**.

29. Make **unit display in summary more stable**

30. Sync **profile weight after deleting a progress entry**

---



1️⃣ Authentication/session issues
2️⃣ Onboarding validation and saving
3️⃣ Biometrics security
4️⃣ Meal logging logic
5️⃣ Workout data structure
6️⃣ UI consistency improvements

