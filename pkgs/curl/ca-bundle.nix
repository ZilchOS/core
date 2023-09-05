{ fetchurl }:

#> FETCH 23c2469e2a568362a62eecf1b49ed90a15621e6fa30e29947ded3436422de9b9
#>  FROM https://curl.se/ca/cacert-2023-08-22.pem

fetchurl {
  # local = /downloads/cacert-2023-08-22.pem;
  url = "https://curl.se/ca/cacert-2023-08-22.pem";
  sha256 = "23c2469e2a568362a62eecf1b49ed90a15621e6fa30e29947ded3436422de9b9";
}
