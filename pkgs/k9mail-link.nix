{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "k9mail-link";
  version = "unstable-2026-02-25";

  src = fetchFromGitHub {
    owner = "lajp";
    repo = "k9mail-link";
    rev = "3482efa1836de2c37384fadfa9d675cf34134bc7";
    hash = "sha256-XllnpG9nCTG84hvYGJ5o6pO9OtdtlxDfoQQMSh7LPh4=";
  };

  cargoHash = "sha256-LIF3jbDk0QOz34Sio1Uxm4g+W0JaijOlGSPd3aj/lLM=";

  meta = with lib; {
    description = "Telegram bot that rewrites K-9 Mail localhost links";
    homepage = "https://github.com/lajp/k9mail-link";
    mainProgram = "k9mail-link";
    platforms = platforms.linux;
  };
}
