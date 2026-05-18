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
      packages.django-fontawesome-6 = python.pkgs.buildPythonPackage rec {
        pname = "django-fontawesome-6";
        version = "1.0.0.0";
        pyproject = true;

        src = pkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-7N9CoRRbINgWjL0sfjctEGNKjM4GcOpPVxyAGG05Nuc=";
        };

        build-system = [ python.pkgs.setuptools ];

        dependencies = lib.attrValues {
          inherit (python.pkgs)
            django_5
            ;
        };
      };
    };
}
