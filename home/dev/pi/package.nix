# Pi compiled to one bun bytecode binary with extensions built in (~0.35s startup vs ~1.9s).
# Update extensions: `bun update --lockfile-only` here, then rebuild and take the new outputHash.
{
  lib,
  stdenvNoCC,
  bun,
  jq,
  makeWrapper,
  pi-coding-agent,
  fd,
  ripgrep,
  rtk,
}: let
  pi = "${pi-coding-agent}/lib/node_modules/pi-monorepo";

  deps = stdenvNoCC.mkDerivation {
    pname = "pi-extensions-deps";
    inherit (pi-coding-agent) version;
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [./package.json ./bun.lock];
    };
    nativeBuildInputs = [bun];
    buildPhase = ''
      export HOME=$TMPDIR
      bun install --frozen-lockfile --omit=peer --ignore-scripts --no-progress
    '';
    # Keep a real node_modules dir so runtime resolution (require.resolve, hoisted deps) works
    installPhase = "mkdir $out && cp -r node_modules $out/";
    dontFixup = true;
    outputHashMode = "recursive";
    outputHash = "sha256-TJpICLDj5amxMRfjO925GXXhTFR3/kLaQfdV00gi5NI=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "pi";
    inherit (pi-coding-agent) version;
    src = ./package.json;
    dontUnpack = true;
    nativeBuildInputs = [bun jq makeWrapper];

    buildPhase = ''
      export HOME=$TMPDIR
      cp -r ${deps}/node_modules node_modules
      chmod -R u+w node_modules

      # Bundled code would see /$bunfs paths; point file-relative lookups (rules, grammars, workers) at the store copy
      find node_modules -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.ts' -o -name '*.mts' \) \
        ! -name '*.d.ts' ! -name '*.d.mts' -print0 |
        while IFS= read -r -d "" f; do
          grep -q 'import\.meta\.\(url\|dirname\|filename\)' "$f" || continue
          r=${deps}/$f
          sed -i "s#import\.meta\.url#'file://$r'#g; s#import\.meta\.dirname#'$(dirname "$r")'#g; s#import\.meta\.filename#'$r'#g" "$f"
        done

      # pi-rtk-optimizer lazy-loads via import(variable), which bun can't bundle; make the imports static
      sed -i 's#createLazyModuleLoader<typeof import("\([^"]*\)")>("\1")#(() => import("\1"))#' \
        node_modules/pi-rtk-optimizer/src/*.ts
      mkdir -p node_modules/@earendil-works
      ln -s ${pi} node_modules/@earendil-works/pi-coding-agent
      for p in pi-ai pi-tui pi-agent-core; do
        ln -s ${pi}/node_modules/@earendil-works/$p node_modules/@earendil-works/$p
      done

      # Mirrors pi's dist/bun/cli.js, passing extensions as factories instead of loading them via jiti
      d=./node_modules/@earendil-works/pi-coding-agent/dist
      {
        echo "import { registerBunOAuthFlows } from '@earendil-works/pi-ai/bun-oauth';"
        echo "import { APP_NAME } from '$d/config.js';"
        echo "import { configureHttpDispatcher } from '$d/core/http-dispatcher.js';"
        echo "import { main } from '$d/main.js';"
        echo "import { restoreSandboxEnv } from '$d/bun/restore-sandbox-env.js';"
        i=0
        for p in $(jq -r '.dependencies | keys[]' $src); do
          e=$(jq -r '.pi.extensions[0] // ""' node_modules/$p/package.json)
          [ -n "$e" ] || continue # plain libraries (peer deps declared here) have no extension entry
          [ -d node_modules/$p/$e ] && e=$e/index.js
          echo "import e$i from './node_modules/$p/''${e#./}';"
          i=$((i + 1))
        done
        echo "process.title = APP_NAME;"
        echo "process.env.PI_CODING_AGENT = 'true';"
        echo "process.emitWarning = () => {};"
        echo "registerBunOAuthFlows();"
        echo "restoreSandboxEnv();"
        echo "await import('$d/bun/register-bedrock.js');"
        echo "configureHttpDispatcher();"
        echo "main(process.argv.slice(2), { extensionFactories: [$(seq -s, -f 'e%g' 0 $((i - 1)))] });"
      } > entry.ts

      bun build --compile --bytecode --format=esm --minify entry.ts --outfile pi
    '';

    # Binary layout expected by pi's isBunBinary paths (see its copy-binary-assets script)
    installPhase = ''
      l=$out/lib/pi
      mkdir -p $l/node_modules/@mariozechner
      cp pi ${pi}/package.json ${pi}/README.md ${pi}/CHANGELOG.md $l/
      cp -r ${pi}/docs ${pi}/examples $l/
      cp -r ${pi}/dist/modes/interactive/theme ${pi}/dist/modes/interactive/assets ${pi}/dist/core/export-html $l/
      cp ${pi}/node_modules/@silvia-odwyer/photon-node/photon_rs_bg.wasm $l/
      cp -r ${pi}/node_modules/@mariozechner/clipboard* $l/node_modules/@mariozechner/
      makeWrapper $l/pi $out/bin/pi \
        --prefix PATH : ${lib.makeBinPath [fd ripgrep rtk]} \
        --set-default PI_SKIP_VERSION_CHECK 1 \
        --set-default PI_TELEMETRY 0
    '';

    # Stripping or patching would corrupt the payload bun appends to the executable
    dontStrip = true;
    dontPatchELF = true;

    meta.mainProgram = "pi";
  }
