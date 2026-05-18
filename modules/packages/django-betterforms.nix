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
      packages.django-betterforms = python.pkgs.buildPythonPackage rec {
        pname = "django-betterforms";
        version = "3.0.0";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "fusionbox";
          repo = pname;
          rev = version;
          hash = "sha256-jBQXHh9FuhnVwXfnFwkvXwnRV4m/gzu7MUhj3EsXlWE=";
        };

        build-system = [ python.pkgs.setuptools ];

        dependencies = lib.attrValues {
          inherit (python.pkgs) django_5;
        };

        pythonImportsCheck = [ "betterforms" ];

        pythonNamespaces = [ "betterforms" ];
      };
    };
}
