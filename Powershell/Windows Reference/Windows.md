## Disable windows hello (pin)
``` powershell
REG ADD HKLM\SOFTWARE\Policies\Microsoft\PassportForWork /v Enabled /t REG_DWORD /d 0 /f
```
