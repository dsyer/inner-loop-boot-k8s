self: super: {
  tilt = super.tilt.overrideAttrs(oldAttrs: rec {
    version = "0.22.5";
    src = self.fetchFromGitHub {
      owner  = "tilt-dev";
      repo   = super.tilt.pname;
      rev    = "v${version}";
      sha256 = "00irifwydsyjvh35k4mik82vp1wfp09agqyi421n7qx39azv46yl";
    };
    buildFlagsArray = [ "-ldflags=-X main.version=${version}" ];
  });
}
