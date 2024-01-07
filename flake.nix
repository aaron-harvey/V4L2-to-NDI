{
  description = "A video input (V4L2) to NDI converter";

  # Nixpkgs / NixOS version to use.
  # inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  inputs = {
    ndi-linux.url = "https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v5_Linux.tar.gz";
    ndi-linux.flake = false;

    v4l2-to-ndi.url = "https://github.com/lplassman/V4L2-to-NDI";
    v4l2-to-ndi.flake = false;
  };

  outputs = { self, nixpkgs, ndi-linux, v4l2-to-ndi }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system:
          let
            pkgs = nixpkgsFor.${system};
          in

          {


            v4l2-to-ndi =

              let
                my-ndi = pkgs.callPackage ./ndi.nix { };
              in

              pkgs.stdenv.mkDerivation
                rec {
                  name = "v4l2-to-ndi";
                  version = "master";

                  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

                  src = ./.;

                  unpackPhase = '' '';

                  /*
                  Original dependencies:

                  apt-get -y install \
                  g++ \
                  avahi-daemon \
                  avahi-discover \
                  avahi-utils \
                  libssl-dev \
                  libconfig++-dev \
                  curl
                  */

                  buildInputs = with pkgs; [
                    openssl
                    curl
                    avahi
                    my-ndi
                  ];

                  /*
                  # Original pre-install script:
                  curl -s https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v5_Linux.tar.gz | tar xvz -C /tmp/
                  yes y | bash /tmp/Install_NDI_SDK_v5_Linux.sh > /dev/null
                  */

                  buildPhase = ''


                ls $src

                  # Original build script:
                  # cp "NDI SDK for Linux"/include/* $src/include/
                  # cp "NDI SDK for Linux"/lib/x86_64-linux-gnu/* lib/
                  # g++ -std=c++14 -pthread  -Wl,--allow-shlib-undefined -Wl,--as-needed -Iinclude/ -L lib -o build/v4l2ndi main.cpp PixelFormatConverter.cpp -lndi -ldl


                  echo y | ${ndi-linux}
                  mkdir build

                  g++ -std=c++14 -pthread  -Wl,--allow-shlib-undefined -Wl,--as-needed \
                  -I'NDI SDK for Linux'/include/ \
                  -Iinclude/ \
                  -L'NDI SDK for Linux'/lib/x86_64-linux-gnu \
                  -o build/v4l2ndi main.cpp PixelFormatConverter.cpp -lndi -ldl

                  mkdir $out
                  cp -r build $out/bin

                '';


                  /*

                  Original Install script:

                  #!/usr/bin/env sh

                  INSTALL_DIR="/opt/v4l2ndi"
                  BIN_DIR="$INSTALL_DIR/bin"
                  LIB_DIR="/usr/lib"

                  rm -R "$INSTALL_DIR"
                  rm -R "$LIB_DIR/libndi*"

                  if [ ! -d "$INSTALL_DIR" ]; then
                  mkdir "$INSTALL_DIR"
                  fi

                  if [ ! -d "$LIB_DIR" ]; then
                  mkdir "$LIB_DIR"
                  fi

                  if [ ! -d "$BIN_DIR" ]; then
                  mkdir "$BIN_DIR"
                  fi

                  cp lib/* "$LIB_DIR"

                  cp build/v4l2ndi "$BIN_DIR"

                  chmod +x "$BIN_DIR/v4l2ndi"

                  #symlink to the /usr/bin directory
                  ln -s "$BIN_DIR/v4l2ndi" /usr/bin/
                  */


                  #   sourceRoot = ".";

                  #   installPhase = ''


                  meta = with pkgs.lib; {
                    mainProgram = "v4l2ndi";
                    platforms = platforms.linux;
                  };

                };
          });


      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.v4l2-to-ndi);
    };
}
