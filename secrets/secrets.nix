let
  nas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBm2ee8Vjge69x3M5FHYkMNp2MZ95Z8MizURjbdPrIYe";
  lajp-nas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAEO0EO47XbQlQT2uBrlAeoKGG9FS7o5sL8pNnJbIxEj";
in {
  "pia.age".publicKeys = [nas];
  "transmission.age".publicKeys = [nas];
  "testaustime.age".publicKeys = [lajp-nas nas];
}
