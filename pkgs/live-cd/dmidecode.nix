{ name ? "dmidecode", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "3.5";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/dmidecode-3.5.tar.xz;
    url = "http://download.savannah.gnu.org/releases/dmidecode/dmidecode-3.5.tar.xz";
    sha256 = "79d76735ee8e25196e2a722964cf9683f5a09581503537884b256b01389cc073";
  };

  buildInputs = [ gnumake ];

  configurePhase = ''
    sed -i "s|prefix  = /usr/local|prefix  = $out|" Makefile
  '';

  allowedRequisites = [ stdenv.musl ];
  allowedReferences = [ stdenv.musl ];
}
