{ inputs, lib, nixpkgs, ... }:

let
  productTypes = import ./types.nix { inherit lib; };
  
  # Helper to get disko config from hardware path
  getDisko = hardwarePath:
    let
      diskoPath = hardwarePath + "/disko.nix";
    in
    if builtins.pathExists diskoPath then diskoPath else null;
    
  # Helper to resolve motherboard path
  getMotherboardPath = motherboard:
    let
      # Map motherboard name to hardware module path
      motherboardPaths = {
        "gigabyte-x870e-aorus-elite-wifi7" = ../../Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7;
        "lenovo-legion-16irx8h" = ../../Hardware/motherboards/lenovo/legion-16irx8h;
      };
    in
    motherboardPaths.${motherboard} or (throw "Unknown motherboard: ${motherboard}");
in

{
  # Main builder function that creates a NixOS system from a product specification
  buildProduct = productSpec:
    let
      # Validate product specification
      validated = validateProduct productSpec;
      
      # Get hardware module paths
      hardwarePaths = getHardwarePaths validated;
      
      # Find disko configs
      diskoConfigs = builtins.filter (x: x != null) (map getDisko hardwarePaths);
      hasDisko = (builtins.length diskoConfigs) > 0;
      
      # Get users
      userModules = getUserModules (validated.users or []);
      
      # Translate capabilities to stacks configuration
      stacksConfig = translateCapabilitiesToStacks (validated.capabilities or {});
    in
    lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit (inputs) secrets disko impermanence stylix lanzaboote self;
      };

      modules = hardwarePaths
        ++ (lib.optionals hasDisko [
          # Disko partitioning from hardware modules
          inputs.disko.nixosModules.disko
          {
            disko.devices = lib.mkMerge (map (diskoPath: import diskoPath { lib = nixpkgs.lib; }) diskoConfigs);
          }
        ])
        ++ [
          # Set hostname
          { networking.hostName = validated.name; }

          # NixOS users
          {
            imports = map (user: user.nixosUser) userModules;
          }

          # Home Manager for users
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users = lib.genAttrs
              (map (user: user.name) userModules)
              (name:
                let user = lib.findFirst (u: u.name == name) null userModules;
                in { imports = [ user.homeManager ]; }
              );
          }

          # Infrastructure and Stacks
          ../Systems/Infra
          ../Systems/Stacks
          { stacks = stacksConfig; }

          # Theme
          inputs.stylix.nixosModules.stylix
          ../Themes/stylix.nix

          # Common modules
          ../modules/motd
          
          # Product-specific system configuration
          (translateSystem (validated.system or {}))
        ];
    };
    
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
    
  # Get hardware module paths
  getHardwarePaths = spec:
    let
      hwSpec = spec.hardware;
      motherboard = hwSpec.motherboard or (throw "Hardware specification must include motherboard");
    in
    [ (getMotherboardPath motherboard) ];
  
  # Get user modules from user names
  getUserModules = users:
    let
      usersLib = import ./users.nix { };
    in
    if builtins.isList users then
      map (userName: usersLib.${userName} or (throw "Unknown user: ${userName}")) users
    else
      throw "Users must be a list of user names";
  
  # Translate capabilities to stacks configuration (matching existing stacks structure)
  translateCapabilitiesToStacks = capSpec: {
    security = lib.optionalAttrs (capSpec ? security) {
      enable = true;
      secureBoot.enable = capSpec.security.secureBoot.enable or false;
      yubikey.enable = capSpec.security.yubikey.enable or false;
      auditRules.enable = capSpec.security.audit.enable or false;
    };
    
    desktop = lib.optionalAttrs (capSpec ? desktop) {
      enable = true;
      warp.enable = capSpec.desktop.warp.enable or false;
      warp.preview = capSpec.desktop.warp.preview or false;
      vscode.enable = capSpec.desktop.vscode.enable or false;
      browser.enable = capSpec.desktop.browser.enable or false;
    };
    
    cicd = lib.optionalAttrs (capSpec ? cicd) {
      enable = true;
      enableGpu = capSpec.cicd.gpuSupport.enable or false;
    };
  };
  
  # Translate system-level configuration
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
