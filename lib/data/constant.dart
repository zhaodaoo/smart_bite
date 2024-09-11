enum Meal {breakfast, lunch, dinnder}
enum ActivityLevel {low, slightlyLow, miderate, high}
enum Sex {female, male}
enum Age {zeroToNine, tenToTwelve, thirteenToFifteen, sixteenToEighteen, ninteenToThirty, thirtyOneToFifty, fiftyOneToSeventy, seventyOneToOneTwelve}
enum NutritionType {grains, meat, dairy, vegetables, fruits, oils, calorie, carb, protein, fat, na, ca, fiber}
enum Rank {good, tooMuch, tooLess}

const Map<Meal,double> mealProportion = {
  Meal.breakfast: 0.2,
  Meal.lunch: 0.4,
  Meal.dinnder: 0.4,
};

String getMealLabel (Meal value) {
    return switch (value) {
      Meal.breakfast => '早餐',
      Meal.lunch => '午餐',
      Meal.dinnder => '晚餐',
    };
  }

  String getActivityLevelLabel (ActivityLevel value) {
    return switch (value)  {
      ActivityLevel.low => '低',
      ActivityLevel.slightlyLow => '稍低',
      ActivityLevel.miderate => '適度',
      ActivityLevel.high => '高',
    };
  }

  String getSexLabel (Sex value) {
    return switch (value) {
      Sex.female => '女',
      Sex.male => '男',
    };
  }

  String getAgeLabel (Age value) {
    return switch (value) {
      Age.zeroToNine =>'0-9',
      Age.tenToTwelve =>'10-12',
      Age.thirteenToFifteen => '13-15',
      Age.sixteenToEighteen => '16-18',
      Age.ninteenToThirty => '19-30',
      Age.thirtyOneToFifty =>'31-50',
      Age.fiftyOneToSeventy => '51-70',
      Age.seventyOneToOneTwelve =>'71-120',
    };
  }
