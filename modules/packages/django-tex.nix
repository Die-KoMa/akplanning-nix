{
  lib,
  ...
}:

{
  perSystem =
    {
      pkgs,
      ...
    }:

    let
      python = pkgs.python3;
    in
    {
      packages.django-tex = python.pkgs.buildPythonPackage rec {
        pname = "django-tex";
        version = "1.1.12";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "ramibch";
          repo = pname;
          rev = "v${version}";
          hash = "sha256-wY17AlFFzeYXXOjH4aeI20VXO5p/oBxjmynF6R4QGS0=";
        };

        build-system = [ python.pkgs.setuptools ];
        nativeBuildInputs = [ python.pkgs.setuptools-scm ];

        dependencies = lib.attrValues {
          inherit (python.pkgs)
            django_5
            jinja2
            ;
        };

        pythonImportsCheck = [ "django_tex" ];

        pythonNamespaces = [ "django_tex" ];
      };
    };
}
