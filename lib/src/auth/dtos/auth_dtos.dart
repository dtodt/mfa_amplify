//
typedef SignInRequestDTO = ({
  String username,
  String password,
});

typedef SignInResponseDTO = ({
  bool mfaEnabled,
  bool signedIn,
});

typedef FetchResponseDTO = ({
  bool mfaEnabled,
  String accessToken,
});
