{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      formatter-nvim
      lsp-format-nvim
      # editorconfig-nvim
      editorconfig-vim
      csv-vim
      vim-surround # fix config
      vim-repeat
      # vim-speeddating  # makes statusline buggy??
      vim-commentary
      vim-unimpaired
      vim-sleuth # adjusts shiftwidth and expandtab based on the current file
      vim-startify
      vim-multiple-cursors
      gundo-vim
      vim-easy-align
      vim-table-mode
      editorconfig-vim
      vim-markdown
      ansible-vim
      vim-nix
      robotframework-vim
      # vimspector
      popup-nvim
      plenary-nvim
      telescope-nvim
      telescope-symbols-nvim
      # telescope-media-files  # doesn't support wayland yet
      nvim-colorizer-lua
      nvim-lspconfig
      # completion-nvim
      nvim-cmp
      cmp-nvim-lsp
      lspkind-nvim
      gitsigns-nvim
      neogit
      nvim-autopairs
      vim-closetag
      friendly-snippets
      vim-vsnip
      # nvim-tree-lua
      neo-tree-nvim
      nvim-web-devicons
      vim-devicons
      # vim-auto-save  # ?
      # minimap-vim
      vim-easymotion
      quick-scope
      matchit-zip
      targets-vim
      neoformat
      vim-numbertoggle
      # vim-markdown-composer
      vimwiki
      vim-python-pep8-indent
      lsp_signature-nvim
      rust-tools-nvim
    ];
    #editor-config-nvim
  };

  # programs.vim = {
  # enable = true;
  # plugins = with pkgs.vimPlugins; [
  # vim-airline
  # editorconfig-vim
  # ];
  # };
}
