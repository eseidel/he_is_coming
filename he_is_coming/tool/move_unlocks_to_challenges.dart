import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void doMain(List<String> arguments) {
  final data = Data.load();

  final challenges = <Challenge>[];
  final items = [
    ...data.items.items,
    ...data.edges.items,
  ];
  for (final item in items) {
    final unlock = item.unlock;
    if (unlock == null) continue;

    final parts = unlock.split(': ');
    if (parts.length != 2) {
      logger.warn('Invalid unlock: $unlock');
      continue;
    }
    final name = parts[0];
    final condition = parts[1];
    final challenge = Challenge(
      name: name,
      unlock: condition,
      reward: item.name,
    );
    challenges.add(challenge);
  }
  // Convert unlocks into challenges.
  data.challenges.items.addAll(challenges);
  data.save();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
