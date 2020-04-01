# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include nelnet::nbs::install
class nelnet::nbs::install (
  String $ps_config_home = lookup('ps_config_home'),
  String $ps_home = lookup('ps_home_location'),
  String $domain = lookup('pia_domain_name'),
  String $temp = 'c:/1d196bf1-acec-4851-86ca-8adcea3d519c',
  Optional[Variant[Enum['present', 'absent'], String[1]]] $ensure = $nelnet::nbs::ensure,
  Optional[String[1]] $package = $nelnet::nbs::package
) {

  notify { 'Executing ::nelnet::nbs::install' : }

  if ($ensure in [ 'present' ]) {

    file { $temp :
      ensure => directory,
    }

    exec { "Expand ${package}" :
      command  => Sensitive("
        \${ProgressPreference}='SilentlyContinue'
        Expand-Archive -Path \"${package}\" -DestinationPath \"${temp}\" -Force
        Move-Item -Path \"${temp}/NBS*/NBS*/*\" -Destination \"${temp}\" -Force
        "),
      provider => powershell,
      creates  => "${temp}/java",
      require  => [ File[$temp] ],
    }

    exec { 'Stop Web Server Service for Nelnet Installation' :
      command  => Sensitive('Get-Service PsftPIA* | Stop-Service -Force'),
      provider => powershell,
      require  => [ File[$temp] ],
    }

    exec { 'Clear Web Server Cache for Nelnet Installation' :
      command  => Sensitive("
        Get-ChildItem `
          -Path \"${ps_config_home}/webserv/${domain}/applications/peoplesoft/PORTAL.war/${domain}/cache\" `
          -Recurse `
          -ErrorAction SilentlyContinue `
          | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ;
        "),
      provider => powershell,
      onlyif   => Sensitive("
        If ( \$(Try { 
            Test-Path `
              -Path \"${ps_config_home}/webserv/${domain}/applications/peoplesoft/PORTAL.war/${domain}/cache\" `
              -ErrorAction Stop
          } Catch { 
            \${False} 
          })
        ) {
          Exit 0
        } Else {
          Exit 1
        }"),
      require  => [ Exec['Stop Web Server Service for Nelnet Installation'] ],
    }

    exec { 'Stop Application Server Service for Nelnet Installation' :
      command  => Sensitive('Get-Service PsftApp* | Stop-Service -Force'),
      provider => powershell,
      require  => [ File[$temp] ],
    }

    exec { 'Clear Application Server Cache for Nelnet Installation' :
      command  => Sensitive("
        Get-ChildItem `
          -Path \"${ps_config_home}/appserv/${domain}/CACHE\" `
          -Recurse `
          -ErrorAction SilentlyContinue `
          | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ;
        "),
      provider => powershell,
      onlyif   => Sensitive("
        If ( \$(Try { 
            Test-Path `
              -Path \"${ps_config_home}/appserv/${domain}/CACHE\" `
              -ErrorAction Stop
          } Catch { 
            \${False} 
          })
        ) {
          Exit 0
        } Else {
          Exit 1
        }"),
      require  => [ Exec['Stop Application Server Service for Nelnet Installation'] ],
    }

    exec { 'Deploy Nelnet components' :
      command  => Sensitive("Copy-Item -Path '${temp}/nelnet_business_solutions*' -Destination '${ps_config_home}/class/' -Force"),
      provider => powershell,
      require  => [ File[$temp], Exec['Stop Application Server Service for Nelnet Installation'] ],
    }

    #dsc_registry { 'Import NBS_Payment fingerprint into CURRENT_USER registry hive' :
    #  dsc_ensure    => 'Present',
    #  dsc_key       => 'HKEY_CURRENT_USER\\Software\\SimonTatham\\PuTTY\\SshHostKeys',
    #  dsc_valuename => 'rsa2@22:transfer.nbspayments.com',
    #  dsc_valuedata => '0x23,0xd165294c3b5bf070e745e9ddded08daf8aebd6552db27c5e037a931d3ddc227402e2c184509c6ff369877497a767b1121176179997dc6872af7ac5bbfab62546091b9d6a171980ec5788622a711ad035dccbd02faf81b177458ea5b9b752a59a9b5f0e4ee5cdec7d7ba0961974c9853756e5a749f83d4c3d3d6a12755e418327037f858081d97a2fb9c1cd82c7ad22e0594dad86966ae3d37eb89e66ded0bb3905dd8cd48c837a750208e9d809a7b4c2f44e833ede96a5ef93dc03be61ab67418cf8145e87eecbda572f3a4ac57119fae2be1c1e0b1caf5b5eac33891112f23f990fb3244d6757ea8748a3541f6295dfe35b818710a9cdfd3bc84c7d3cef8c97',
    #  require       => [ Exec['Deploy Nelnet components'] ],
    #}

    exec { "Import NBS_Payment fingerprint into CURRENT_USER registry hive" :
      command  => Sensitive("
        If (-not (Test-Path 'HKCU:\\SOFTWARE\\SimonTatham\\PuTTY\\SshHostKeys')) { 
          New-Item 'HKCU:\\SOFTWARE\\SimonTatham\\PuTTY\\SshHostKeys' -ItemType Directory -Force
        }
        Set-ItemProperty `
          -Path 'HKCU:\\SOFTWARE\\SimonTatham\\PuTTY\\SshHostKeys' `
          -Name 'rsa2@22:transfer.nbspayments.com' `
          -Value '0x23,0xd165294c3b5bf070e745e9ddded08daf8aebd6552db27c5e037a931d3ddc227402e2c184509c6ff369877497a767b1121176179997dc6872af7ac5bbfab62546091b9d6a171980ec5788622a711ad035dccbd02faf81b177458ea5b9b752a59a9b5f0e4ee5cdec7d7ba0961974c9853756e5a749f83d4c3d3d6a12755e418327037f858081d97a2fb9c1cd82c7ad22e0594dad86966ae3d37eb89e66ded0bb3905dd8cd48c837a750208e9d809a7b4c2f44e833ede96a5ef93dc03be61ab67418cf8145e87eecbda572f3a4ac57119fae2be1c1e0b1caf5b5eac33891112f23f990fb3244d6757ea8748a3541f6295dfe35b818710a9cdfd3bc84c7d3cef8c97'
        "),
      provider => powershell,
      require  => [ Exec['Deploy Nelnet components'] ],
    }

    exec { "Delete ${temp} Directory" :
      command  => Sensitive("
        New-Item -Path \"c:/empty\" -Type Directory -Force | Out-Null
        & C:\\windows\\system32\\cmd.exe /c 'robocopy c:\\empty ${regsubst($temp ,'/', '\\\\', 'G')} /MOVE /MIR >nul'
        & C:\\windows\\system32\\cmd.exe /c 'rmdir ${regsubst($temp ,'/', '\\\\', 'G')} /Q /S >nul'
        "),
      provider => powershell,
      require  => [ Exec['Deploy Nelnet components'] ],
    }
    
  }

}
