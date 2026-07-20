# Implementation Plan - Restructuring to MVVM Architecture with GetX

We will restructure the BG Remover project into an MVVM (Model-View-ViewModel) architecture utilizing **GetX** for state management. This will simplify controller lifecycles, eliminate boilerplate listener setup, and cleanly decouple the business logic/state from the UI layer.

## User Review Required

> [!NOTE]
> We will add the `get` package to `pubspec.yaml`. The view models will inherit from `GetxController`, and the views will consume state reactive/builder hooks (like `GetBuilder` or `Obx`).

## Proposed Changes

### [Dependency Updates]

#### [MODIFY] [pubspec.yaml](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/pubspec.yaml)
Add `get: ^4.6.6` to dependencies.

---

### [ViewModels / Controllers Component]

We will create the following view model classes, all extending `GetxController` from GetX:

#### [NEW] [splash_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/splash_viewmodel.dart)
Handles app initialization delays, reading first-time user flags from `SharedPreferences`, checking active Supabase sessions, and determining initial routing.

#### [NEW] [onboarding_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/onboarding_viewmodel.dart)
Manages the onboarding completion logic, writing settings flags to local storage.

#### [NEW] [login_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/login_viewmodel.dart)
Manages text controllers, loading indicators, password obfuscation toggle state, email sign-in logic, forgot password reset emails, and guest sign-in. Exposes reactive/observable properties or calls `update()` for simple state triggers.

#### [NEW] [sign_up_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/sign_up_viewmodel.dart)
Manages registration input fields, password strength indicator state, terms checkbox state, and Supabase sign-up triggers.

#### [NEW] [main_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/main_viewmodel.dart)
Controls bottom navigation indices using reactive GetX fields.

#### [NEW] [home_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/home_viewmodel.dart)
Exposes loading states, camera/gallery permissions checks, picking image logic, and triggers background cloud synchronization.

#### [NEW] [preview_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/preview_viewmodel.dart)
Drives the ExtendedImage editor controller state, rotation/flip actions, and image cropping/exporting.

#### [NEW] [processing_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/processing_viewmodel.dart)
Coordinates ONNX Runtime model load state, progress percentages, locally saving output PNGs, and auto-syncing background tasks to Supabase Storage.

#### [NEW] [profile_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/profile_viewmodel.dart)
Fetches and formats user metadata names, triggers cloud uploads, logs statistics (local edits, cloud sync, plan status), and performs sign out.

#### [NEW] [recents_edits_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/recents_edits_viewmodel.dart)
Manages recent edits grids, image deletion confirm flows, and sharing functions.

#### [NEW] [result_viewmodel.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/viewmodels/result_viewmodel.dart)
Manages gallery saving steps, sharing sheets, and original vs result file metrics.

---

### [Views Component]

We will modify existing screens to hook up to their GetX ViewModels using `GetBuilder` or simple instantiation/dependency injection:

#### [MODIFY] [splash_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/splash_screen.dart)
Use `SplashViewModel` for initialization workflow.

#### [MODIFY] [onboarding_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/onboarding_screen.dart)
Use `OnboardingViewModel`.

#### [MODIFY] [login_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/login_screen.dart)
Instantiate `LoginViewModel` with `Get.put()` and use `GetBuilder<LoginViewModel>` to rebuild UI upon controller updates.

#### [MODIFY] [sign_up_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/sign_up_screen.dart)
Instantiate `SignUpViewModel` with `Get.put()` and use `GetBuilder<SignUpViewModel>`.

#### [MODIFY] [main_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/main_screen.dart)
Use `MainViewModel` index tracking via GetX.

#### [MODIFY] [home_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/home_screen.dart)
Use `GetBuilder<HomeViewModel>` to listen to loading and edits updates.

#### [MODIFY] [preview_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/preview_screen.dart)
Use `GetBuilder<PreviewViewModel>` to control rotations and flips.

#### [MODIFY] [processing_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/processing_screen.dart)
Use `GetBuilder<ProcessingViewModel>` to observe progress values.

#### [MODIFY] [profile_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/profile_screen.dart)
Use `GetBuilder<ProfileViewModel>` for lists, uploads, and account details.

#### [MODIFY] [recents_edits_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/recents_edits_screen.dart)
Use `GetBuilder<RecentsEditsViewModel>` to fetch and delete recent images.

#### [MODIFY] [result_screen.dart](file:///c:/Users/abdul/Desktop/Flutter-Project/UNI/bg_remover/lib/screens/result_screen.dart)
Use `GetBuilder<ResultViewModel>` for download and share triggers.

---

## Verification Plan

### Automated Tests
- Run `flutter pub get` to download dependencies.
- Run `flutter analyze` or `flutter test` to ensure there are no compilation errors.

### Manual Verification
- Test registration, email validation strength display, guest entrance, permissions checking, image picking/editing, ONNX model loading, processing progress updates, saving to storage/gallery, and logging out.
