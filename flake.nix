{
  description = "A simple Go package";

  # Nixpkgs / NixOS version to use.
  # inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  inputs = {
    ndi-linux.url = "https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v5_Linux.tar.gz";
    ndi-linux.flake = false;
  };

  outputs = { self, nixpkgs, ndi-linux }:
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


            v4l2-to-ndi = pkgs.stdenv.mkDerivation
              rec {
                name = "v4l2-to-ndi";
                version = "master";


                #   nativeBuildInputs = [
                #     pkgs.autoPatchelfHook
                #   ];

                src = [
                 ./.
                  # ndi-linux
                ];

                unpackPhase = ''
                  echo y | ${ndi-linux}
                  ls -l
                  ndiSDK="NDI SDK for Linux";
                '';



                # sudo bash ./preinstall.sh

                /*
                  #!/usr/bin/env sh

                  apt-get update

                  #install prerequisites
                  apt-get -y install \
                  g++ \
                  avahi-daemon \
                  avahi-discover \
                  avahi-utils \
                  libssl-dev \
                  libconfig++-dev \
                  curl \
                  || exit 1
                */


                buildInputs = with pkgs; [
                  # alsaLib
                  # openssl
                  # zlib
                  openssl
                  curl
                  avahi
                  # pulseaudio
                ];

                # sudo bash ./download_NDI_SDK.sh

                /*


                  #download and extract NDI
                  curl -s https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v5_Linux.tar.gz | tar xvz -C /tmp/
                  yes y | bash /tmp/Install_NDI_SDK_v5_Linux.sh > /dev/null

                */


                # sudo bash ./build_x86_64.sh

                /*
                  #!/usr/bin/env sh

                  if [ ! -d "build" ]; then
                  mkdir build
                  fi

                  if [ ! -d "lib" ]; then
                  mkdir lib
                  fi

                  cp "NDI SDK for Linux"/include/* include/
                  cp "NDI SDK for Linux"/lib/x86_64-linux-gnu/* lib/

                  g++ -std=c++14 -pthread  -Wl,--allow-shlib-undefined -Wl,--as-needed -Iinclude/ -L lib -o build/v4l2ndi main.cpp PixelFormatConverter.cpp -lndi -ldl

                */

                buildPhase = ''

                echo "SRC is $src"

                  # mkdir build
                  # mkdir lib

                  echo "SDK IS IN "

# ls 'NDI SDK for Linux'



                  # cp "NDI SDK for Linux"/include/* $src/include/

                  # cp "NDI SDK for Linux"/lib/x86_64-linux-gnu/* lib/

                  # g++ -std=c++14 -pthread  -Wl,--allow-shlib-undefined -Wl,--as-needed -Iinclude/ -L lib -o build/v4l2ndi main.cpp PixelFormatConverter.cpp -lndi -ldl

                  cd $src


                  g++ -std=c++14 -pthread  -Wl,--allow-shlib-undefined -Wl,--as-needed \
                  -I'NDI SDK for Linux'/incude/ \
                  -Iinclude/ \
                  -L 'NDI SDK for Linux'/lib/x86_64-linux-gnu \
                  -o build/v4l2ndi main.cpp PixelFormatConverter.cpp -lndi -ldl

                '';


                # sudo bash ./install.sh


                /*


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


                #   # meta = with pkgs.lib; {
                #   #   homepage = "https://studio-link.com";
                #   #   description = "Voip transfer";
                #   #   platforms = platforms.linux;
                #   # };

              };




            # ndi-utils = pkgs.stdenv.mkDerivation rec {
            #   pname = "ndi";

            #   version = "21.07.0";

            #   src = ./.;

            #   nativeBuildInputs = [
            #     pkgs.autoPatchelfHook
            #   ];

            #   buildInputs = with pkgs; [
            #     # alsaLib
            #     # openssl
            #     # zlib
            #     avahi
            #     # pulseaudio
            #   ];

            #   sourceRoot = ".";

            #   installPhase = ''




            #                  install -m755 -D $src/bin/x86_64-linux-gnu/ndi-record $out/bin/ndi-record
            #                  install -m755 -D $src/bin/x86_64-linux-gnu/ndi-directory-service $out/bin/ndi-directory-service
            #                  install -m755 -D $src/bin/x86_64-linux-gnu/ndi-free-audio $out/bin/ndi-free-audio
            #                  install -m755 -D $src/bin/x86_64-linux-gnu/ndi-benchmark $out/bin/ndi-benchmark

            #     # echo "LIBS"


            #     #   cp -r $src/lib/x86_64-linux-gnu $out/lib


            #     # echo "patching bins"

            #     #   for i in $out/bin/*; do
            #     #     patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$i"
            #     #   done


            #     # echo "patching ndi-record"
            #     #   patchelf --set-rpath "${pkgs.avahi}/lib:${pkgs.stdenv.cc.libc}/lib" $out/bin/ndi-record


            #     # echo "patching lib"




            #     #   echo "copy example"

            #     #   mv $src/include examples $out/
            #     #   mkdir -p $out/share/doc/${pname}-${version}
            #     #   mv licenses $out/share/doc/${pname}-${version}/licenses
            #     #   mv logos $out/share/doc/${pname}-${version}/logos
            #     #   mv documentation/* $out/share/doc/${pname}-${version}/



            #   '';

            #   # meta = with pkgs.lib; {
            #   #   homepage = "https://studio-link.com";
            #   #   description = "Voip transfer";
            #   #   platforms = platforms.linux;
            #   # };
            # };
          });


      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.v4l2-to-ndi);
    };
}
