# Microsoft Store (MSIX) packaging

The Store build is the same `hermespill.exe`. Two features only work there, because
Windows gives them to packaged apps only, and both need entries in the
package's `AppxManifest.xml`.

## Launch on startup

Packaged apps start with Windows through a startup task, not the registry Run
key the portable build uses. HermesPill looks the task up by id, so the `TaskId`
must be exactly `HermesPillStartup` (`autostart::STORE_TASK_ID`).

```xml
<Package
  xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  xmlns:uap3="http://schemas.microsoft.com/appx/manifest/uap/windows10/3"
  xmlns:desktop="http://schemas.microsoft.com/appx/manifest/desktop/windows10"
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
  IgnorableNamespaces="uap uap3 desktop rescap">
  ...
  <Applications>
    <Application Id="HermesPill" Executable="hermespill.exe" EntryPoint="Windows.FullTrustApplication">
      ...
      <Extensions>
        <desktop:Extension Category="windows.startupTask">
          <desktop:StartupTask TaskId="HermesPillStartup" Enabled="false" DisplayName="HermesPill" />
        </desktop:Extension>
      </Extensions>
    </Application>
  </Applications>
```

- `Enabled="false"`: the Store build starts with this off. Turning it on in
  HermesPill's Settings asks Windows (`StartupTask.RequestEnableAsync`).
- If the user turns HermesPill off in **Settings › Apps › Startup**, Windows reports
  `DisabledByUser`; HermesPill shows that and never re-enables itself.
- A startup-task launch passes no arguments. That is fine: an ordinary launch
  already starts quietly in the tray.

## Notifications from every app (optional)

Only needed if this release should show other apps' Windows notifications in
the notch. Without it, the Store build behaves like the portable one (webhook
alerts only), and nothing else depends on it.

```xml
  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
    <uap3:Capability Name="userNotificationListener" />
  </Capabilities>
```

The user still has to allow it: Settings › Notch › Notifications › Connect
Windows notifications shows Windows' own permission prompt.
