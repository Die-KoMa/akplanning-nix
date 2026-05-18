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
      python = pkgs.python3.override {
        packageOverrides = self: super: {
          django = super.django_5;
        };
      };
    in
    {
      packages.django-bootstrap-datepicker-plus = python.pkgs.buildPythonPackage rec {
        pname = "django-bootstrap-datepicker-plus";
        version = "6.0.0";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "monim67";
          repo = pname;
          rev = version;
          hash = "sha256-G+IIpSH7x++IGvNWd0NOkHsmFPlheu0LTg+lTNyhlrA=";
        };

        build-system = [ python.pkgs.poetry-core ];

        dependencies = lib.attrValues {
          inherit (python.pkgs)
            django
            django-bootstrap5
            pydantic
            pydantic-settings
            ;
        };

        pythonImportsCheck = [ "bootstrap_datepicker_plus.widgets" ];

        pythonNamespaces = [ "bootstrap_datepicker_plus" ];
      };
    };
}
