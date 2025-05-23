
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_bite/provider/data_provider.dart';
import 'package:smart_bite/provider/serial_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    var serialPortsProvider = context.watch<SerialPortsProvider>();
    var getSerialStatusCards = context.select<SerialPortsProvider, List<SerialStatusCard>>(
      (provider) {
        return List<SerialStatusCard>.generate(
          provider.availablePorts.length,
          (index) => SerialStatusCard(
            status: provider.availablePorts[index].status,
            address: provider.availablePorts[index].address, 
            deviceId: provider.availablePorts[index].deviceId, 
          ),
        );
      }
    );

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Settings', style: Theme.of(context).textTheme.headlineLarge)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text('Serial Ports Reading Time', style: Theme.of(context).textTheme.titleMedium),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                        child: Slider(
                          value: serialPortsProvider.loadingTime,
                          max: 20,
                          min: 3,
                          divisions: 17,
                          label: serialPortsProvider.loadingTime.round().toString(),
                          onChanged: (double value) {
                              serialPortsProvider.loadingTime = value;
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Serial Ports Status', style: Theme.of(context).textTheme.titleMedium),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                          child: Wrap(
                            spacing: 5,
                            children: getSerialStatusCards,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: FilledButton.icon(
                      onPressed: ()async => await serialPortsProvider.updatePorts(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh"),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextFormField(
                      initialValue: context.read<DataProvider>().printerName,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Printer Name',
                      ),
                      onFieldSubmitted:(value) {
                        context.read<DataProvider>().printerName = value;
                        debugPrint('Printer Name = ${context.read<DataProvider>().printerName}');
                      },
                    ),
                    Text('Current Printer Name: ${context.select<DataProvider, String>((provider) => provider.printerName)}'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: FilledButton.icon(
                        onPressed: () async{
                          await Printing.directPrintPdf ( 
                            printer: Printer(url: context.read<DataProvider>().printerName), 
                            format: PdfPageFormat.a4.landscape,
                            onLayout: (format) => context.read<DataProvider>().generatePdf(format)
                          );
                        },
                        icon: const Icon(Icons.print),
                        label: const Text("Print Test Page"),
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    //   child: FilledButton.icon(
                    //     onPressed: ()async => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingPage())),
                    //     icon: const Icon(Icons.print),
                    //     label: const Text("Printing Preview"),
                    //   ),
                    // )
                  ],
                ),
              )
            )
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: ()async => await serialPortsProvider.updatePorts(),
      //   child: const Icon(Icons.refresh),
      // ),
    );
  }
}

class SerialStatusCard extends StatelessWidget {
  final String address, deviceId;
  final PortStatus status;
  
  const SerialStatusCard({super.key, required this.status, required this.address, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
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
              title: Text(deviceId),
              subtitle: Text(address),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: status==PortStatus.updating? const LinearProgressIndicator():const LinearProgressIndicator(value: 0),
            ),
          ],
        ),
      ),
    );
  }
}
