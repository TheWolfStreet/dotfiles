# Vendored pi-coding-agent 0.86.0: our pinned nixpkgs ships 0.80.10, whose
# opencode-go provider only implements anthropic-messages and
# openai-completions. OpenCode Go serves Muse Spark, Grok 4.6/4.7 and GPT Luna
# over the Responses API, so those models fail on 0.80.10 with
# `Provider opencode-go has no API implementation for "openai-responses"`.
# 0.86.0 registers all three Go APIs with session headers. Drop this file,
# pi-coding-agent.bun.lock and the override in default.nix once pinned
# nixpkgs reaches >= 0.86.0.
#
# Built from the upstream npm tarball (ships prebuilt dist/) rather than the
# GitHub source: the wrapper in package.nix needs the monorepo layout
# (dist/ plus resolvable @earendil-works/* workspace packages) to bundle
# extensions into its compiled binary.
#
# Fixed-output (like the extensions deps in package.nix) so `bun install`
# can use the network; pi-coding-agent.bun.lock keeps it reproducible.
{
  lib,
  stdenvNoCC,
  bun,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.86.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${finalAttrs.version}.tgz";
    hash = "sha256-Pw9QL0l8RIiN29aKEYl2Ubc56qvfSyNeOn7Zc1NTsM0=";
  };

  lockfile = ./pi-coding-agent.bun.lock;

  nativeBuildInputs = [ bun ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    cp ${finalAttrs.lockfile} ./bun.lock
    bun install --frozen-lockfile --no-progress
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/pi-monorepo
    cp -r . $out/lib/node_modules/pi-monorepo
    runHook postInstall
  '';

  dontFixup = true;
  outputHashMode = "recursive";
  outputHash = "sha256-3I0FXIqKaf7sowbU0eXmX71LrMSSuvZ6piumXLgak3M=";

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
})
