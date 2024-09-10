import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/data/id_to_meal.dart';
import 'package:smart_bite/provider/data_provider.dart';
import 'package:smart_bite/provider/serial_provider.dart';

enum Page {homePage, mealPage, activityLevelPage, agePage, sexPage, orderPage, confirmPage}

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState(); 
}

class _InputScreenState extends State<InputScreen> {
  late Page _currentPage = Page.homePage;
  
  @override
  void initState() {
    super.initState();
    _currentPage = Page.homePage;
  }

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage('assets/images/background.png'), context);
    return Scaffold(
      body: Container(
        decoration: _currentPage==Page.homePage
        ? BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimaryContainer
        )
        : const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding:  _currentPage == Page.homePage
            ? const EdgeInsets.fromLTRB(102, 120, 108, 80)
            : const EdgeInsets.fromLTRB(102, 160, 108, 152),
            child: switch (_currentPage) {
              Page.homePage => HomePage(
                onSubmit: () {
                  setState(() {
                    _currentPage = Page.mealPage;
                  });
                },
              ),
              Page.mealPage => MealPage(
                onGoBack: () {
                  setState(() {
                    _currentPage = Page.homePage;
                  });
                },
                onSubmit: () {
                  setState(() {
                    _currentPage = Page.sexPage;
                  });
                },
              ),
              Page.sexPage => SexPage(
                onGoBack: () {
                  setState(() {
                    _currentPage = Page.mealPage;
                  });
                },
                onSubmit: () {
                  setState(() {
                    _currentPage = Page.agePage;
                  });
                },
              ),
              Page.agePage => AgePage(
                onGoBack: () {
                  setState(() {
                    _currentPage = Page.sexPage;
                  });
                },
                onSubmit: () {
                  setState(() {
                    _currentPage = Page.activityLevelPage;
                  });
                },
              ),
              Page.activityLevelPage => ActivityLevelPage(
                onGoBack: () {
                  setState(() {
                    _currentPage = Page.agePage;
                  });
                },
                onSubmit: () {
                  setState(() {
                    _currentPage = Page.orderPage;
                  });
                },
              ),
              Page.orderPage => OrderPage(
                onGoBack: () {
                  setState(() {
                    _currentPage = Page.activityLevelPage;
                  });
                },
                onSubmit: () {
                  setState(() {
                    _currentPage = Page.confirmPage;
                  });
                },
              ),
              Page.confirmPage => ConfirmPage(
                onGoBack: () {
                  setState(() {
                    _currentPage = Page.orderPage;
                  });
                },
                onSubmit: () {
                  
                },
              )
            },
          ),
        )
      ),
    );
  }
}

class ConfirmPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;
  
  const ConfirmPage({super.key, required this.onGoBack, required this.onSubmit});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MyHeadLine('資料確認'),
        Wrap(
          // spacing: 8,
          direction: Axis.horizontal,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: context.select<DataProvider, List<InfoCard>>(
            (provider) {
              return [
                InfoCard(
                  icon: switch (provider.meal) {
                    Meal.breakfast => Icons.breakfast_dining,
                    Meal.lunch => Icons.lunch_dining,
                    Meal.dinnder => Icons.dinner_dining,
                  },
                  title: provider.mealLabel, 
                  subtitle: '這是哪一餐'
                ),
                InfoCard(
                  icon: switch (provider.sex) {
                    Sex.female => Icons.female,
                    Sex.male => Icons.male,
                  },
                  title: provider.sexLabel, 
                  subtitle: '性別'
                ),
                InfoCard(
                  icon: Icons.numbers,
                  title: provider.ageLabel, 
                  subtitle: '年齡'
                ),
                InfoCard(
                  icon: Icons.directions_run,
                  title: provider.activityLevelLabel, 
                  subtitle: '生活活動強度'
                ),
              ];
            }
          )
        ),
        context.select<DataProvider, Widget>(
          (provider) {
            return provider.orderNames.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
                child: Wrap(
                  spacing: 8,
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: List<OrderCard>.generate(
                    provider.orderNames.length, 
                    (index) {
                      return OrderCard(status: PortStatus.ok, mealName: provider.orderNames[index]);
                    }
                  )
                ),
              )
            : const OrderCard(width: 400, status: PortStatus.init, mealName: '沒收到你的點餐，難道...吃空氣？');
          }
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MySubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            MySubmitButton(
              onPressed: onSubmit,
              label: '確認',
            )
          ],
        )
      ],
    );
  }
  
}

class OrderPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const OrderPage({super.key, required this.onGoBack, required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    List<OrderCard> getSerialStatusCards = context.select<SerialPortsProvider, List<OrderCard>>(
      (provider) {
        provider.orderNames.clear();
        List<MySerialPort> availableRFID = provider.availablePorts.toList();
        return availableRFID.isNotEmpty
        ? List<OrderCard>.generate(
          availableRFID.length,
          (index) {
            debugPrint('Processing Widget DeviceID=${availableRFID[index].deviceId}');
            String mealId = availableRFID[index].rfid;
            String mealName = idToMealName.containsKey(mealId)? idToMealName[mealId] ?? '黑暗料理' : '未知料理';
            provider.orderNames.add(mealName);
            debugPrint('RFID is not empty so a OderCard is returned.');
            return OrderCard(
              status: availableRFID[index].status,
              mealName: mealName,
            );
          } 
        )
        : [const OrderCard(width: 390, status: PortStatus.init, mealName: '沒收到您的點餐，是不知道要吃什麼嗎？可以請服務人員為您推薦！')];
      }
    );
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MyHeadLine('5.這是您點的餐：'),
        Padding(
          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
          child: context.select<SerialPortsProvider, bool>((provider) => provider.availablePorts.every((port)=>port.status!=PortStatus.updating))
          ? Wrap(
            spacing: 8,
            direction: Axis.horizontal,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: getSerialStatusCards,
          )
          : const CircularProgressIndicator.adaptive(),
        ),
        
        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MySubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            const SizedBox(width: 22,),
            MySubmitButton(
              onPressed: ()async => await context.read<SerialPortsProvider>().updatePorts(),
              label: '重新感應',
            ),
            const SizedBox(width: 22,),
            MySubmitButton(
              onPressed: () {
                context.read<DataProvider>().orderNames = context.read<SerialPortsProvider>().orderNames;
                onSubmit();
              },
              label: '確認',
            )
          ],
        )
      ]
    );
  }
}

class ActivityLevelPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const ActivityLevelPage({super.key, required this.onGoBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    var getActivityChoices = context.select<DataProvider, List<Widget>>((provider) {
      int start = 0;
      int end = ActivityLevel.values.length;
      if (provider.age.index < 3){
        start = 1;
        end = 3;
      } else if (provider.age.index > 6){
        start = 0;
        end = 3;
      } 
      return List<Widget>.generate(
        ActivityLevel.values.length,
        (int index) {
          return MyTileChoiceChip(
            title: getActivityLevelLabel(ActivityLevel.values[index]),
            subtitle: switch (ActivityLevel.values[index]) {
              ActivityLevel.low => '靜態活動，多半坐著或躺著。',
              ActivityLevel.slightlyLow => '站立活動，多半站著但少移動身體。',
              ActivityLevel.miderate => '站立且移動的活動，如打掃、散步等。',
              ActivityLevel.high => '比一般速度更快的活動，如爬樓梯、快走等。',
            },
            selected: provider.activityLevel == ActivityLevel.values[index],
            onSelected: (bool selected) {
              if (selected) {
                provider.activityLevel = ActivityLevel.values[index];
              }
            },
          );
        },
      ).toList().sublist(start, end);
    });

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MyHeadLine('4.活動生活活動強度如何？'),
        Wrap(
          spacing: 8.0,
          alignment: WrapAlignment.center,
          children: getActivityChoices
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MySubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            MySubmitButton(
              onPressed: onSubmit,
              label: '確認',
            )
          ],
        )
      
      ],
    );
  }
}

class AgePage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const AgePage({super.key, required this.onGoBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    var dataProvider = context.read<DataProvider>();
    
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MyHeadLine('3.請問您幾歲？'),
        Padding(
          padding: const EdgeInsets.fromLTRB(240, 0, 240, 0),
          child: Wrap(
            spacing: 8.0,
            alignment: WrapAlignment.spaceBetween,
            children:  List<Widget>.generate(
              Age.values.length,
              (int index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                  child: MyChoiceChip(
                    label: getAgeLabel(Age.values[index]),
                    selected: context.select<DataProvider, Age>((provider) => provider.age) == Age.values[index],
                    onSelected: (bool selected) {
                      if (selected) {
                        dataProvider.age = Age.values[index];
                      }
                    },
                  ),
                );
              },
            ).toList(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MySubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            MySubmitButton(
              onPressed: () {
                dataProvider.activityLevel = ActivityLevel.miderate;
                onSubmit();
              },
              label: '確認',
            )
          ],
        )
      ],
    );
  }
}

class SexPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const SexPage({super.key, required this.onGoBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MyHeadLine('2.選擇您的性別：'),
        Wrap(
          spacing: 16.0,
          children:  List<Widget>.generate(
            Sex.values.length,
            (int index) {
              return MyChoiceChip(
                label: getSexLabel(Sex.values[index]),
                icon: switch (Sex.values[index]) {
                  Sex.female => Icons.female,
                  Sex.male => Icons.male
                },
                selected: context.select<DataProvider, Sex>((provider) => provider.sex) == Sex.values[index],
                onSelected: (bool selected) {
                  if (selected) {
                    context.read<DataProvider>().sex = Sex.values[index];
                  }
                },
              );
            },
          ).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MySubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            MySubmitButton(
              onPressed: onSubmit,
              label: '確認',
            )
          ],
        )
      ],
    );
  }
}

class MealPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const MealPage({super.key, required this.onGoBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MyHeadLine('1.這是哪一餐？'),
        Wrap(
          spacing: 16.0,
          children:  List<Widget>.generate(
            Meal.values.length,
            (int index) {
              return MyChoiceChip(
                label: getMealLabel(Meal.values[index]),
                icon: switch (Meal.values[index]) {
                  Meal.breakfast => Icons.breakfast_dining,
                  Meal.lunch => Icons.lunch_dining,
                  Meal.dinnder => Icons.dinner_dining,
                },
                selected: context.select<DataProvider, Meal>((provider) => provider.meal) == Meal.values[index],
                onSelected: (bool selected) {
                  if (selected) {
                    context.read<DataProvider>().meal = Meal.values[index];
                  }
                },
              );
            },
          ).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MySubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            MySubmitButton(
              onPressed: onSubmit,
              label: '確認',
            )
          ],
        )
      
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function() onSubmit;

  const HomePage({super.key, required this.onSubmit});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isStart = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(80, 0, 80, 0),
          child: Image(image: AssetImage('assets/images/title.png')),
        ),
        isStart? const SizedBox(width: 880, child: LinearProgressIndicator()): const SizedBox(height: 4,),
        MySubmitButton(
          onPressed: () async{
            setState(() {
              isStart = true;
            });
            context.read<SerialPortsProvider>().updatePorts();
            await Future.delayed(const Duration(seconds: 1));
            widget.onSubmit();
          },
          label: '確認',
        )
      ],
    );
  }
}

class MySubmitButton extends StatelessWidget {
  final void Function() onPressed;
  final String label;

  const MySubmitButton({super.key, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed, 
      iconAlignment: IconAlignment.end,
      child:
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children:[
            Text(label, style: TextStyle(fontSize: Theme.of(context).textTheme.displaySmall?.fontSize),),
            // Icon(Icons.send, size: Theme.of(context).textTheme.displaySmall?.fontSize,),
          ]
        ),
      )  
    );
  }
  
}

class MyTileChoiceChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final void Function(bool)? onSelected;

  const MyTileChoiceChip({super.key, required this.title, required this.subtitle, required this.selected, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: ChoiceChip(
        label: SizedBox(
          width: 320,
          height: 64,
          child: Center(
            child: ListTile(
              leading: Text(
                title,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.headlineLarge!.fontSize
                ),
              ),
              title: Text(subtitle),
            ),
          ),
        ),
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }
}

class MyChoiceChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool selected;
  final void Function(bool)? onSelected;

  const MyChoiceChip({super.key, this.icon, required this.label, required this.selected, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: icon == null
        ? [
          Text(
            label, 
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.displaySmall!.fontSize
            )
          ),
        ]
        : [
          Icon(icon, size: Theme.of(context).textTheme.displayMedium!.fontSize,),
          const SizedBox(width: 8,),
          Text(
            label, 
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.displayMedium!.fontSize
            )
          ),
        ]
      ),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class MyHeadLine extends StatelessWidget {
  final String text;

  const MyHeadLine(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: Theme.of(context).textTheme.displayMedium!.fontSize
      ),
    );
  }
  
}

class MyInfo extends StatelessWidget {
  final String text;

  const MyInfo(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: Theme.of(context).textTheme.displaySmall!.fontSize
      ),
    );
  }
  
}

class OrderCard extends StatelessWidget {
  final String mealName;
  final PortStatus status;
  final double? width;
  
  const OrderCard({super.key, required this.status, required this.mealName, this.width});

  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 280,
      child: Card(
        child: ListTile(
          leading: switch (status) {
            PortStatus.updating => Icon(
              Icons.change_circle_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            PortStatus.init => Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            PortStatus.ok => const Icon(
              Icons.check_circle_outline, 
              color: Colors.green
            ),
            PortStatus.error => Icon(
              Icons.highlight_off,
              color: Theme.of(context).colorScheme.error,
            ),
          },
          title: Text(
            mealName,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize
            ),
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const InfoCard({super.key, required this.title, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 213,
      child: Card(
        child: ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: Theme.of(context).textTheme.displaySmall!.fontSize,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.titleLarge!.fontSize
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize
            ),
          ),
        ),
      ),
    );
  }
}
