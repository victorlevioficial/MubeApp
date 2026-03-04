# Performance Guidelines - MubeApp

## Const Constructors

### Why Use Const?
- Widgets marked `const` are created once at compile time
- Flutter skips rebuilding const widgets during setState/rebuild cycles
- Reduces memory allocations and garbage collection pressure

### Rules
```dart
// ✅ Use const when all parameters are compile-time constants
const SizedBox(height: 16);
const Text('Static text');
const Icon(Icons.home, size: 24);

// ✅ Class constructors should be const when possible
class MyWidget extends StatelessWidget {
  const MyWidget({super.key}); // const constructor
}

// ❌ Cannot be const if using runtime values
SizedBox(height: dynamicValue); // No const
Text(userName);                  // No const
```

## Widget Optimization Patterns

### 1. Extract Static Widgets
```dart
// ❌ Bad - rebuilds every time
Widget build(BuildContext context) {
  return Column(
    children: [
      const SizedBox(height: 16),
      _buildHeader(), // If this is static, extract it
    ],
  );
}

// ✅ Good - static const extracted
static const _header = Padding(
  padding: EdgeInsets.all(16),
  child: Text('Header'),
);

Widget build(BuildContext context) {
  return Column(children: [_header, _dynamicContent()]);
}
```

### 2. Use RepaintBoundary for Complex Widgets
```dart
// For widgets that render frequently but don't change
RepaintBoundary(
  child: ComplexAnimatedWidget(),
)
```

### 3. Prefer StatelessWidget
Use `StatefulWidget` only when you need:
- `setState()` to trigger rebuilds
- `initState()` / `dispose()` lifecycle hooks
- Mutable local state

## Current Optimizations Applied

| Widget | Optimization |
|--------|--------------|
| `OnboardingProgressBar` | const constructor, const TextStyle |
| `OnboardingHeader` | const constructor, const Icon |
| `PrimaryButton` | const constructor |
| `OrDivider` | const constructor |
| `AppLoading` | const constructor with named constructors |

## Running Performance Analysis

```bash
# Profile mode with DevTools
flutter run --profile

# Open DevTools
# Run "Open DevTools" from VS Code or press 'd' in terminal
```
