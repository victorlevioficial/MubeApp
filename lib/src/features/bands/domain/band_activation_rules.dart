/// Keep this file in sync with `functions/src/band_activation.ts`.
const int minimumBandMembersForActivation = 2;

/// Shared public status used by band onboarding and visibility rules.
const String profileDraftStatus = 'rascunho';

/// Default public status for concluded profiles that can appear in the app.
const String profileActiveStatus = 'ativo';

bool isBandEligibleForActivation(int acceptedMembers) {
  return acceptedMembers >= minimumBandMembersForActivation;
}

int missingBandMembersForActivation(int acceptedMembers) {
  final missing = minimumBandMembersForActivation - acceptedMembers;
  return missing > 0 ? missing : 0;
}
