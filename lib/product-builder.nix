{ inputs, lib, nixpkgs, ... }:

let
  productTypes = import ./types.nix { inherit lib; };
in

{
  # Main builder function
  buildProduct = productSpec:
    let
      # Validate product specification
      validated = validateProduct productSpec;
      
      # Translate to system configuration
      systemConfig = translateProduct validated;
      
      # Build NixOS system
      nixosSystem = lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = systemConfig.modules;
      };
    in
    nixosSystem;
    
  # Validation
  validateProduct = spec:
    let
      checks = {
        hasName = builtins.hasAttr "name" spec;
        hasHardware = builtins.hasAttr "hardware" spec;
        hasType = builtins.hasAttr "type" spec;
      };
      
      errors = lib.filter (check: !checks.${check}) (builtins.attrNames checks);
    in
    if (builtins.length errors) > 0
    then throw "Product validation failed: ${builtins.toString errors}"
    else spec;
    
  # Translation from product spec to NixOS modules
  translateProduct = spec: {
    modules = [
      # Hardware modules
      (translateHardware (spec.hardware or {}))
      
      # Capability modules  
      (translateCapabilities (spec.capabilities or {}))
      
      # User modules
      (translateUsers (spec.users or []))
      
      # UI modules
      (translateUI (spec.ui or {}))
      
      # System modules
      (translateSystem (spec.system or {}))
      
      # Base configuration
      {
        networking.hostName = spec.name;
        system.stateVersion = "24.05";
      }
    ];
  };
  
  translateHardware = hwSpec: {
    # Enable the specified motherboard
    hardware.motherboard.${hwSpec.motherboard or hwSpec.platform or "generic"}.enable = lib.mkDefault true;
    
    # CPU configuration
    hardware.cpu = lib.mkIf (hwSpec ? cpu) (
      if builtins.isAttrs hwSpec.cpu then hwSpec.cpu
      else { enable = true; model = hwSpec.cpu; }
    );
    
    # GPU configuration
    hardware.gpu = lib.mkIf (hwSpec ? gpu) (
      if builtins.isAttrs hwSpec.gpu then hwSpec.gpu
      else { enable = true; model = hwSpec.gpu; }
    );
    
    # Audio configuration
    hardware.audio = lib.mkIf (hwSpec ? audio) (
      if builtins.isAttrs hwSpec.audio then hwSpec.audio
      else { enable = hwSpec.audio; }
    );
    
    # Bluetooth configuration
    hardware.bluetooth = lib.mkIf (hwSpec ? bluetooth) (
      if builtins.isAttrs hwSpec.bluetooth then hwSpec.bluetooth
      else { enable = hwSpec.bluetooth; }
    );
    
    # Network configuration
    hardware.network = lib.mkIf (hwSpec ? wifi || hwSpec ? ethernet) {
      wifi = lib.mkIf (hwSpec ? wifi) (
        if builtins.isAttrs hwSpec.wifi then hwSpec.wifi
        else { enable = hwSpec.wifi; }
      );
      ethernet = lib.mkIf (hwSpec ? ethernet) (
        if builtins.isAttrs hwSpec.ethernet then hwSpec.ethernet
        else { enable = hwSpec.ethernet; }
      );
    };
  };
  
  translateCapabilities = capSpec: {
    # Map capabilities to stacks
    capabilities = capSpec;
  };
  
  translateUsers = users: 
    if builtins.isList users then {
      # Simple list of usernames
      users.users = builtins.listToAttrs (map (user:
        { 
          name = user; 
          value = { 
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
          }; 
        }
      ) users);
    } else {
      # Attrset of user configurations
      users.users = users;
    };
  
  translateUI = uiSpec: {
    ui = uiSpec;
  };
  
  translateSystem = sysSpec: {
    time.timeZone = sysSpec.timezone or "UTC";
    i18n.defaultLocale = sysSpec.locale or "en_US.UTF-8";
    
    # Network configuration
    networking = lib.optionalAttrs (sysSpec ? network) {
      networkmanager.enable = lib.mkDefault (sysSpec.network.manager or "networkmanager" == "networkmanager");
      wireless.enable = lib.mkDefault (sysSpec.network.wireless or false);
    };
    
    # Performance tuning
    boot.kernel.sysctl = lib.optionalAttrs (sysSpec ? performance) (
      let perf = sysSpec.performance; in {
        "net.core.default_qdisc" = lib.mkIf (perf ? tcp-congestion-control) (perf.qdisc or "fq");
        "net.ipv4.tcp_congestion_control" = lib.mkIf (perf ? tcp-congestion-control) (perf.tcp-congestion-control or "bbr");
        "vm.swappiness" = lib.mkIf (perf ? vm-swappiness) (perf.vm-swappiness or 60);
        "vm.vfs_cache_pressure" = lib.mkIf (perf ? vm-vfs-cache-pressure) (perf.vm-vfs-cache-pressure or 100);
        "vm.dirty_background_ratio" = lib.mkIf (perf ? vm-dirty-background-ratio) (perf.vm-dirty-background-ratio or 10);
        "vm.dirty_ratio" = lib.mkIf (perf ? vm-dirty-ratio) (perf.vm-dirty-ratio or 20);
      }
    );
  };
}
