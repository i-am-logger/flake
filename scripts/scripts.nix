{ writeShellScriptBin, ... }: {

  writeShellScriptBin "hi" ''
    echo "hello"
  ''

  }
