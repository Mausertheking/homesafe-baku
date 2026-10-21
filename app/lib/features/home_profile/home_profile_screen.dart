import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/content_strings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'home_profile.dart';

/// Home profile setup. A single scrolling form (it is filled once) with
/// large choice chips; every value is a stable id, never translated text.
class HomeProfileScreen extends ConsumerStatefulWidget {
  const HomeProfileScreen({super.key});

  @override
  ConsumerState<HomeProfileScreen> createState() => _HomeProfileScreenState();
}

class _HomeProfileScreenState extends ConsumerState<HomeProfileScreen> {
  late HomeProfile _p = ref.read(homeProfileProvider);

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // A renter who later becomes an owner should not keep a contract answer.
    final profile = _p.role == 'owner'
        ? HomeProfile.fromJson({..._p.toJson(), 'hasWrittenContract': null})
        : _p;
    await ref.read(homeProfileProvider.notifier).save(profile);
    messenger.showSnackBar(SnackBar(content: Text(l.profileSaved)));
    if (mounted) context.canPop() ? context.pop() : context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = ref.watch(contentStringsProvider);

    Widget group<T>(String title, T? value, List<(T, String)> options, void Function(T) onSelect) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (v, label) in options)
              ChoiceChip(
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(label, style: const TextStyle(fontSize: 16)),
                ),
                selected: value == v,
                onSelected: (_) => setState(() => onSelect(v)),
              ),
          ]),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: PageBody(children: [
          Text(l.profileIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          group(l.profileRole, _p.role, [('renter', l.roleRenter), ('owner', l.roleOwner)],
              (v) => _p = _p.copyWith(role: v)),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: DropdownButtonFormField<String>(
              initialValue: _p.district,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.profileDistrict),
              items: [
                for (final d in HomeProfile.districts)
                  DropdownMenuItem(value: d, child: Text(t('district.$d'), style: const TextStyle(fontSize: 18))),
              ],
              onChanged: (v) => setState(() => _p = _p.copyWith(district: v)),
            ),
          ),
          group(l.profileBuildingAge, _p.buildingAgeBand, [
            ('before_1960', l.ageBefore1960),
            ('1960_1990', l.age1960to1990),
            ('1991_2010', l.age1991to2010),
            ('after_2010', l.ageAfter2010),
            ('not_sure', l.notSure),
          ], (v) => _p = _p.copyWith(buildingAgeBand: v)),
          group(l.profileHeating, _p.heatingType, [
            ('individual_gas_heater', l.heatingIndividualGas),
            ('gas_boiler', l.heatingGasBoiler),
            ('central_heating', l.heatingCentral),
            ('electric', l.heatingElectric),
            ('other', l.heatingOther),
          ], (v) => _p = _p.copyWith(heatingType: v)),
          group(l.profileWaterHeater, _p.heaterLocation, [
            ('bathroom', l.waterHeaterBathroom),
            ('kitchen', l.waterHeaterKitchen),
            ('other', l.waterHeaterOther),
            ('none', l.waterHeaterNone),
          ], (v) => _p = _p.copyWith(heaterLocation: v)),
          group(l.profileCoAlarm, _p.hasCoAlarm, [
            ('yes', l.yes),
            ('no', l.no),
            ('not_sure', l.notSure),
          ], (v) => _p = _p.copyWith(hasCoAlarm: v)),
          if (_p.role == 'renter')
            group(l.profileContract, _p.hasWrittenContract, [(true, l.yes), (false, l.no)],
                (v) => _p = _p.copyWith(hasWrittenContract: v)),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ]),
      ),
    );
  }
}
