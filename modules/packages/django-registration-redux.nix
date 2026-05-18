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
      packages.django-registration-redux = python.pkgs.buildPythonPackage rec {
        pname = "django-registration-redux";
        version = "2.13";
        pyproject = true;

        src = pkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-l5OgWzKx1zQsbvPgFAspUbfb3gWLO6boojK1NJKCefk=";
        };

        build-system = [ python.pkgs.setuptools ];

        dependencies = lib.attrValues {
          inherit (python.pkgs)
            django_5
            ;
        };

        pythonImportsCheck = [ "registration" ];

        pythonNamespaces = [ "registration" ];
      };
    };
}
