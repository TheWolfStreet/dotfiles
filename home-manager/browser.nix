{...}: {
  home = {
    sessionVariables.BROWSER = "chromium";
  };

  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "jehmdpemhgfgjblpkilmeoafmkhbckhi" # Scroll Anywhere
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "njdfdhgcmkocbgbhcioffdbicglldapd" # LocalCDN
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
      "ibplnjkanclpjokhdolnendpplpjiace" # Simple Translate
    ];
  };
}
