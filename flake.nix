# See: https://flyx.org/nix-flakes-latex/
{
  description = "Complexity Theory Cheat Sheet";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:

      let
        mainFile = "cheat-sheet";
        date = "2022-03-04";

        pkgs = nixpkgs.legacyPackages.${system};
        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-minimal latex-bin latexmk babel babel-german koma-script enumitem geometry csquotes fontspec fontawesome metafont amsmath xcolor pgf epstopdf-pkg;
        };
        build = pkgs.writeScriptBin "build" ''
          mkdir -p .cache/texmf-var
          env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
              SOURCE_DATE_EPOCH=$(date -d ${date} +%s) \
              latexmk -interaction=nonstopmode -pdf -lualatex \
              -pretex="\pdfvariable suppressoptionalinfo 512\relax" \
              -usepretex ${mainFile}.tex
        '';

      in rec {
        packages = {

          document = pkgs.stdenvNoCC.mkDerivation rec {
            name = "${mainFile}.pdf";
            src = self;
            buildInputs = [ pkgs.coreutils tex build ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              ${build}/bin/build
            '';
            installPhase = ''
              mkdir -p $out
              cp ${mainFile}.pdf $out/
            '';
          };

        };

        defaultPackage = packages.document;

        shell = pkgs.stdenvNoCC.mkShell {
          packages = [ pkgs.coreutils tex build ];
        };
      });
}
