# Inspec test for netbios

## Example tests for Checking netbios enabled on network interfaces.

### This code will run a powershell query, filter on the netbios setting for anything set to 1 (enabled) and if anything is returned it will fail with a list of names.

```
control "Arbitrary rule name for your compliance sets" do
  title "Look for netbios enabled Network Adapters"
  desc  "
  CHeck for adapters with netbios enabled in their settings.
  "
  impact 1.0
  script = <<-EOH
$interfaces =  Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Property *
foreach ($interface in $interfaces) {
If ($interface.TcpipNetbiosOptions -eq 1)
{echo $interface.ServiceName}
}
EOH
  describe powershell(script)do
its('stdout') { should cmp '' }
  end
end
```

### This version I am still working on but I believe will give cleaner output. Need to figure how to get it to loop through the list.
```
control "Arbitrary rule name for your compliance sets" do
  title "Look for netbios enabled Network Adapters"
  desc  "
  CHeck for adapters with netbios enabled in their settings.
  "
  impact 1.0
  describe wmi(
    class: 'niconfig',
    query: 'wmic nicconfig get Description,index,TcpipNetbiosOptions'
    ) do
    its('TcpipNetbiosOptions') { should_not eq '1' }
  end
end
```
