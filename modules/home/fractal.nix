{ pkgs, ... }:
let
  pythonPackages = pkgs.python3Packages;

  # https://github.com/plasma-ai/wiki
  # Changelog: https://github.com/plasma-ai/wiki/blob/main/CHANGELOG.md
  plasmaWiki = pythonPackages.buildPythonApplication rec {
    pname = "plasma-wiki";
    version = "1.2.0"; # актуальная на PyPI 2026-08-07
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "plasma_wiki";
      inherit version;
      hash = "sha256-2C/dttwRpfVYv86ZZf0BO4nQVILzwW+SxxR8Y0N1cws=";
    };

    build-system = [ pythonPackages.poetry-core ];
    dependencies = [ pythonPackages.typer ];
    pythonImportsCheck = [ "wiki" ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    # wiki/cli/{utils,cmd/wiki}.py вызывают git по короткому имени через
    # subprocess. В замыкании его нет, поэтому инжектим в PATH обёртки.
    postFixup = ''
      wrapProgram $out/bin/wiki \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git ]}
    '';
  };

  # https://github.com/plasma-ai/fractal
  # Changelog: https://github.com/plasma-ai/fractal/blob/main/CHANGELOG.md
  plasmaFractal = pythonPackages.buildPythonApplication rec {
    pname = "plasma-fractal";
    version = "1.1.0"; # актуальная на PyPI 2026-08-07
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "plasma_fractal";
      inherit version;
      hash = "sha256-aDER8ujkzSPKvlCquWxVGTULNGPgKfxmDvmxP4taCgk=";
    };

    build-system = [ pythonPackages.poetry-core ];
    dependencies = [
      plasmaWiki
      pythonPackages.rich
      pythonPackages.textual
      pythonPackages.typer
    ];
    pythonImportsCheck = [ "fractal" ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    # tmux, git и bash вызываются по короткому имени и в замыкании отсутствуют:
    #   util/tmux.py:42        -> ['tmux', ...]
    #   core/worktree.py:570   -> ['bash', <_scripts/*.sh>, ...]
    #   _scripts/*.sh          -> git (137 вызовов), tmux (49)
    # Shebangs в _scripts не патчатся (файлы лежат вне bin/), но и не нужны:
    # скрипты запускаются через явный `bash`. PATH обёртки сохраняется, т.к.
    # util/system.py:51 prepend_bin_path только префиксует существующий PATH.
    postFixup = ''
      wrapProgram $out/bin/fractal \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.tmux
            pkgs.git
            pkgs.bashNonInteractive # pkgs.bash тянет bash-interactive (readline/ncurses)
          ]
        }
    '';
  };
in
{
  # tmux нужен fractal в рантайме, но приходит из обёртки, а не отсюда.
  # В интерактивном PATH он живёт независимо, в packages/cli.nix.
  home.packages = [
    plasmaFractal
    plasmaWiki
  ];
}
