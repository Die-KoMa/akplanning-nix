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

          inherit (self'.packages)
            django-admin-logs
            django-betterforms
            django-bootstrap-datepicker-plus
            django-docs
            django-fontawesome-6
            django-tex
            django-registration-redux
            sphinxcontrib-django
            ;
        };
      };

      texlive = pkgs.texlive.combine {
        inherit (pkgs.texlive.pkgs)
          collection-basic
          collection-luatex
          collection-latex
          collection-latexrecommended
          collection-latexextra
          collection-fontsrecommended
          collection-fontsextra
          collection-langgerman
          beamer
          ;
      };

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
          django-fontawesome-6
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

      pythonPath = python.pkgs.makePythonPath dependencies;
    in
    {
      devShells.akplanning = pkgs.mkShell {
        inputsFrom = self'.packages.aktool;
      };

      packages.akplanning = python.pkgs.buildPythonApplication {
        name = "akplanning";
        version = "0-unstable-2026-05-18";
        pyproject = false;
        inherit src;

        patches = [
          ./patches/0001-Require-name-and-institution-in-preference-polls.patch
          ./patches/0002-Reword-required-into-required-AK-owner.patch
        ];

        nativeBuildInputs = [
          pkgs.gettext
        ];

        inherit dependencies;

        buildPhase = ''
          runHook preBuild

          mkdir -p $out/lib
          cp -r $src $out/lib/akplanning
          chmod -R +w $out/lib/akplanning
          rm -rf $out/lib/akplanning/docs

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          chmod +x $out/lib/akplanning/manage.py
          makeWrapper $out/lib/akplanning/manage.py $out/bin/akplanning \
            --prefix PYTHONPATH : "${pythonPath}" \
            --prefix PATH : "${path}"

          runHook postInstall
        '';

        postInstall = ''
          python $out/lib/akplanning/manage.py collectstatic
          python $out/lib/akplanning/manage.py compilemessages
        '';

        nativeCheckInputs = lib.attrValues {
          inherit (python.pkgs)
            unittest-xml-reporting
            beautifulsoup4
            ;
        };

        passthru = {
          inherit python pythonPath;
        };

        meta = {
          license = lib.licenses.agpl3Only;
          mainProgram = "akplanning";
        };
      };

    };
}
