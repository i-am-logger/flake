# nixos - install OS + setup btrfs

the laptop has 2x8TB nvmes

file system: btrfs

volumes: nvme 1
-----------------|
| boot	| 2GB    |
| / 		| 8GB    |
| /tmp  | 100GB  |
| /swap	| 100GB  |
| /nix  | 2048GB |
| /home	| ~6TB   |

volumes: nvme 2
-----------------|
| /data	| 8TBGB  |


# steps

- [x] backup /home 
- [ ] install os
- [ ] setup btrfs
- [ ] setup personal flake.nix with new hardware-configuration.nix
- [ ] setup development enviornment for sky360 nixOS SD Image builds 