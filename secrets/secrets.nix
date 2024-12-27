let
  nas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBm2ee8Vjge69x3M5FHYkMNp2MZ95Z8MizURjbdPrIYe";
  lajp-nas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAEO0EO47XbQlQT2uBrlAeoKGG9FS7o5sL8pNnJbIxEj";
  lajp-t480 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnZzQYZMQAPPVRLMP1nIDR5cSc2u67aaf1t5OXNUYdy";
  t480 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHB05Rw4+xyxVyJXL84g7TM6jcS73P3yBJA/QI+MBqdc";
in {
  "pia.age".publicKeys = [nas];
  "pia2.age".publicKeys = [lajp-t480];
  "transmission.age".publicKeys = [nas];
  "testaustime.age".publicKeys = [lajp-nas nas lajp-t480];
  "restic-t480.age".publicKeys = [t480 lajp-t480];
  "cross-seed.age".publicKeys = [nas];
}
