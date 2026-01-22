# Data Optimization Quick Reference

## 🚀 Quick Start

### Using Optimized Indexes

```dart
// Import the optimization layer
import 'package:smart_bite/data/optimized_indexes.dart';

// Get nutrition data (type-safe)
final dish = OptimizedDishesInfo.get('雙薯搖滾蛋沙拉');
if (dish != null) {
  print('Calories: ${dish.calorie}');
  print('Protein: ${dish.protein}');
  print('Grains: ${dish.getValue(NutritionType.grains)}');
}

// Get label information
final labels = OptimizedDishesLabel.get('雙薯搖滾蛋沙拉');
if (labels != null) {
  final type = labels[Label.type];
  final food = labels[Label.food];
}

// Check if dish exists
if (OptimizedDishesInfo.contains('Some Dish')) {
  // ... process
}
```

### RFID Caching

```dart
final service = MealIdentificationService();

// Automatic caching (LRU, max 30 entries)
final mealName = service.identifyMeal(rfidUid); // Cached automatically

// Get cache statistics
final stats = service.getCacheStats();
print('Cache size: ${stats['size']}/${stats['maxSize']}');

// Clear cache (for testing)
service.clearCache();
```

### Lazy-Loaded PDF Data

```dart
// Import lazy loader
import 'package:smart_bite/data/lazy_label_data.dart';

// Automatic loading on first access
final info = LazyLabelData.getInfo('雞蛋');
print('Certification: ${info?['certification_id']}');

// Pre-load explicitly (optional)
await LazyLabelData.preload();

// Check if loaded
if (LazyLabelData.isLoaded) {
  print('Data is in memory');
}
```

## 🐛 Debug & Testing

### Disable Caching

```bash
# Run with caching disabled
flutter run --dart-define=DISABLE_CACHE=true

# Build with caching disabled
flutter build linux --dart-define=DISABLE_CACHE=true
```

### Performance Monitoring

```dart
// RFID lookup timing
final stopwatch = Stopwatch()..start();
final meal = service.identifyMeal(rfidUid);
stopwatch.stop();
print('Lookup took: ${stopwatch.elapsedMicroseconds} μs');

// Cache statistics
final stats = service.getCacheStats();
print('Cache hit rate: ${stats['size']}/${stats['maxSize']}');
print('Disabled: ${stats['disabled']}');
```

## 📊 Performance Benchmarks

### Expected Performance

| Operation | Target Time | Notes |
|-----------|-------------|-------|
| RFID Lookup (cached) | < 0.2 ms | 70-80% hit rate expected |
| RFID Lookup (uncached) | < 1 ms | First access or cache miss |
| Nutrition Analysis | < 40 ms | 5-8 dishes typical |
| PDF Generation | < 150 ms | All 4 label types |

### Monitoring in Production

```dart
// Add timing wrapper for critical operations
T measurePerformance<T>(String operation, T Function() fn) {
  final stopwatch = Stopwatch()..start();
  final result = fn();
  stopwatch.stop();
  debugPrint('[$operation] took ${stopwatch.elapsedMilliseconds} ms');
  return result;
}

// Usage
final result = measurePerformance('Nutrition Analysis', () {
  return service.analyzeNutrition(...);
});
```

## 🔧 Common Tasks

### Adding a New Dish

1. Add to `dishes_info.dart` (raw data)
2. Add to `dishes_label.dart` if it has labels
3. Optimized indexes update automatically on next app start
4. No code changes needed!

### Adding a New Label Field

1. Update `lazy_label_data.dart` with new field
2. Update PDF generation to use new field
3. Test with cache disabled first

### Troubleshooting Slow Performance

```dart
// Check if indexes are initialized
void verifyIndexes() {
  print('Dishes indexed: ${OptimizedDishesInfo.count}');
  print('All dishes: ${OptimizedDishesInfo.allDishNames.length}');
  
  if (OptimizedDishesInfo.count == 0) {
    print('⚠️ WARNING: Indexes not initialized!');
    print('Call initializeOptimizedIndexes() in main.dart');
  }
}

// Check cache performance
void verifyCachePerformance(MealIdentificationService service) {
  final stats = service.getCacheStats();
  
  if (stats['disabled'] == true) {
    print('ℹ️ Caching is disabled (DISABLE_CACHE=true)');
  }
  
  if (stats['size'] == stats['maxSize']) {
    print('✓ Cache is full (good utilization)');
  }
}
```

## 🧪 Testing

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bite/data/optimized_indexes.dart';

void main() {
  setUpAll(() {
    // Initialize indexes before tests
    initializeOptimizedIndexes();
  });
  
  test('Optimized index provides correct nutrition data', () {
    final dish = OptimizedDishesInfo.get('雙薯搖滾蛋沙拉');
    
    expect(dish, isNotNull);
    expect(dish!.name, equals('雙薯搖滾蛋沙拉'));
    expect(dish.calorie, greaterThan(0));
  });
  
  test('RFID cache works correctly', () {
    final service = MealIdentificationService();
    
    final meal1 = service.identifyMeal('test_uid_123');
    final meal2 = service.identifyMeal('test_uid_123'); // Should hit cache
    
    expect(meal1, equals(meal2));
    
    final stats = service.getCacheStats();
    expect(stats['size'], equals(1));
  });
}
```

### Integration Test Template

```dart
testWidgets('Nutrition analysis uses optimized indexes', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Initialize indexes
  await initializeOptimizedIndexes();
  
  // Select dishes via RFID
  final service = MealIdentificationService();
  final dishes = ['dish1', 'dish2'].map((uid) => 
    service.identifyMeal(uid)
  ).toList();
  
  // Analyze nutrition (should be fast)
  final stopwatch = Stopwatch()..start();
  final result = await NutritionAnalysisService.analyzeNutrition(
    orderNames: dishes,
    // ... other params
  );
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(50));
  expect(result.neededCaloriePerDay, greaterThan(0));
});
```

## 📝 Migration Checklist

### When Adding New Features

- [ ] Use `OptimizedDishesInfo.get()` instead of `dishesInfo[key]`
- [ ] Use `OptimizedDishesLabel.get()` instead of `dishesLabel[key]`
- [ ] Use `LazyLabelData.getInfo()` for PDF label data
- [ ] Add timing measurements for new critical paths
- [ ] Test with `DISABLE_CACHE=true` to verify correctness
- [ ] Document expected performance in comments

### Code Review Checklist

- [ ] No direct imports of `dishes_info.dart` in services (use optimized layer)
- [ ] No repeated map lookups in tight loops
- [ ] Cache-friendly patterns (access once, reuse result)
- [ ] Proper null handling with optimized indexes
- [ ] Performance-critical code has timing measurements

## 🎯 Best Practices

### DO ✅

```dart
// Use optimized indexes
final dish = OptimizedDishesInfo.get(name);
final calorie = dish?.calorie ?? 0.0;

// Cache lookup results
final labelData = LazyLabelData.getInfo(foodName);
final code = labelData?['trace_code'] ?? '';
final operator = labelData?['operator'] ?? '';

// Use type-safe accessors
final value = dish.getValue(NutritionType.protein);
```

### DON'T ❌

```dart
// Don't bypass optimization layer
final dish = dishesInfo[name]; // ❌ Slower, less type-safe

// Don't repeat map lookups
final code = foodToLabelInfo[key]?['trace_code'];
final operator = foodToLabelInfo[key]?['operator']; // ❌ Lookup twice

// Don't ignore null safety
final value = dish!.toMap()[type]!; // ❌ Can crash
```

## 🔗 Related Files

- **Core Implementation:** `lib/data/optimized_indexes.dart`
- **Lazy Loading:** `lib/data/lazy_label_data.dart`
- **RFID Service:** `lib/services/meal_identification_service.dart`
- **Nutrition Service:** `lib/services/nutrition_analysis_service.dart`
- **PDF Service:** `lib/services/pdf_generation_service.dart`
- **Full Documentation:** `documents/DATA_OPTIMIZATION_IMPLEMENTATION.md`

## 📞 Support

If you encounter issues:
1. Check if indexes are initialized in `main.dart`
2. Test with `DISABLE_CACHE=true` to isolate caching issues
3. Verify performance benchmarks match expected values
4. Review full implementation guide in `documents/`

---

**Last Updated:** 2025-12-20  
**Version:** 1.0
