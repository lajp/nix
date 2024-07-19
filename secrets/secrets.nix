let
  nas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBm2ee8Vjge69x3M5FHYkMNp2MZ95Z8MizURjbdPrIYe";
in {
  "pia.age".publicKeys = [nas];
  "transmission.age".publicKeys = [nas];
}
