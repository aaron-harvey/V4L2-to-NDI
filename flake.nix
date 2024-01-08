{
  description = "A video input (V4L2) to NDI converter";

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
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });

    in
    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        ndi = prev.ndi.overrideAttrs (old: {

          # Override unfree src with flake input and adapt unpackPhase
          # accordingly
          src = ndi-linux;
          unpackPhase = ''
            echo y | $src;
            sourceRoot="NDI SDK for Linux";
          '';

          # TODO Currently ndi is broken/outdated in nixpkgs.
          # Remove this installPhase when
          # https://github.com/NixOS/nixpkgs/pull/272073 is merged
          installPhase = with prev;
            let
              ndiPlatform = "x86_64-linux-gnu";
              pname = "ndi";
              version = "5.6.0";
            in

            ''
              mkdir $out
              mv bin/${ndiPlatform} $out/bin
              for i in $out/bin/*; do
                if [ -L "$i" ]; then continue; fi
                patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$i"
              done
              patchelf --set-rpath "${avahi}/lib:${stdenv.cc.libc}/lib" $out/bin/ndi-record
              mv lib/${ndiPlatform} $out/lib
              for i in $out/lib/*; do
                if [ -L "$i" ]; then continue; fi
                patchelf --set-rpath "${avahi}/lib:${stdenv.cc.libc}/lib" "$i"
              done
              mv include examples $out/
              mkdir -p $out/share/doc/${pname}-${version}
              mv licenses $out/share/doc/${pname}-${version}/licenses
              mv documentation/* $out/share/doc/${pname}-${version}/
            '';
        });
      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system:
          let pkgs = nixpkgsFor.${system}; in
          {

            v4l2-to-ndi = pkgs.stdenv.mkDerivation rec {
              name = "v4l2-to-ndi";
              inherit version;

              nativeBuildInputs = [ pkgs.autoPatchelfHook ];

              src = ./.;

              buildInputs = with pkgs; [
                openssl
                curl
                avahi
                ndi
              ];

              buildPhase = ''
                mkdir build

                g++ -std=c++14 -pthread  -Wl,--allow-shlib-undefined -Wl,--as-needed \
                -I'NDI SDK for Linux'/include/ \
                -Iinclude/ \
                -L'NDI SDK for Linux'/lib/x86_64-linux-gnu \
                -o build/v4l2ndi main.cpp PixelFormatConverter.cpp -lndi -ldl

              '';

              installPhase = ''
                mkdir $out
                cp -r build $out/bin
              '';

              meta = with pkgs.lib; {
                mainProgram = "v4l2ndi";
                platforms = platforms.linux;
                homepage = "https://github.com/lplassman/V4L2-to-NDI";
                description = "A video input (V4L2) to NDI converter";
                maintainers = with pkgs; [ pinpox MayNiklas ];
                license = licenses.mit;
              };

            };
          });


      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.v4l2-to-ndi);
    };
}
