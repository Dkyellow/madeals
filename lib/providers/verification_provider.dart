import 'package:flutter_riverpod/flutter_riverpod.dart';

enum IdVerificationState { notStarted, uploading, pendingReview, verified }
enum SelfieVerificationState { locked, inProgress, verified }

class VerificationState {
  final bool isPhoneConfirmed;
  final IdVerificationState idState;
  final SelfieVerificationState selfieState;
  final String? uploadedIdPath;
  final int trustScore;

  const VerificationState({
    this.isPhoneConfirmed = true,
    this.idState = IdVerificationState.notStarted,
    this.selfieState = SelfieVerificationState.locked,
    this.uploadedIdPath,
    this.trustScore = 55,
  });

  VerificationState copyWith({
    bool? isPhoneConfirmed,
    IdVerificationState? idState,
    SelfieVerificationState? selfieState,
    String? uploadedIdPath,
    int? trustScore,
  }) {
    return VerificationState(
      isPhoneConfirmed: isPhoneConfirmed ?? this.isPhoneConfirmed,
      idState: idState ?? this.idState,
      selfieState: selfieState ?? this.selfieState,
      uploadedIdPath: uploadedIdPath ?? this.uploadedIdPath,
      trustScore: trustScore ?? this.trustScore,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  VerificationNotifier() : super(const VerificationState());

  void setPhoneConfirmed(bool confirmed) {
    state = state.copyWith(
      isPhoneConfirmed: confirmed,
      trustScore: confirmed ? 55 : 20,
    );
  }

  void startIdUpload() {
    state = state.copyWith(idState: IdVerificationState.uploading);
  }

  void completeIdUpload(String mockPath) {
    state = state.copyWith(
      idState: IdVerificationState.pendingReview,
      selfieState: SelfieVerificationState.inProgress,
      uploadedIdPath: mockPath,
      trustScore: 82,
    );
  }

  void completeSelfieVerification() {
    state = state.copyWith(
      idState: IdVerificationState.verified,
      selfieState: SelfieVerificationState.verified,
      trustScore: 98,
    );
  }
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier();
});
