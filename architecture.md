## 1️⃣ Architectural Design (SYSTEM-LEVEL)

### What examiners expect

They want to see:

•⁠  ⁠How the app is structured internally
•⁠  ⁠How responsibilities are separated
•⁠  ⁠Why your architecture makes sense for the problem

### What YOU should include (for FitFlow)

✔ Architecture pattern (MVVM)
✔ Diagram showing:

•⁠  ⁠Views
•⁠  ⁠ViewModels
•⁠  ⁠Models
•⁠  ⁠Persistence (Core Data)
•⁠  ⁠External services (HealthKit, Notifications)

✔ Justification:

•⁠  ⁠Why MVVM over MVC
•⁠  ⁠Why SwiftUI fits this architecture

### How to do it

•⁠  ⁠Draw a *component diagram*
•⁠  ⁠Label each layer clearly
•⁠  ⁠Add a short explanation under the diagram

💡 This shows *software engineering maturity*, not just coding.

---

## 2️⃣ Data Design (STRUCTURAL)

### What examiners expect

They want to see:

•⁠  ⁠How data is structured
•⁠  ⁠How it is stored
•⁠  ⁠How relationships are handled

### What YOU should include

✔ Entity list:

•⁠  ⁠UserProfile
•⁠  ⁠Workout
•⁠  ⁠Exercise
•⁠  ⁠Meal
•⁠  ⁠FoodItem
•⁠  ⁠ProgressEntry

✔ Relationships (1–many, etc.)
✔ Why Core Data was chosen
✔ Privacy-first storage justification

### Artefact

•⁠  ⁠*ER Diagram* or *Class Diagram*
•⁠  ⁠Not code — visual + explanation

💡 This proves you didn’t “just store stuff randomly”.

---

## 3️⃣ Functional Design (BEHAVIOUR)

### What examiners expect

They want to see:

•⁠  ⁠What the system does
•⁠  ⁠How users interact with it
•⁠  ⁠What happens step-by-step

### What YOU already did well

✔ Use Case Diagram
✔ Use Case Descriptions

But for *full design*, you must also show:

•⁠  ⁠Internal flow of logic

### Add this

✔ *Activity diagrams* or *sequence diagrams* for:

•⁠  ⁠Logging a workout
•⁠  ⁠Logging a meal
•⁠  ⁠Viewing progress

💡 This bridges *requirements → implementation*.

---

## 4️⃣ User Interface Design (THIS IS WHERE WIREFRAMES FIT)

### What examiners expect

They want:

•⁠  ⁠Layout decisions
•⁠  ⁠Navigation logic
•⁠  ⁠Accessibility awareness

### What YOU should include

✔ Low-fidelity wireframes (structure)
✔ High-fidelity wireframes (detailed layout)
✔ Explanation of:

•⁠  ⁠Navigation choice (tab bar)
•⁠  ⁠Why screens are arranged that way
•⁠  ⁠How it supports usability

✔ Accessibility notes:

•⁠  ⁠Dynamic Type
•⁠  ⁠Button size
•⁠  ⁠Colour contrast

💡 UI ≠ decoration. It’s *design reasoning*.

---

## 5️⃣ Security & Privacy Design (VERY IMPORTANT)

This is often where marks are lost.

### What examiners expect

They want to see:

•⁠  ⁠You understand legal and ethical implications
•⁠  ⁠You designed around them, not added them later

### What YOU should include

✔ Threat awareness (health data sensitivity)
✔ Design decisions:

•⁠  ⁠On-device storage
•⁠  ⁠Keychain
•⁠  ⁠Biometric auth
•⁠  ⁠Consent-based HealthKit

✔ Boundary explanation (what data leaves the device, what doesn’t)

💡 This directly links to *UK GDPR* and your ethics section.

---

## 6️⃣ Design Traceability (THE HIDDEN MARK BOOSTER)

This is what separates *good* from *excellent* projects.

### What examiners LOVE

Seeing that:

	⁠Every design choice links back to a requirement.

### How YOU do this

Create a *small table*:

| Requirement    | Design Decision           |
| -------------- | ------------------------- |
| Secure login   | Biometric auth + Keychain |
| Offline access | Core Data local storage   |
| Usability      | Tab-based navigation      |
| Motivation     | Dashboard + streaks       |

💡 This proves *intentional design*, not guessing.

---

# How to Go About It STEP-BY-STEP (Do This Exactly)

### Step 1: Freeze Your Requirements

You already did this in PPRS ✅
Do *not change scope* now.

---

### Step 2: Design Before Coding

For each major feature:

•⁠  ⁠Sketch
•⁠  ⁠Diagram
•⁠  ⁠Explain

Only then implement.

---

### Step 3: Match Every Design to a Section

Your report structure should look like:


4. System Design
  4.1 Architectural Design
  4.2 Data Design
  4.3 Functional Design
  4.4 User Interface Design
  4.5 Security & Privacy Design
  4.6 Design Traceability


