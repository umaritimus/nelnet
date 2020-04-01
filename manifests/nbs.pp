# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include nelnet::nbs
class nelnet::nbs (
  Optional[String[1]] $package = undef,
  Optional[Variant[Enum['present', 'absent'], String[1]]] $ensure = 'absent',
) {

  notify { 'Executing ::nelnet::nbs' : }

  contain ::nelnet::nbs::install
}
