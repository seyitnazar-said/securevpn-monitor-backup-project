## Обновление пакетов и включение автоматических обновлений на Ubuntu

### Обновляем индекс пакетов, чтобы иметь актуальную информацию о доступных пакетах
```bash
sudo apt update
```

### Устанавливаем пакет unattended-upgrades, который позволяет включить автоматические обновления
```bash
sudo apt install unattended-upgrades
```

### Проверяем статус службы unattended-upgrades, чтобы убедиться, что она запущена 
```bash
sudo systemctl status unattended-upgrades
```

### Открываем конфигурационный файл, в котором определяется, какие пакеты и источники могут обновляться автоматически
```bash
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

#### В этом файле указываем, какие источники пакетов разрешены для автоматического обновления

```bash
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";          # Main Ubuntu repository
    "${distro_id}:${distro_codename}-security"; # Security updates repository
};
```

#### При необходимости можно указать пакеты, которые НЕ должны обновляться автоматически

```bash
Unattended-Upgrade::Package-Blacklist {
    apache2  # Prevent Apache from being automatically upgraded
};
```

### Открываем конфигурационный файл, который задает частоту автоматических обновлений
```bash
sudo vim /etc/apt/apt.conf.d/20auto-upgrades
```

#### Настраиваем периодические обновления:
```bash
APT::Periodic::Update-Package-Lists "1";      # Update package lists daily
APT::Periodic::Unattended-Upgrade "1";       # Apply unattended upgrades daily
APT::Periodic::AutocleanInterval "7";        # Clean up obsolete packages every 7 days
```

### Перезапускаем службу unattended-upgrades, чтобы применить изменения
```bash
sudo systemctl restart unattended-upgrades.service
```

### Тестируем конфигурацию unattended-upgrades без фактической установки обновлений
```bash
sudo unattended-upgrades --dry-run –debug
```

## Источник
**https://phoenixnap.com/kb/automatic-security-updates-ubuntu**