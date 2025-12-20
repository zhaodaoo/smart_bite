import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/provider/data_provider.dart';
import 'package:smart_bite/provider/rfid_reader_provider.dart';
import 'package:smart_bite/widgets/setting_page.dart';
import 'package:smart_bite/interfaces/rfid_reader.dart';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

enum Page {
  homePage,
  mealPage,
  activityLevelPage,
  agePage,
  sexPage,
  orderPage,
  confirmPage,
  analyzingPage,
  printingPage,
  initialingPage
}

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
          decoration: _currentPage == Page.homePage
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimaryContainer)
              : const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
          child: Center(
            child: Padding(
              padding: _currentPage == Page.homePage
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
                        _currentPage = Page.confirmPage;
                      });
                    },
                  ),
                Page.confirmPage => ConfirmPage(
                    onGoBack: () {
                      setState(() {
                        _currentPage = Page.activityLevelPage;
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
                        _currentPage = Page.confirmPage;
                      });
                    },
                    onSubmit: () async {
                      setState(() {
                        _currentPage = Page.analyzingPage;
                      });
                      await context.read<DataProvider>().analyze();
                      // Start printing combined PDF (nutrition report + label info)
                      Printing.directPrintPdf(
                          printer: Printer(
                              // ignore: use_build_context_synchronously
                              url: context.read<DataProvider>().printerName),
                          format: PdfPageFormat.a4.landscape,
                          usePrinterSettings: true,
                          onLayout: (format) => context
                              .read<DataProvider>()
                              .generateCombinedPdf(format));
                      // ignore: use_build_context_synchronously
                      await context.read<DataProvider>().saveData();
                      await Future.delayed(const Duration(seconds: 4));

                      setState(() {
                        _currentPage = Page.printingPage;
                      });
                      await Future.delayed(const Duration(seconds: 10));

                      setState(() {
                        // 進入初始化頁面
                        _currentPage = Page.initialingPage;
                      });
                      // ignore: use_build_context_synchronously
                      await context.read<DataProvider>().initialize();
                      await Future.delayed(const Duration(seconds: 4));
                      setState(() {
                        _currentPage = Page.homePage;
                      });
                    },
                  ),
                Page.analyzingPage => const LoadingPage('分析中'),
                Page.printingPage => const LoadingPage('列印中'),
                Page.initialingPage => const LoadingPage('初始化中'),
              },
            ),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingPage()));
        },
        backgroundColor: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: .1),
        child: Icon(
          Icons.settings,
          color: Theme.of(context)
              .colorScheme
              .onPrimaryContainer
              .withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  final String hint;

  const LoadingPage(this.hint, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HeadLine(hint),
        const SizedBox(width: 880, child: LinearProgressIndicator()),
      ],
    );
  }
}

/// Order card widget for displaying detected meal
class _OrderCard extends StatelessWidget {
  final ReaderStatus status;
  final String mealName;
  final double width;

  const _OrderCard({
    required this.status,
    required this.mealName,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        border: Border.all(color: status.color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(status),
                color: status.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              // Text(
              //   status.displayName,
              //   style: TextStyle(
              //     color: status.color,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mealName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ReaderStatus status) {
    switch (status) {
      case ReaderStatus.ok:
        return Icons.check_circle;
      case ReaderStatus.error:
        return Icons.error;
      case ReaderStatus.updating:
        return Icons.refresh;
      case ReaderStatus.init:
        return Icons.radio_button_unchecked;
      case ReaderStatus.disconnected:
        return Icons.cloud_off;
    }
  }
}

/// Refactored OrderPage using RFIDReaderProvider
class OrderPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const OrderPage({
    super.key,
    required this.onGoBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _HeadLine('6.這是您點的餐：'),

        // Meal display section
        Padding(
          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
          child: _buildMealDisplay(context),
        ),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            const SizedBox(width: 61),
            _SubmitButton(
              onPressed: () async {
                await context.read<RFIDReaderProvider>().updateReaders();
              },
              label: '重新感應',
            ),
            const SizedBox(width: 61),
            _SubmitButton(
              onPressed: () {
                // Transfer order data to DataProvider
                final orderNames =
                    context.read<RFIDReaderProvider>().orderNames;
                context.read<DataProvider>().orderNames = orderNames;
                onSubmit();
              },
              label: '分析',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealDisplay(BuildContext context) {
    final isScanning = context.select<RFIDReaderProvider, bool>(
      (provider) => provider.isScanning,
    );

    if (isScanning) {
      return const CircularProgressIndicator.adaptive();
    }

    final orderNames = context.select<RFIDReaderProvider, List<String>>(
      (provider) => provider.orderNames,
    );

    if (orderNames.isEmpty) {
      return const _OrderCard(
        width: 390,
        status: ReaderStatus.init,
        mealName: '沒收到您的點餐，是不知道要吃什麼嗎？可以請服務人員為您推薦！',
      );
    }

    return Wrap(
      spacing: 8,
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: orderNames
          .map((mealName) => _OrderCard(
                status: ReaderStatus.ok,
                mealName: mealName,
              ))
          .toList(),
    );
  }
}

class ConfirmPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const ConfirmPage(
      {super.key, required this.onGoBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _HeadLine('5.資料確認'),
        Padding(
          padding: const EdgeInsets.fromLTRB(180, 0, 180, 0),
          child: Wrap(
              // spacing: 8,
              direction: Axis.horizontal,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: context.select<DataProvider, List<_InfoCard>>((provider) {
                return [
                  _InfoCard(
                      icon: switch (provider.meal) {
                        Meal.breakfast => Icons.breakfast_dining,
                        Meal.lunch => Icons.lunch_dining,
                        Meal.dinnder => Icons.dinner_dining,
                      },
                      title: getMealLabel(provider.meal),
                      subtitle: '這是哪一餐'),
                  _InfoCard(
                      icon: switch (provider.sex) {
                        Sex.female => Icons.female,
                        Sex.male => Icons.male,
                      },
                      title: getSexLabel(provider.sex),
                      subtitle: '性別'),
                  _InfoCard(
                      icon: Icons.numbers,
                      title: getAgeLabel(provider.age),
                      subtitle: '年齡'),
                  _InfoCard(
                      icon: Icons.directions_run,
                      title: getActivityLevelLabel(provider.activityLevel),
                      subtitle: '生活活動強度'),
                ];
              })),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            _SubmitButton(
              onPressed: onSubmit,
              label: '確認',
            )
          ],
        )
      ],
    );
  }
}

class ActivityLevelPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const ActivityLevelPage(
      {super.key, required this.onGoBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    var getActivityChoices =
        context.select<DataProvider, List<Widget>>((provider) {
      int start = 0;
      int end = ActivityLevel.values.length;
      if (provider.age.index < 3) {
        start = 1;
        end = 3;
      } else if (provider.age.index > 6) {
        start = 0;
        end = 3;
      }
      return List<Widget>.generate(
        ActivityLevel.values.length,
        (int index) {
          return _TileChoiceChip(
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
        const _HeadLine('4.活動生活活動強度如何？'),
        Padding(
          padding: const EdgeInsets.fromLTRB(180, 0, 180, 0),
          child: Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: getActivityChoices),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            _SubmitButton(
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
        const _HeadLine('3.請問您幾歲？'),
        Padding(
          padding: const EdgeInsets.fromLTRB(180, 0, 180, 0),
          child: Wrap(
            spacing: 8.0,
            alignment: WrapAlignment.center,
            children: List<Widget>.generate(
              Age.values.length,
              (int index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                  child: _ChoiceChip(
                    label: getAgeLabel(Age.values[index]),
                    selected: context.select<DataProvider, Age>(
                            (provider) => provider.age) ==
                        Age.values[index],
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
            _SubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            _SubmitButton(
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
        const _HeadLine('2.選擇您的性別：'),
        Wrap(
          spacing: 16.0,
          children: List<Widget>.generate(
            Sex.values.length,
            (int index) {
              return _ChoiceChip(
                label: getSexLabel(Sex.values[index]),
                icon: switch (Sex.values[index]) {
                  Sex.female => Icons.female,
                  Sex.male => Icons.male
                },
                selected: context.select<DataProvider, Sex>(
                        (provider) => provider.sex) ==
                    Sex.values[index],
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
            _SubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            _SubmitButton(
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
        const _HeadLine('1.這是哪一餐？'),
        Wrap(
          spacing: 16.0,
          children: List<Widget>.generate(
            Meal.values.length,
            (int index) {
              return _ChoiceChip(
                label: getMealLabel(Meal.values[index]),
                icon: switch (Meal.values[index]) {
                  Meal.breakfast => Icons.breakfast_dining,
                  Meal.lunch => Icons.lunch_dining,
                  Meal.dinnder => Icons.dinner_dining,
                },
                selected: context.select<DataProvider, Meal>(
                        (provider) => provider.meal) ==
                    Meal.values[index],
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
            _SubmitButton(
              onPressed: onGoBack,
              label: '返回',
            ),
            _SubmitButton(
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
        isStart
            ? const SizedBox(width: 880, child: LinearProgressIndicator())
            : const SizedBox(
                height: 4,
              ),
        _SubmitButton(
          onPressed: () async {
            setState(() {
              isStart = true;
            });
            context.read<RFIDReaderProvider>().updateReaders();
            await Future.delayed(const Duration(seconds: 3));
            widget.onSubmit();
          },
          label: '確認',
        )
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final void Function() onPressed;
  final String label;

  const _SubmitButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.displaySmall?.fontSize),
                ),
                // Icon(Icons.send, size: Theme.of(context).textTheme.displaySmall?.fontSize,),
              ]),
        ));
  }
}

class _TileChoiceChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final void Function(bool)? onSelected;

  const _TileChoiceChip(
      {required this.title,
      required this.subtitle,
      required this.selected,
      required this.onSelected});

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
                    fontSize:
                        Theme.of(context).textTheme.headlineLarge!.fontSize),
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

class _ChoiceChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool selected;
  final void Function(bool) onSelected;

  const _ChoiceChip(
      {this.icon, required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Theme.of(context).textTheme.displayMedium!.fontSize,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(label,
                style: TextStyle(
                    fontSize:
                        Theme.of(context).textTheme.displayMedium!.fontSize)),
          ]),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _HeadLine extends StatelessWidget {
  final String text;

  const _HeadLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          fontSize: Theme.of(context).textTheme.displayMedium!.fontSize),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoCard(
      {required this.title, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        child: ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: Theme.of(context).textTheme.displayLarge!.fontSize,
          ),
          title: Text(
            title,
            style: TextStyle(
                fontSize: Theme.of(context).textTheme.headlineLarge!.fontSize),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
          ),
        ),
      ),
    );
  }
}
