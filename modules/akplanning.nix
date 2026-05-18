{
  lib,
  ...
}:

{
  perSystem =
    {
      self',
      pkgs,
      ...
    }:

    let
      src = pkgs.fetchgit {
        url = "https://gitlab.fachschaften.org/kif/akplanning.git";
        rev = "faf3e534998f67e315cfa0f9c5d21b87c032a632";
        hash = "sha256-rmnxA2xj6xXUebzottnzkaAF091KaT2b1Pwi2frGZQ4=";
      };

      python = pkgs.python3Packages.python.override {
        packageOverrides = self: super: {
          django = super.django_5;

          django-docs = null;
          django-fontawesome6 = null;
          django-registration-redux = null;
          django-tex = null;

          inherit (self'.packages)
            django-admin-logs
            django-betterforms
            django-bootstrap-datepicker-plus

            sphinxcontrib-django
            ;
        };
      };

      texlive = pkgs.texliveBasic.withPackages (
        ps:
        lib.attrValues {
          inherit (ps)
            beamer
            luatex
            ;
        }
      );

      path = lib.makeBinPath [
        texlive
      ];

      dependencies = lib.attrValues {
        inherit (python.pkgs)
          django
          django-admin-logs
          django-betterforms
          django-bootstrap-datepicker-plus
          django-bootstrap5
          django-compressor
          django-debug-toolbar
          django-fontawesome6
          django-libsass
          django-registration-redux
          django-simple-history
          django-split-settings
          django-tex
          django-timezone-field
          django-csp
          djangorestframework

          fontawesomefree
          mysqlclient
          tzdata
          jsonschema

          sphinx
          sphinx-rtd-theme
          sphinxcontrib-apidoc
          sphinxcontrib-django
          recommonmark
          django-docs
          ;
      };
    in
    {
      packages.akplanning = python.pkgs.buildPythonApplication {
        name = "akplanning";
        version = "0-unstable-2026-05-18";
        pyproject = false;
        inherit src;

        nativeBuildInputs = [
        ];

        inherit dependencies;

        buildPhase = ''
          runHook preBuild

          mkdir -p $out/lib
          cp -r $src $out/lib/akplanning
          runHook postBuild
        '';

        installPhase =
          let
            pythonPath = python.pkgs.makePythonPath dependencies;
          in
          ''
            runHook preInstall

            chmod +x $out/lib/akplanning/manage.py
            makeWrapper $out/lib/akplanning/manage.py $out/bin/akplanning \
              --prefix PYTHONPATH : "${pythonPath}" \
              --prefix PATH : "${path}"

            runHook postInstall
          '';

        nativeCheckInputs = lib.attrValues {
          inherit (python.pkgs)
            unittest-xml-reporting
            beautifulsoup4
            ;
        };

        meta = {
          license = lib.licenses.agpl3Only;
        };
      };

    };
}
