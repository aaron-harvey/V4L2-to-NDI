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

              pkgs.stdenv.mkDerivation rec {
                name = "v4l2-to-ndi";
                version = "master";

                nativeBuildInputs = [ pkgs.autoPatchelfHook ];

                src = ./.;

                buildInputs = with pkgs; [
                  openssl
                  curl
                  avahi
                  my-ndi
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
                  maintainers = with pkgs; [ pinpox mayniklas ];
                  # sourceProvenance = with sourceTypes; [ binaryNativeCode ];
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
