/// Build-time switch that replaces every wallet call with a logged no-op.
///
/// Enable with `--dart-define=ZAPCLOCK_DRY_RUN_PAYMENTS=true` when exercising
/// the zap path on a device or emulator without moving sats. Off by default
/// and never read from runtime state, so a release build cannot flip it.
const bool kDryRunPayments = bool.fromEnvironment(
  'ZAPCLOCK_DRY_RUN_PAYMENTS',
  defaultValue: false,
);
