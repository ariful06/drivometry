import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/rental_entry.dart';
import '../cubits/rental_cubit.dart';

Future<void> showRentalBillingUpdateDialog(
  BuildContext context,
  RentalEntry entry,
) async {
  final rentalCubit = context.read<RentalCubit>();
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (bottomSheetContext) {
      return BlocProvider.value(
        value: rentalCubit,
        child: _RentalTripBillingSheet(
          entry: entry,
          scaffoldMessenger: scaffoldMessenger,
        ),
      );
    },
  );
}

class _RentalTripBillingSheet extends StatefulWidget {
  const _RentalTripBillingSheet({
    required this.entry,
    required this.scaffoldMessenger,
  });

  final RentalEntry entry;
  final ScaffoldMessengerState scaffoldMessenger;

  @override
  State<_RentalTripBillingSheet> createState() =>
      _RentalTripBillingSheetState();
}

class _RentalTripBillingSheetState extends State<_RentalTripBillingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fareCtrl;
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _partialPaymentCtrl;
  late String _paymentStatus;
  late _TripCompletionChoice _tripCompletionChoice;
  bool _submitting = false;

  static const _paymentOptions = ['Paid', 'Partial', 'Due'];

  RentalEntry get _entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _fareCtrl = TextEditingController(text: _entry.rentFareAmount.toString());
    _distanceCtrl =
        TextEditingController(text: _entry.totalKm.toStringAsFixed(1));
    _partialPaymentCtrl = TextEditingController();
    _paymentStatus = _entry.paymentStatus;
    if (!_paymentOptions.contains(_paymentStatus)) {
      _paymentStatus = 'Due';
    }
    final now = DateTime.now();
    final tripEndIsInFuture = now.isBefore(_entry.endDateTime);
    _tripCompletionChoice = tripEndIsInFuture
        ? _TripCompletionChoice.ongoing
        : _TripCompletionChoice.finished;
  }

  @override
  void dispose() {
    _fareCtrl.dispose();
    _distanceCtrl.dispose();
    _partialPaymentCtrl.dispose();
    super.dispose();
  }

  double get _fare => double.tryParse(_fareCtrl.text.trim()) ?? 0;
  double get _distanceKm => double.tryParse(_distanceCtrl.text.trim()) ?? 0;

  double get _partialPaymentEntered {
    final parsed = double.tryParse(_partialPaymentCtrl.text.trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  double get _billablePreview => RentalEntry.billableTripAmount(
        rentFareAmount: _fare,
        fuelCost: _entry.fuelCost,
        customerPaidFuelBill: _entry.customerPaidFuelBill,
      );

  double get _advanceAfterSave {
    switch (_paymentStatus) {
      case 'Paid':
        return _billablePreview;
      case 'Partial':
        return _entry.advanceReceived + _partialPaymentEntered;
      case 'Due':
      default:
        return _entry.advanceReceived;
    }
  }

  double get _duePreview {
    if (_paymentStatus == 'Paid') return 0;
    return RentalEntry.computeDue(
      rentFareAmount: _fare,
      advanceReceived: _advanceAfterSave,
      fuelCost: _entry.fuelCost,
      customerPaidFuelBill: _entry.customerPaidFuelBill,
    ).clamp(0.0, double.infinity);
  }

  bool get _markTripCompletedOnSave {
    final now = DateTime.now();
    final tripEndIsInFuture = now.isBefore(_entry.endDateTime);
    return tripEndIsInFuture &&
        _tripCompletionChoice == _TripCompletionChoice.finished;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentStatus == 'Partial') {
      final raw = _partialPaymentCtrl.text.trim();
      if (raw.isNotEmpty && double.tryParse(raw) == null) {
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      await context.read<RentalCubit>().updateRentalFareDistanceAndPayment(
            entry: _entry,
            rentFareAmount: _fare,
            tripDistanceKm: _distanceKm,
            paymentStatusSelection: _paymentStatus,
            partialPaymentAmount:
                _paymentStatus == 'Partial' ? _partialPaymentEntered : 0,
            markTripCompleted: _markTripCompletedOnSave,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Rental updated')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      widget.scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Could not save: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final now = DateTime.now();
    final tripEndIsInFuture = now.isBefore(_entry.endDateTime);
    final existingAdvance = _entry.advanceReceived;
    final hasExistingAdvance = existingAdvance > 0;
    final remainingColor = _duePreview <= 0 ? colors.success : colors.warning;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return PopScope(
      canPop: !_submitting,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SizedBox(
          height: screenHeight,
          child: DraggableScrollableSheet(
            expand: true,
            initialChildSize: 0.58,
            minChildSize: 0.48,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.58, 1.0],
            builder:
                (BuildContext sheetContext, ScrollController scrollController) {
              return Material(
                color: colors.cardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trip billing',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _entry.customerName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            sliver: SliverToBoxAdapter(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Rental status',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (tripEndIsInFuture)
                                      SegmentedButton<_TripCompletionChoice>(
                                        segments: const [
                                          ButtonSegment(
                                            value:
                                                _TripCompletionChoice.ongoing,
                                            label: Text('Ongoing'),
                                            icon: Icon(Icons.schedule_outlined,
                                                size: 18),
                                          ),
                                          ButtonSegment(
                                            value:
                                                _TripCompletionChoice.finished,
                                            label: Text('Completed'),
                                            icon: Icon(Icons.flag_outlined,
                                                size: 18),
                                          ),
                                        ],
                                        selected: {_tripCompletionChoice},
                                        emptySelectionAllowed: false,
                                        showSelectedIcon: false,
                                        onSelectionChanged: _submitting
                                            ? null
                                            : (Set<_TripCompletionChoice>
                                                selected) {
                                                setState(() {
                                                  _tripCompletionChoice =
                                                      selected.first;
                                                });
                                              },
                                      )
                                    else
                                      _ReadOnlyFieldCard(
                                        label: 'Trip',
                                        value:
                                            'Completed (end time already passed)',
                                        valueColor: colors.textSecondary,
                                        icon: Icons.flag_outlined,
                                      ),
                                    if (tripEndIsInFuture &&
                                        _tripCompletionChoice ==
                                            _TripCompletionChoice.finished)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'On save, end time will be set to now.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _fareCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Fare rate',
                                        prefixIcon:
                                            Icon(Icons.payments_outlined),
                                      ),
                                      validator: (String? rawText) {
                                        if (rawText == null ||
                                            rawText.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        final parsedFare =
                                            double.tryParse(rawText);
                                        if (parsedFare == null ||
                                            parsedFare < 0) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                      onChanged: (String? newText) =>
                                          setState(() {}),
                                    ),
                                    const SizedBox(height: 12),
                                    _ReadOnlyFieldCard(
                                      label: 'Advance received (to date)',
                                      value: hasExistingAdvance
                                          ? Formatters.formatCurrency(
                                              existingAdvance)
                                          : 'None yet',
                                      valueColor: hasExistingAdvance
                                          ? colors.success
                                          : colors.textSecondary,
                                      icon: Icons.savings_outlined,
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      // ignore: deprecated_member_use
                                      value: _paymentStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'Payment status',
                                        prefixIcon: Icon(Icons
                                            .account_balance_wallet_outlined),
                                      ),
                                      items: _paymentOptions
                                          .map(
                                            (String option) =>
                                                DropdownMenuItem<String>(
                                              value: option,
                                              child: Text(option),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _submitting
                                          ? null
                                          : (String? selected) {
                                              if (selected == null) return;
                                              setState(() =>
                                                  _paymentStatus = selected);
                                            },
                                    ),
                                    if (_paymentStatus == 'Paid') ...[
                                      const SizedBox(height: 8),
                                      _InfoBanner(
                                        message:
                                            'Remaining due will be cleared. Total collected will match '
                                            'the billable fare (${Formatters.formatCurrency(_billablePreview)}).',
                                        colors: colors,
                                      ),
                                    ],
                                    if (_paymentStatus == 'Partial') ...[
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _partialPaymentCtrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Amount received now',
                                          hintText: '0',
                                          helperText:
                                              'Added to advance. Remaining stays tied to billable fare '
                                              '(${Formatters.formatCurrency(_billablePreview)}).',
                                          prefixIcon: const Icon(
                                              Icons.point_of_sale_outlined),
                                        ),
                                        validator: (String? rawText) {
                                          if (rawText == null ||
                                              rawText.trim().isEmpty) {
                                            return null;
                                          }
                                          final parsedPayment =
                                              double.tryParse(rawText);
                                          if (parsedPayment == null ||
                                              parsedPayment < 0) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                        onChanged: (String? newText) =>
                                            setState(() {}),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _distanceCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Trip distance (km)',
                                        prefixIcon:
                                            Icon(Icons.straighten_outlined),
                                        helperText:
                                            'End odometer = start KM + distance.',
                                      ),
                                      validator: (String? rawText) {
                                        if (rawText == null ||
                                            rawText.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        final parsedDistanceKm =
                                            double.tryParse(rawText);
                                        if (parsedDistanceKm == null ||
                                            parsedDistanceKm < 0) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                      onChanged: (String? newText) =>
                                          setState(() {}),
                                    ),
                                    const SizedBox(height: 16),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.surfaceContainerHighest
                                            .withValues(
                                          alpha: theme.brightness ==
                                                  Brightness.dark
                                              ? 0.35
                                              : 0.65,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              'Summary',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            if (_entry.customerPaidFuelBill &&
                                                _entry.fuelCost > 0)
                                              _SettlementLine(
                                                label:
                                                    'Fuel credited (customer paid)',
                                                value:
                                                    '- ${Formatters.formatCurrency(_entry.fuelCost)}',
                                                valueColor:
                                                    colors.textSecondary,
                                              ),
                                            _SettlementLine(
                                              label: 'Billable trip',
                                              value: Formatters.formatCurrency(
                                                  _billablePreview),
                                              valueColor:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            _SettlementLine(
                                              label: 'Payment status',
                                              value: _paymentStatus,
                                              valueColor:
                                                  theme.colorScheme.primary,
                                            ),
                                            const SizedBox(height: 6),
                                            _SettlementLine(
                                              label:
                                                  'Total advance (after save)',
                                              value: Formatters.formatCurrency(
                                                  _advanceAfterSave),
                                              valueColor: colors.success,
                                            ),
                                            const SizedBox(height: 10),
                                            Divider(
                                              height: 1,
                                              color: colors.divider
                                                  .withValues(alpha: 0.8),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Remaining due',
                                                    style: theme
                                                        .textTheme.titleSmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  Formatters.formatCurrency(
                                                      _duePreview),
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: remainingColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 88 + bottomSafe),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: colors.divider.withValues(alpha: 0.7)),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              child: const Text('Cancel'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 20),
                              label: Text(
                                  _submitting ? 'Saving…' : 'Save changes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _TripCompletionChoice { ongoing, finished }

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.colors});

  final String message;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.success.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20, color: colors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyFieldCard extends StatelessWidget {
  const _ReadOnlyFieldCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.25 : 0.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: Text(
        value,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: valueColor,
        ),
      ),
    );
  }
}

class _SettlementLine extends StatelessWidget {
  const _SettlementLine({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.extension<AppColors>()!.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
