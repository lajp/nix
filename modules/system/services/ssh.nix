{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lajp.user) username;
  cfg = config.lajp.services.ssh;
in {
  options.lajp.services.ssh.enable = mkEnableOption "Enable the OpenSSH server";
  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "without-password";
        StreamLocalBindUnlink = "yes";
      };
    };

    services.fail2ban.enable = true;

    users.users.${username}.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSvQTWLI2UWDNaxW2o+5ziYQdxV5R2MKqB+wS0npmIuoHvu6J/SaE4cRA6M7daUw1nc+eRz49tc9LXG7W62y0vaTcJktNlCmMdpN/xUEJEsnbJUIbnTIoyisRoe09mrJYRmYoZhqCxwuoy2GfvKPrO4cvHKYdcxlUzxkb6cvL/5RZvYkzPEM8iwXAd/cysoepj9ajEv5vLJqJggT+9NyNqiWIGPzNF00ZWITu8OKteHfG/Msj/hGvs3NH7S5JMUp5y6HbMUYtrLPjUhnZTqdaEinL3aVuxJziIx/mnSFKGkR9ap6rhBYBXW0wYp6yq2RVRx9d1zp8ov3mWeZVL9zREql/8bEIUd0ex2Lg8Sm/EIi1VMfQvYlpw9D824p1Eb7KxjY945/nuvrj+eBaAmIQ2FDfe9PHBFn3gxdAvGkqkwQOwOW7foyp9Za3CzK7loT1hlapSEsSYzypSernQCaK3QGBD60bkhPAK+KWpBjTpqsYjLfYuXZ3gUkeivgjcNQs="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbrz46rQjkvigOa/j3CL+lQjqRJOJ9qHmUh6YcwSSTsWUSRZGRaLGT8hnLxFz0FiGoZ5hsMAc30IjYc8ybYwJavYOyEVmhXg28qL6lc8PGxfdyRb9apu8j+GEd3oid+53kiD6ZjpeqeAPFlv3Jg1RO7nYbL+ioEW02Cgqq5p9ubqSXXRl8/HuQ8KGEK2AOTc4OgrEEswjckJVDMoHsSBy94v2G6yoP9bL4144EQLvp7j+xPyv0D13eKS5HeNvNYyJDU6mk7zLoNni13Lez/9/smZ1Tw8V9FFT6t80ciG4gmBvp5ZxK3w3rV93CfndTdWt1U66ZoXT5Pu23+9Sg+IdGyoF89qSszm5b4BNaQQBqKeUuPyKHCOl6yZ4cwECElaW6h3ghW+0/Av+mt24mmY2u70Cf5VEg126TbnIJ4vzxN+aqPAzwT72AoaFBdDAS8e49ICXfuaOkKT3TWDl+5H7I/MqR8goseHOKIeWMQ3GsLyQLQ+m3CqrIcHlDoxpNo0c="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2UnzpLVdcpV/Np+P806LDkGB7/u4zWNMwnppDwLwGHH/SwaD7TTRu0WplRiFwXIE8nep87VYYacK9ZhhWQhGljoarJK3jwod7dmhttWl/sYw76Xkvm4bTc8sT0puQ1WN96qE9Xp/EdcxJkL3nYrk9jvEkCLYHAJJ0Xzg0jWbfm3FKKKU0Q4jvxCR5AcLDhyKyAC4uII+mcGJFCV3s9C6s3BGi7ZmxA3+vTfQaUPXk+YBRRM7FVRvmqZZ7HBYE8YBVW7S/L+RI2qaLLoR1V0CWVkrQJgYlQYobGausjVtQQELEjwmZ+mjQO68a6q82Gs0LfT5Gu6spcznhS2C4rq4u6wOrdFAZfSwRlmayhFpslnohrYTj/TscbupccPDOW1aGv6L7n9pXnGMUqbtQgbnd7jtk+CLy4uKfttcHD+T5cPL5evCzdLt7c6yyawPK8/BquKq32T72yFO4jpL3WyK/DCkXuhejA8mqb6fJ9s/3ZsS46NGgqxf9iiu+QIkqkYM="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCqDccdqRaoZtHZ9k+KrynmYY8iWylkkK9u96VLpb8SxjxyrbYWdtGj5gAelid2OGF8c/1QW1oGDJN+Z7LkYQcYIgtAmYiECGKv8LwKmDedHKMAOgNsXZpfKu6Y+/KIpfrOP5qPiE5FMN5byw9ZkaWZaIGABv79gCrzc1JPP65lfv0TP2o5VuiyIytYHxXc+zzw778Nl6ljhuT2LBmQmEnF0mSzkq9WC3ycIG7GlK2Y3Pv3X0UyhorjwL7rdybC9Qgo4k2Cw6dvSXukhBiIsCE7MHBRCULnxudZCN/24pRzAN1mj2B22AiUJjdSCGBFqQLnlOn5lZFRRaH8ongSkEzPSsrVu1jLq+oSkPlKwDJhiwl9trbTj6timO7RLKJOFe/D7dJvGaoTna2KFZlRSCwwujzgiOnwHG36ikmOnON8ozaaU5xWvBrty2LDxVtAYHyAuXTPXUODifj58VZF6U+zJPHZtt1s80yjd7Y2Sra+QlSW5ArHdXthaPPMmhLJacc="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICDO+tfrNqYEcR/t4FgbdwmLcyz0NxiLkx7Q0YdJjsKG"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISghGPvKtS05h/drTAU5kTxtckYieAKVMTYlct4/Lqu"
    ];
  };
}
