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
      packages.sphinxcontrib-django = python.pkgs.buildPythonPackage rec {
        pname = "sphinxcontrib-django";
        version = "2.5";
        pyproject = true;

        src = pkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-RaVMDMH2QdbBWHKCiGLwc4NIyo19W5J3e8qlMGeMLMQ=";
        };

        build-system = [ python.pkgs.setuptools ];

        dependencies = lib.attrValues {
          inherit (python.pkgs) django_5 sphinx pprintpp;
        };

        pythonImportsCheck = [ "sphinxcontrib_django" ];

        pythonNamespaces = [ "sphinxcontrib_django" ];
      };
    };
}
