space
=====

Container::INI - a small pure perl lib with zero deps that takes an INI file name as an argument and creates some serious data structures/objects.
                 I'm sure a number of these exist, but this version supports dot notation for keys which will nest your structure
		 quite nicely.  Values are type checked for comma separated values to determine if value is a LIST context or SCALAR.

# config
[header::example::1]
address.street=1 Individual Way
address.city=Your Town
address.state=Your State
address.zip=Your Zip
name.first=Rajendra
name.last=Prashad
os.unix.linux=Debian, Centos, Gentoo, Mint
os.unix.bsd=FreeBSD, NetBSD, OpenBSD

# code
use Container::INI;
use Data::Dumper;

my $ini = new Container::INI("example1.ini");
print Dumper $ini->get_config;

# output
$VAR1 = {
          'header' => {
                        'example' => {
                                       '1' => {
                                                'name' => {
                                                            'first' => 'Rajendra',
                                                            'last' => 'Prashad'
                                                          },
                                                'address' => {
                                                               'zip' => 'Your Zip',
                                                               'city' => 'Your Town',
                                                               'street' => '1 Individual Way',
                                                               'state' => 'Your State'
                                                             },
                                                'os' => {
                                                          'unix' => {
                                                                      'bsd' => [
                                                                                 'FreeBSD',
                                                                                 'NetBSD',
                                                                                 'OpenBSD'
                                                                               ],
                                                                      'linux' => [
                                                                                   'Debian',
                                                                                   'Centos',
                                                                                   'Gentoo',
                                                                                   'Mint'
                                                                                 ]
                                                                    }
                                                        }
                                              }
                                     }
                      }
        };

