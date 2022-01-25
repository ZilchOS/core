{ fetchurl }:

#> FETCH ae31ecb3c6e9ff3154cb7a55f017090448f88482f0e94ac927c0c67a1f33b9cf
#>  FROM https://curl.se/download/cacert-2021-10-26.pem

fetchurl {
  # local = /downloads/cacert-2021-10-26.pem";
  url = "https://curl.se/ca/cacert-2021-10-26.pem";
  sha256 = "ae31ecb3c6e9ff3154cb7a55f017090448f88482f0e94ac927c0c67a1f33b9cf";
}
