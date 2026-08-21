{ python3Packages, fetchFromGitHub }:
python3Packages.buildPythonApplication {
  name = "hpilo-exporter";
  src = fetchFromGitHub {
    owner = "hpilo-exporter";
    repo = "hpilo-exporter";
    rev = "8a0df66e8ad5ead7c29ed48d1669298840b462e1";
    hash = "sha256-f8g16NR3uEjz9NRzvi/He9YpHe7OcdZPpv1OHeW/gH0=";
  };

  pyproject = true;

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    prometheus-client
    python-hpilo
    psutil
  ];
}
