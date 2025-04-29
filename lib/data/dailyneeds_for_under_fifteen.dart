import 'package:smart_bite/data/constant.dart';

const Map<Sex, Map<Age, Map<ActivityLevel, Map<NutritionType, double>>>> dailyNeedsForUnderFifteen = {
  Sex.male:{
    Age.zeroToNine:{
      ActivityLevel.slightlyLow: {
        NutritionType.calorie: 1800,
        NutritionType.grains:3,
        NutritionType.meat: 5,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 3,
        NutritionType.fruits: 2,
        NutritionType.oils:5,
      },
      ActivityLevel.miderate: {
        NutritionType.calorie: 2100,
        NutritionType.grains: 3.5,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 4,
        NutritionType.fruits: 3,
        NutritionType.oils: 6,
      }
    },
    Age.tenToTwelve:{
      ActivityLevel.slightlyLow: {
        NutritionType.calorie: 2050,
        NutritionType.grains: 3,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 4,
        NutritionType.fruits: 3,
        NutritionType.oils: 6,
      },
      ActivityLevel.miderate: {
        NutritionType.calorie: 2350,
        NutritionType.grains: 4,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 4,
        NutritionType.fruits: 4,
        NutritionType.oils: 6,
      }
    },
    Age.thirteenToFifteen:{
      ActivityLevel.slightlyLow: {
        NutritionType.calorie: 2400,
        NutritionType.grains: 4,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 5,
        NutritionType.fruits: 4,
        NutritionType.oils: 7,
      },
      ActivityLevel.miderate: {
        NutritionType.calorie: 2800,
        NutritionType.grains:4.5,
        NutritionType.meat:8,
        NutritionType.dairy:2,
        NutritionType.vegetables:5,
        NutritionType.fruits:4,
        NutritionType.oils:8,
      },
    },
  },
  Sex.female:{
    Age.zeroToNine:{
      ActivityLevel.slightlyLow: {
        NutritionType.calorie: 1650,
        NutritionType.grains:2.5,
        NutritionType.meat: 4,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 3,
        NutritionType.fruits: 2,
        NutritionType.oils:5,
      },
      ActivityLevel.miderate: {
        NutritionType.calorie: 1900,
        NutritionType.grains: 3,
        NutritionType.meat: 5.5,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 3,
        NutritionType.fruits: 3,
        NutritionType.oils: 5,
      }
    },
    Age.tenToTwelve:{
      ActivityLevel.slightlyLow: {
        NutritionType.calorie: 1950,
        NutritionType.grains: 3,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 3,
        NutritionType.fruits: 3,
        NutritionType.oils: 5,
      },
      ActivityLevel.miderate: {
        NutritionType.calorie: 2250,
        NutritionType.grains: 3.5,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 4,
        NutritionType.fruits: 3.5,
        NutritionType.oils: 6,
      }
    },
    Age.thirteenToFifteen:{
      ActivityLevel.slightlyLow: {
        NutritionType.calorie: 2050,
        NutritionType.grains: 3,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 4,
        NutritionType.fruits: 3,
        NutritionType.oils: 6,
      },
      ActivityLevel.miderate: {
        NutritionType.calorie: 2350,
        NutritionType.grains: 4,
        NutritionType.meat: 6,
        NutritionType.dairy: 1.5,
        NutritionType.vegetables: 4,
        NutritionType.fruits: 4,
        NutritionType.oils: 6,
      },
    },
  },
 };
