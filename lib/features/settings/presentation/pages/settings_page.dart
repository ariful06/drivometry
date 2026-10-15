import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Currency', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const ValueKey('currency-dropdown'),
                value: AppSettings.currencies
                        .any((c) => c.$1 == settings.currencySymbol)
                    ? settings.currencySymbol
                    : null,
                items: [
                  for (final (symbol, label) in AppSettings.currencies)
                    DropdownMenuItem(value: symbol, child: Text(label)),
                ],
                onChanged: (value) {
                  if (value != null) settings.setCurrencySymbol(value);
                },
              ),
              const SizedBox(height: 24),
              Text('Distance', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<DistanceUnit>(
                segments: const [
                  ButtonSegment(
                      value: DistanceUnit.km, label: Text('Kilometres')),
                  ButtonSegment(value: DistanceUnit.mile, label: Text('Miles')),
                ],
                selected: {settings.distanceUnit},
                onSelectionChanged: (value) =>
                    settings.setDistanceUnit(value.first),
              ),
              const SizedBox(height: 24),
              Text('Fuel volume',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<VolumeUnit>(
                segments: const [
                  ButtonSegment(value: VolumeUnit.liter, label: Text('Litres')),
                  ButtonSegment(
                      value: VolumeUnit.gallon, label: Text('Gallons (US)')),
                ],
                selected: {settings.volumeUnit},
                onSelectionChanged: (value) =>
                    settings.setVolumeUnit(value.first),
              ),
              const SizedBox(height: 24),
              Text(
                'Settings apply to every vehicle. Entry forms still take '
                'kilometres and litres; values are converted for display only.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
