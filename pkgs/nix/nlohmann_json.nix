{ name ? "nlohmann_json", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "3.11.2";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/nlohmann-json-3.11.2.tar.xz;
    url = "https://github.com/nlohmann/json/releases/download/v3.11.2/json.tar.xz";
    sha256 = "8c4b26bf4b422252e13f332bc5e388ec0ab5c3443d24399acb675e68278d341f";
  };

  buildInputs = [ gnumake ];

  configurePhase = "";
  buildPhase = "";

  installPhase = ''
    mkdir $out
    cp -rv include $out
    mkdir -p $out/lib/pkgconfig
    sed < cmake/pkg-config.pc.in \
      -e 's|''${PROJECT_NAME}|nlohmann_json|' \
      -e 's|''${PROJECT_VERSION}|3.11.2|' \
      -e "s|\''${CMAKE_INSTALL_FULL_INCLUDEDIR}|$out/include|" \
      > $out/lib/pkgconfig/nlohmann_json.pc
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
