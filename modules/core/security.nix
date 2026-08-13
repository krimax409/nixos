{
  security.rtkit.enable = true;
  security.sudo.enable = true;

  # SUID-хелпер песочницы Chromium в /run/wrappers/bin/__chromium-suid-sandbox.
  #
  # Нужен Electron-приложениям вне Nix store — у Hermes Desktop свой
  # chrome-sandbox лежит в ~/.hermes и после каждой пересборки теряет
  # root:root 4755, вернуть их из меню приложений нечем (sudo без TTY).
  # Обернуть тот файл через security.wrappers нельзя: он лежит в home и
  # доступен пользователю на запись, то есть setuid-бит на нём — это прямой
  # путь к root для любого процесса от k. Хелпер из store неизменяем, поэтому
  # безопасен; Electron берёт его через CHROME_DEVEL_SANDBOX
  # (см. modules/home/hermes-support.nix).
  security.chromiumSuidSandbox.enable = true;
}
