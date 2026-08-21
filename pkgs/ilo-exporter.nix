{ buildGoModule, fetchFromGitHub }:
buildGoModule (prev: {
  name = "ilo_exporter";
  version = "1.0.4";

  src = fetchFromGitHub {
    owner = "MauveSoftware";
    repo = "ilo_exporter";
    tag = "v${prev.version}";
    hash = "sha256-8gTWZEMObG4D2kD601CzwBZBcxWicCf8MflN4ud8OJg=";
  };

  vendorHash = "sha256-FGpEyemuqlSMhsLNMNCUyzEG0rSBxwOhpmRp1LL1vz8=";
})
