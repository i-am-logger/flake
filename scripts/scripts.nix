{ writeShellScriptBin, ... }: {

  writeShellScriptBin "name" ''
    echo "hello"
  ''

  }
