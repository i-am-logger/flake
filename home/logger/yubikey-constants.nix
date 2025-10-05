# YubiKey Constants
# Centralized configuration for YubiKey settings to avoid hardcoded values
{
  # YubiKey Serial Numbers
  yubikey1Serial = "15147050";
  yubikey2Serial = "17027658";
  
  # GPG Key IDs
  yubikey1GpgKeyId = "42BF2C362C094388";
  yubikey2GpgKeyId = "9D92E6047DEB1589";
  
  # SSH Keygrips (for gpg-agent SSH support)
  yubikey1SshKeygrip = "504BF2F0CD516A5FD35A640B1719EA8CD73EF2DA";
  yubikey2SshKeygrip = "90687F2920871E0132190BE0142A24C3D3A9090F";
  
  # U2F Registration Data (PAM authentication) - registered with pam:// origin
  yubikey1U2fData = "x75RZ50wUBxtKWAvyGznyn4VBfAwez885pEUMz5DIefwaMqEM7SYjClLpt7U7wPFfZI8dmtfGLk1fHK8hrVuQA==,9RDhFkuKAsqMMwg7JctuF2keZE9tt57JaeV4+fwzDOLrt3okgh3rfLCkmQP9dAoHVSi2pJ0bxncOXlgUz/GLVA==,es256,+presence";
  yubikey2U2fData = "UtReVJlip06Qkkq857sMUU/fbJkCJrLTkfdNNEBmZcYofkRffsa684x5TZSLt7fCn3iPFnhxmP3INmU6EB2v0g==,06KPW/h74mFiv9uj+B1lIt9aa8H4uA7P7YaAp0zndpcrYZhRwdrSHyu2ZOVEIHCcw/etjsHUV9c/ik5fsxwqJQ==,es256,+presence";
  
  # User Information
  userName = "logger";
  userEmail = "i-am-logger@users.noreply.github.com";
  
  # Path Configuration
  passwordStoreDir = "$HOME/.password-store";
  gpgHomePath = "$HOME/.gnupg";
}