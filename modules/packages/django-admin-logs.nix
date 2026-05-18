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
      packages.django-admin-logs = python.pkgs.buildPythonPackage rec {
        pname = "django-admin-logs";
        version = "1.5.0";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "radwon";
          repo = pname;
          rev = "v${version}";
          hash = "sha256-3bUsLSBoCYgbQlCV9e02r1qkvas4JejI4rpspxLqSVw=";
        };

        build-system = [ python.pkgs.setuptools ];

        dependencies = lib.attrValues {
          inherit (python.pkgs) django_5;
        };

        pythonImportsCheck = [ "django_admin_logs" ];

        pythonNamespaces = [ "django_admin_logs" ];
      };
    };
}
