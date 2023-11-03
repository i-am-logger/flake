{ pkgs, sky360pkgs, ... }:
{
  services.ros2 = {
    enable = true;
    distro = "iron";

    # pkgs = [

    #   sky360pkgs.ros2.heartbeat = {
    #   service = true;
    # };
    # ];
  };

  # systemPackages = with pkgs; [ ros2cli ros2run gazebo ros2launch ros-environment ];
}
