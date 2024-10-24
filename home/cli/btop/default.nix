{ pkgs, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      update_ms = 100;
      # gpu_mem_override = true;
      # gpu_cores_override = true;
      # gpu_temps_override = true;
      show_gpu = "true";
      shown_boxes = "cpu mem net proc gpu0";
      # gpu_mirror_graph = "gpu0:gpu1";
      # gpu_mirror_mem = "gpu0:gpu1";
      # gpu_mirror_temp = "gpu0:gpu1";
    };
    package = pkgs.btop.override {
      cudaSupport = true;
    };
  };
}
