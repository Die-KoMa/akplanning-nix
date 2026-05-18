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
      packages.django-docs = python.pkgs.buildPythonPackage rec {
        pname = "django-docs";
        version = "0.3.3";
        pyproject = true;

        src = pkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-8rSJqxIvbchKGo8OK+htzIs5WLMbLQpGA1cMRyKECNA=";
        };

        build-system = [ python.pkgs.setuptools ];

        dependencies = lib.attrValues {
          inherit (python.pkgs)
            django_5
            ;
        };

        pythonImportsCheck = [ "docs" ];

        pythonNamespaces = [ "docs" ];
      };
    };
}
