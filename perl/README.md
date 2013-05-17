space
=====

Container::INI -  create beautifully complex (nested data structures) from an INI file
                  * multiline values
                  * not notation
                  * array detection
                  * fast, tiny, and efficient
                  * multitude of uses (dependency injection, etc.)

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

